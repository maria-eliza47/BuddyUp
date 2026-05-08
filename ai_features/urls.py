from django.urls import path
from .views import test_icebreaker, test_matchmaker # <-- am adăugat test_matchmaker aici

urlpatterns = [
    path('test-ai/', test_icebreaker, name='test_ai'),
    path('test-match/', test_matchmaker, name='test_match'), # <-- ruta nouă
]