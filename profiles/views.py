from django.shortcuts import render

# Create your views here.
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import parser_classes
from .models import Profile


@api_view(['GET'])
def profile_detail_view(request, user_id):

    try:

        profile = Profile.objects.get(
            user__id=user_id
        )

    except Profile.DoesNotExist:

        return Response(
            {
                'error': 'Profile not found'
            },
            status=status.HTTP_404_NOT_FOUND
        )

    data = {

        'username': profile.user.username,
        'email': profile.user.email,
        'age': profile.age,
        'bio': profile.bio,
        'interests': profile.interests,
        'latitude': profile.latitude,
        'longitude': profile.longitude,
        'profile_picture': (
            request.build_absolute_uri(
                profile.profile_picture.url
            )
            if profile.profile_picture
            else None
        ),
    }

    return Response(data)


@api_view(['PUT'])
def profile_update_view(request, user_id):

    try:

        profile = Profile.objects.get(
            user__id=user_id
        )

    except Profile.DoesNotExist:

        return Response(
            {
                'error': 'Profile not found'
            },
            status=status.HTTP_404_NOT_FOUND
        )

    profile.age = request.data.get(
        'age',
        profile.age
    )

    profile.bio = request.data.get(
        'bio',
        profile.bio
    )

    profile.interests = request.data.get(
        'interests',
        profile.interests
    )

    profile.latitude = request.data.get(
        'latitude',
        profile.latitude
    )

    profile.longitude = request.data.get(
        'longitude',
        profile.longitude
    )

    profile.save()

    return Response(
        {
            'message': 'Profile updated successfully'
        }
    )

@api_view(['PUT'])
@parser_classes([MultiPartParser, FormParser])
def upload_profile_picture_view(request, user_id):

    try:

        profile = Profile.objects.get(
            user__id=user_id
        )

    except Profile.DoesNotExist:

        return Response(
            {
                'error': 'Profile not found'
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if 'profile_picture' not in request.FILES:

        return Response(
            {
                'error': 'No image provided'
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    profile.profile_picture = request.FILES[
        'profile_picture'
    ]

    profile.save()

    return Response(
        {
            'message': 'Profile picture uploaded successfully'
        }
    )