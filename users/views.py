from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from profiles.models import Profile

@csrf_exempt
@api_view(['POST'])
def register_view(request):
    username = request.data.get('username')
    email = request.data.get('email')
    password = request.data.get('password')

    # Verificăm dacă toate câmpurile sunt trimise
    if not username or not email or not password:
        return Response(
            {'error': 'Please provide username, email and password'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Verificăm dacă username-ul există deja
    if User.objects.filter(username=username).exists():
        return Response(
            {'error': 'Username already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Creăm utilizatorul
    try:
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password
        )

        # Creăm automat și profilul gol pentru acest utilizator
        Profile.objects.create(user=user)

        return Response(
            {'message': 'User created successfully'},
            status=status.HTTP_201_CREATED
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@csrf_exempt
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
            },
            status=status.HTTP_200_OK
        )

    return Response(
        {'error': 'Invalid credentials'},
        status=status.HTTP_401_UNAUTHORIZED
    )