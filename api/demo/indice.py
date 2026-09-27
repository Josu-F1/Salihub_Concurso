"""Cálculo del índice de disposición de la demo.

⚠️ Es una fórmula de juguete: el promedio simple de las respuestas. No es la fórmula de SaliHub.
Si su idea necesita otra forma de calcularlo, cámbiela.
"""

from .catalogo import NIVELES, PREGUNTAS, PREGUNTAS_POR_CLAVE


class RespuestasInvalidas(ValueError):
    pass


def validar(respuestas):
    """Revisa que vengan todas las preguntas y que cada respuesta sea una opción válida (su índice)."""
    if not isinstance(respuestas, dict):
        raise RespuestasInvalidas("Las respuestas tienen que ser un objeto {clave: opción}.")
    faltan = [p["clave"] for p in PREGUNTAS if p["clave"] not in respuestas]
    if faltan:
        raise RespuestasInvalidas(f"Faltan respuestas: {', '.join(faltan)}.")
    for clave, valor in respuestas.items():
        pregunta = PREGUNTAS_POR_CLAVE.get(clave)
        if pregunta is None:
            raise RespuestasInvalidas(f"No existe la pregunta «{clave}».")
        if not isinstance(valor, int) or isinstance(valor, bool) or not 0 <= valor < len(pregunta["opciones"]):
            raise RespuestasInvalidas(f"La respuesta de «{clave}» tiene que ser un número de 0 a {len(pregunta['opciones']) - 1}.")


def calcular(respuestas):
    """Devuelve el índice de 0 a 100."""
    validar(respuestas)
    puntajes = [PREGUNTAS_POR_CLAVE[clave]["puntajes"][valor] for clave, valor in respuestas.items()]
    return round(sum(puntajes) / len(puntajes) * 100)


def nivel_de(indice):
    for nivel in NIVELES:
        if indice >= nivel["desde"]:
            return nivel
    return NIVELES[-1]


def nivel_por_clave(clave):
    return next(n for n in NIVELES if n["clave"] == clave)


def elegir_carta(fecha, nivel_clave, disciplina="bienestar", es_dorada=False):
    """Elige determinísticamente una carta según fecha, nivel y disciplina deportiva."""
    from .catalogo import CARTAS
    candidatas = [c for c in CARTAS if c["nivel"] == nivel_clave and c["disciplina"] == disciplina]
    if not candidatas:
        candidatas = [c for c in CARTAS if c["nivel"] == nivel_clave and c["disciplina"] == "bienestar"]
    if not candidatas:
        candidatas = [c for c in CARTAS if c["nivel"] == nivel_clave]
    if not candidatas:
        candidatas = CARTAS[:1]

    idx = fecha.toordinal() % len(candidatas)
    carta = dict(candidatas[idx])
    carta["es_dorada"] = es_dorada
    carta["fecha"] = fecha.isoformat() if hasattr(fecha, "isoformat") else str(fecha)
    return carta


def es_carta_dorada(checkin_actual, historial_previo):
    """Devuelve True si el índice actual es el máximo de los últimos 30 días (Carta Dorada)."""
    if not historial_previo:
        return True
    indices = [c.indice for c in historial_previo if c.id != getattr(checkin_actual, "id", None)]
    if not indices:
        return True
    return checkin_actual.indice >= max(indices)

