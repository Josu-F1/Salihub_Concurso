"""Rutas del API de demo.

No hay usuarios ni inicio de sesión: toda la demo es de una sola persona de ejemplo.
Para simular otro día, agregue `?fecha=AAAA-MM-DD` a cualquier ruta.
"""

import datetime

from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import serializers, status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from . import indice as calculo
from .catalogo import AVISO, DISCIPLINAS, PREGUNTAS, PREGUNTAS_POR_DISCIPLINA
from .models import CheckIn, Registro, Sesion

PERSONA = {"nombre": "Persona demo", "enfoque": "Bienestar general", "disciplina": "bienestar"}


@api_view(["GET"])
def api_root(request):
    return Response({
        "status": "ok",
        "mensaje": "API de SaliHub Demo funcionando correctamente",
        "endpoints": [
            "/api/perfil/",
            "/api/disciplinas/",
            "/api/checkin/preguntas/",
            "/api/checkin/",
            "/api/indice/hoy/",
            "/api/indice/historial/",
            "/api/cartas/",
            "/api/entrenamiento/sesion-del-dia/",
            "/api/entrenamiento/sesiones/",
            "/api/entrenamiento/registros/"
        ]
    })


def hoy(request):
    texto = request.query_params.get("fecha")
    if texto:
        try:
            return datetime.date.fromisoformat(texto)
        except ValueError:
            pass
    return timezone.localdate()


def nivel_publico(clave):
    nivel = calculo.nivel_por_clave(clave)
    return {k: nivel[k] for k in ("clave", "nombre", "color", "recomendacion", "rpe_maximo")}


def carta_de(checkin):
    historial_30 = list(CheckIn.objects.filter(fecha__lt=checkin.fecha, fecha__gte=checkin.fecha - datetime.timedelta(days=30)))
    es_dorada = calculo.es_carta_dorada(checkin, historial_30)
    disciplina = PERSONA.get("disciplina", "bienestar")
    return calculo.elegir_carta(checkin.fecha, checkin.nivel, disciplina=disciplina, es_dorada=es_dorada)


def checkin_publico(checkin):
    return {
        "fecha": checkin.fecha,
        "indice": checkin.indice,
        "nivel": nivel_publico(checkin.nivel),
        "respuestas": checkin.respuestas,
        "carta": carta_de(checkin),
    }


class PasoSerializer(serializers.Serializer):
    orden = serializers.IntegerField()
    contenido = serializers.CharField()
    duracion_segundos = serializers.IntegerField()


class SesionSerializer(serializers.ModelSerializer):
    pasos = PasoSerializer(many=True, read_only=True)

    class Meta:
        model = Sesion
        exclude = ["id"]


class SesionResumenSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sesion
        fields = ["codigo", "titulo", "categoria", "duracion_min", "duracion_max", "intensidad", "rpe_min", "rpe_maximo"]


class RegistroSerializer(serializers.ModelSerializer):
    sesion = serializers.SlugRelatedField(slug_field="codigo", queryset=Sesion.objects.all())
    titulo = serializers.CharField(source="sesion.titulo", read_only=True)

    class Meta:
        model = Registro
        fields = ["id", "sesion", "titulo", "fecha", "valoracion", "esfuerzo", "comentario"]
        read_only_fields = ["id", "fecha"]


@api_view(["GET", "POST", "PUT"])
def perfil(request):
    if request.method in ("POST", "PUT"):
        disciplina = request.data.get("disciplina")
        if disciplina in [d["clave"] for d in DISCIPLINAS]:
            PERSONA["disciplina"] = disciplina
            disp = next(d for d in DISCIPLINAS if d["clave"] == disciplina)
            PERSONA["enfoque"] = disp["nombre"]
        if "nombre" in request.data:
            PERSONA["nombre"] = request.data["nombre"]
    return Response(PERSONA)


@api_view(["GET"])
def disciplinas(request):
    return Response(DISCIPLINAS)


@api_view(["GET"])
def preguntas(request):
    disc = request.query_params.get("disciplina", PERSONA.get("disciplina", "bienestar"))
    lista_preguntas = PREGUNTAS_POR_DISCIPLINA.get(disc, PREGUNTAS)
    return Response([{k: p[k] for k in ("clave", "texto", "opciones")} for p in lista_preguntas])


@api_view(["GET"])
def cartas(request):
    fecha_limite = hoy(request)
    checkins = CheckIn.objects.filter(fecha__lte=fecha_limite).order_by("-fecha")
    resultado = []
    for c in checkins:
        resultado.append(carta_de(c))
    return Response(resultado)


@api_view(["POST", "DELETE"])
def checkin(request):
    fecha = hoy(request)
    if request.method == "DELETE":
        CheckIn.objects.filter(fecha=fecha).delete()
        return Response({"status": "ok", "mensaje": f"Check-in del {fecha} eliminado."})

    if CheckIn.objects.filter(fecha=fecha).exists():
        return Response(
            {"detalle": "Ya hizo su check-in de hoy. Podrá hacer uno nuevo mañana."},
            status=status.HTTP_409_CONFLICT,
        )
    respuestas = request.data.get("respuestas")
    try:
        valor = calculo.calcular(respuestas)
    except calculo.RespuestasInvalidas as error:
        return Response({"detalle": str(error)}, status=status.HTTP_400_BAD_REQUEST)
    nuevo = CheckIn.objects.create(
        fecha=fecha, respuestas=respuestas, indice=valor, nivel=calculo.nivel_de(valor)["clave"]
    )
    return Response(checkin_publico(nuevo), status=status.HTTP_201_CREATED)


@api_view(["GET"])
def indice_hoy(request):
    fecha = hoy(request)
    del_dia = CheckIn.objects.filter(fecha=fecha).first()
    if del_dia is None:
        return Response({"fecha": fecha, "hecho": False, "aviso": AVISO})
    return Response({"hecho": True, "aviso": AVISO, **checkin_publico(del_dia)})


@api_view(["GET"])
def indice_historial(request):
    try:
        dias = max(1, min(int(request.query_params.get("dias", 14)), 90))
    except ValueError:
        dias = 14
    fecha_actual = hoy(request)
    desde = fecha_actual - datetime.timedelta(days=dias - 1)
    filas = CheckIn.objects.filter(fecha__gte=desde, fecha__lte=fecha_actual).order_by("fecha")
    return Response([{"fecha": str(c.fecha), "indice": c.indice, "nivel": c.nivel} for c in filas])


@api_view(["GET"])
def sesion_del_dia(request):
    fecha = hoy(request)
    del_dia = CheckIn.objects.filter(fecha=fecha).first()
    if del_dia is None:
        sugerida = Sesion.objects.order_by("rpe_maximo", "codigo").first()
        if sugerida:
            return Response(
                {
                    "sesion": SesionSerializer(sugerida).data,
                    "nivel": None,
                    "mensaje": "Sesión sugerida del día. Haga su check-in para personalizarla a su estado actual.",
                    "terminada_hoy": Registro.objects.filter(fecha=fecha, sesion=sugerida).exists(),
                }
            )
        return Response({"sesion": None, "motivo": "Haga su check-in para que le recomendemos una sesión."})

    nivel = calculo.nivel_por_clave(del_dia.nivel)
    permitidas = list(Sesion.objects.filter(rpe_maximo__lte=nivel["rpe_maximo"]).order_by("-rpe_maximo", "codigo"))
    if not permitidas:
        permitidas = list(Sesion.objects.order_by("rpe_maximo", "codigo")[:1])
    if not permitidas:
        return Response({"sesion": None, "motivo": "No hay sesiones cargadas. Corra `python manage.py sembrar`."})

    # Entre las dos sesiones más exigentes que el día permite, alterna según la fecha.
    candidatas = permitidas[:2]
    elegida = candidatas[fecha.toordinal() % len(candidatas)]
    return Response(
        {
            "sesion": SesionSerializer(elegida).data,
            "nivel": nivel_publico(del_dia.nivel),
            "mensaje": f"Ajustamos su sesión: {nivel['recomendacion']}",
            "terminada_hoy": Registro.objects.filter(fecha=fecha, sesion=elegida).exists(),
        }
    )


@api_view(["GET"])
def sesiones(request):
    return Response(SesionResumenSerializer(Sesion.objects.all(), many=True).data)


@api_view(["GET"])
def sesion_detalle(request, codigo):
    return Response(SesionSerializer(get_object_or_404(Sesion, codigo=codigo)).data)


@api_view(["GET", "POST"])
def registros(request):
    if request.method == "GET":
        return Response(RegistroSerializer(Registro.objects.select_related("sesion")[:50], many=True).data)
    datos = RegistroSerializer(data=request.data)
    datos.is_valid(raise_exception=True)
    datos.save(fecha=hoy(request))
    return Response(datos.data, status=status.HTTP_201_CREATED)
