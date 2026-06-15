from django.utils import timezone
from datetime import timedelta
from django.http import JsonResponse
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404
from .models import Swipe
from matches.models import Match
from geopy.distance import geodesic
import json
import unicodedata
from django.views.decorators.csrf import csrf_exempt
from profiles.models import Profile
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db.models import Q


# ==========================================
# UTILITARE
# ==========================================

def normalizeaza_text(text):

    if not text:
        return ""

    text = text.lower()

    text = ''.join(

        c for c in unicodedata.normalize('NFD', text)

        if unicodedata.category(c) != 'Mn'
    )

    return text.strip()


# ==========================================
# 1. LOGICA SWIPE + MATCH
# ==========================================

@csrf_exempt
@api_view(['POST'])
def inregistreaza_swipe(
    request,
    swiped_user_id,
    tip_actiune
):

    from_user_id = request.GET.get(
        'from_user'
    )

    swiper = None

    if request.user.is_authenticated:

        swiper = request.user

    elif (
        from_user_id and
        from_user_id != 'null'
    ):

        swiper = User.objects.filter(
            id=from_user_id
        ).first()

    if not swiper:

        return JsonResponse(

            {
                'error':
                'Utilizator sursa neidentificat'
            },

            status=400
        )

    swiped_user = get_object_or_404(
        User,
        id=swiped_user_id
    )

    action = (

        'RIGHT'

        if tip_actiune.lower() == 'like'

        else 'LEFT'
    )

    Swipe.objects.filter(

        swiper=swiper,
        swiped_user=swiped_user

    ).delete()

    Swipe.objects.create(

        swiper=swiper,
        swiped_user=swiped_user,
        swipe_type=action
    )

    este_match = False

    if action == 'RIGHT':

        reciproc = Swipe.objects.filter(

            swiper=swiped_user,
            swiped_user=swiper,
            swipe_type='RIGHT'

        ).exists()

        if reciproc:

            u1, u2 = (

                (swiper, swiped_user)

                if swiper.id < swiped_user.id

                else (swiped_user, swiper)
            )

            Match.objects.get_or_create(

                user1=u1,
                user2=u2
            )

            este_match = True

    return JsonResponse({

        'status': 'success',

        'is_match': este_match,

        'matched_with':

            swiped_user.username

            if este_match

            else None
    })


# ==========================================
# 2. UTILIZATORI PENTRU SWIPE
# ==========================================

@api_view(['GET'])
def get_utilizatori_filtrati(request):

    try:

        user_id_url = request.GET.get(
            'user_id'
        )

        current_user = None

        if request.user.is_authenticated:

            current_user = request.user

        elif (
            user_id_url and
            user_id_url != 'null'
        ):

            current_user = User.objects.filter(
                id=user_id_url
            ).first()

        potentiali = User.objects.all(
        ).select_related('profile')

        if current_user:

            potentiali = potentiali.exclude(
                id=current_user.id
            )

        rezultat_final = []

        for p in potentiali:

            try:

                if not hasattr(p, 'profile'):

                    continue

                profil_p = p.profile

                foto_url = None

                if profil_p.profile_picture:

                    foto_url = request.build_absolute_uri(
                        profil_p.profile_picture.url
                    )

                rezultat_final.append({

                    'id': p.id,

                    'username': p.username,

                    'age': profil_p.age or 20,

                    'bio':
                    profil_p.bio
                    or
                    "Hey! Let's be buddies.",

                    'interests':
                    profil_p.interests or "",

                    'profile_picture':
                    foto_url,
                })

            except Exception as e:

                print(
                    f"Eroare la procesarea profilului {p.id}: {e}"
                )

                continue

        return JsonResponse(

            rezultat_final,
            safe=False
        )

    except Exception as e:

        print(
            f"EROARE CRITICA SERVER: {e}"
        )

        return JsonResponse(

            {
                'error': str(e)
            },

            status=500
        )


# ==========================================
# 3. SUGESTII INTERESE
# ==========================================

def get_sugestii_interese(request):

    sugestii = [

        "Muzica",
        "Sport",
        "Filme",
        "Gaming",
        "Gatit",
        "Tehnologie",
        "Calatorii",
        "Arta"
    ]

    return JsonResponse({

        'sugestii': sugestii
    })


# ==========================================
# 4. UPDATE LOCATIE
# ==========================================

@csrf_exempt
def actualizeaza_locatia(request):

    return JsonResponse({

        'status': 'ok'
    })