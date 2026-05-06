from django.urls import path
from . import views

urlpatterns = [
    path('api/lista/', views.lista_matchuri_utilizator, name='lista_matchuri'),
]