from django.urls import include, path
from demo.views import api_root

urlpatterns = [
    path("", api_root),
    path("api/", include("demo.urls")),
]
