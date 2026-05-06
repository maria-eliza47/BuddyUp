from django.urls import path
from . import views

urlpatterns = [
    # Această rută va afișa lista de match-uri
    path('my-list/', views.lista_matchuri_utilizator, name='lista_matchuri'),
]