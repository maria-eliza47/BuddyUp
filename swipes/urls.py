from django.urls import path
from . import views

urlpatterns = [
    # Această rută returnează lista de utilizatori filtrată (GPS, vârstă, interese)
    path('api/utilizatori/', views.get_utilizatori_filtrati, name='api_get_users'),
    path('api/update-location/', views.actualizeaza_locatia, name='update_location'),

    # Această rută înregistrează un swipe (LIKE/PASS)
    path('api/inregistreaza/<int:swiped_user_id>/<str:tip_actiune>/', views.inregistreaza_swipe, name='api_post_swipe'),
]