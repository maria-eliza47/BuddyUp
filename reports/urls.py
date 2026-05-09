from django.urls import path
from . import views

urlpatterns = [
    path('api/block/', views.block_user, name='block_user'),
    path('api/report/', views.report_user, name='report_user'),
]