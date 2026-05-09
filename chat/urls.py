from django.urls import path
from . import views

urlpatterns = [
    path('api/thread/', views.get_or_create_thread, name='get_thread'),
    path('api/send/', views.send_message, name='send_message'),
    path('api/<int:thread_id>/messages/', views.get_messages, name='get_messages'),
]