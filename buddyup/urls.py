from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    # Rutele pentru aplicațiile voastre
    path('users/', include('users.urls')),
    path('profiles/', include('profiles.urls')),
    path('swipes/', include('swipes.urls')),
    path('matches/', include('matches.urls')),

    # Rutele pentru AI (asigură-te că fișierul ai_features/urls.py există)
    path('ai/', include('ai_features.urls')),
]

# Servirea fișierelor media (poze de profil) și statice în timpul dezvoltării
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)