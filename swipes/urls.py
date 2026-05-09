from django.urls import path
from . import views

urlpatterns = [
    path('api/utilizatori/', views.get_utilizatori_filtrati, name='utilizatori_filtrati'),
    path('api/inregistreaza/<int:swiped_user_id>/<str:tip_actiune>/', views.inregistreaza_swipe, name='inregistreaza_swipe'),
    path('api/update-location/', views.actualizeaza_locatia, name='actualizeaza_locatia'),
    path('api/sugestii-interese/', views.get_sugestii_interese, name='sugestii_interese'),
]