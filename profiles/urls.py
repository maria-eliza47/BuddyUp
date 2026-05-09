from django.urls import path

from .views import (
    profile_detail_view,
    profile_update_view,
    upload_profile_picture_view,
    upload_gallery_image_view,
    gallery_images_view
)

urlpatterns = [

    path(
        '<int:user_id>/',
        profile_detail_view,
        name='profile-detail'
    ),

    path(
        'update/<int:user_id>/',
        profile_update_view,
        name='profile-update'
    ),

    path(
        'upload-picture/<int:user_id>/',
        upload_profile_picture_view,
        name='upload-profile-picture'
    ),

    path(
    'upload-gallery/<int:user_id>/',
    upload_gallery_image_view,
    name='upload-gallery-image'
    ),

    path(
    'gallery/<int:user_id>/',
    gallery_images_view,
    name='gallery-images'
    ),
]