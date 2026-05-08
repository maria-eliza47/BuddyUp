from django.urls import path
urlpatterns = []
from . import views

urlpatterns = [
<<<<<<< HEAD
    path('api/utilizatori/', views.get_utilizatori_filtrati, name='utilizatori_filtrati'),
    path('api/inregistreaza/<int:swiped_user_id>/<str:tip_actiune>/', views.inregistreaza_swipe, name='inregistreaza_swipe'),
    path('api/update-location/', views.actualizeaza_locatia, name='actualizeaza_locatia'),
    # LINIA NOUA:
    path('api/sugestii-interese/', views.get_sugestii_interese, name='sugestii_interese'),
]
=======
    # Această rută returnează lista de utilizatori filtrată (GPS, vârstă, interese)
    path('api/utilizatori/', views.get_utilizatori_filtrati, name='api_get_users'),
    path('api/update-location/', views.actualizeaza_locatia, name='update_location'),

    # Această rută înregistrează un swipe (LIKE/PASS)
    path('api/inregistreaza/<int:swiped_user_id>/<str:tip_actiune>/', views.inregistreaza_swipe, name='api_post_swipe'),
]
>>>>>>> origin/ai-agents
