from django.contrib import admin
from django.urls import path, include # Adaugă 'include' aici

urlpatterns = [
    path('admin/', admin.site.urls),
    # Adaugă linia de mai jos:
    path('users/', include('buddyup.urls')),
]