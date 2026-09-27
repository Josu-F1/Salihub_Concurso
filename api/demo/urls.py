from django.urls import path

from . import views

urlpatterns = [
    path("", views.api_root),
    path("perfil/", views.perfil),
    path("disciplinas/", views.disciplinas),
    path("checkin/preguntas/", views.preguntas),
    path("checkin/", views.checkin),
    path("indice/hoy/", views.indice_hoy),
    path("indice/historial/", views.indice_historial),
    path("cartas/", views.cartas),
    path("entrenamiento/sesion-del-dia/", views.sesion_del_dia),
    path("entrenamiento/sesiones/", views.sesiones),
    path("entrenamiento/sesiones/<slug:codigo>/", views.sesion_detalle),
    path("entrenamiento/registros/", views.registros),
]
