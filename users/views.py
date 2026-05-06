from django.contrib.auth.models import User
from django.contrib.auth import authenticate

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from profiles.models import Profile


@api_view(['POST'])
def register_view(request):

    username = request.data.get('username')
    email = request.data.get('email')
    password = request.data.get('password')

    if User.objects.filter(username=username).exists():

        return Response(
            {
                'error': 'Username already exists'
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    user = User.objects.create_user(
        username=username,
        email=email,
        password=password
    )

    Profile.objects.create(user=user)

    return Response(
        {
            'message': 'User created successfully'
        },
        status=status.HTTP_201_CREATED
    )


@api_view(['POST'])
def login_view(request):

    username = request.data.get('username')
    password = request.data.get('password')

    user = authenticate(
        username=username,
        password=password
    )

    if user is not None:

        return Response(
            {
                'message': 'Login successful',
                'username': user.username,
                'user_id': user.id
            }
        )

    return Response(
        {
            'error': 'Invalid credentials'
        },
        status=status.HTTP_401_UNAUTHORIZED
    )