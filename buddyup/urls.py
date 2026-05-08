from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static


urlpatterns = [
    path('admin/', admin.site.urls),
    # IMPORTANT: trimite către ai_features.urls, NU către buddyup.urls!
    path('ai/', include('ai_features.urls')),
    path('users/', include('users.urls')),
    path('swipes/', include('swipes.urls')),
    path('matches/', include('matches.urls')),
    path('profiles/', include('profiles.urls')),
    path('reports/', include('reports.urls')),
]

urlpatterns += static(
    settings.MEDIA_URL,
    document_root=settings.MEDIA_ROOT
)
