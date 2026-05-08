from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    # IMPORTANT: trimite către ai_features.urls, NU către buddyup.urls!
    path('ai/', include('ai_features.urls')), 
]