from django.utils import timezone
from datetime import timedelta
from django.http import JsonResponse
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404
from .models import Swipe
from matches.models import Match
from geopy.distance import geodesic
import json
from django.views.decorators.csrf import csrf_exempt
from profiles.models import Profile
import unicodedata
from rest_framework.decorators import api_view
from rest_framework.response import Response

# ==========================================
# UTILITARE
# ==========================================
def normalizeaza_text(text):
    if not text:
        return ""
    text = text.lower()
    text = ''.join(c for c in unicodedata.normalize('NFD', text)
                   if unicodedata.category(c) != 'Mn')
    return text.strip()

# ==========================================
# 1. LOGICA DE SWIPE SI MATCH
# ==========================================
@csrf_exempt
@api_view(['POST'])
def inregistreaza_swipe(request, swiped_user_id, tip_actiune):
    """
    Inregistreaza un swipe. Daca ambii dau LIKE (RIGHT), se creeaza un Match.
    """
    from_user_id = request.GET.get('from_user')

    # Identificam cine da swipe
    if request.user.is_authenticated:
        swiper = request.user
    elif from_user_id:
        swiper = get_object_or_404(User, id=from_user_id)
    else:
        return JsonResponse({'error': 'ID utilizator sursa lipseste'}, status=400)

    swiped_user = get_object_or_404(User, id=swiped_user_id)

    # Mapam actiunea din Flutter in formatul bazei de date
    action = 'RIGHT' if tip_actiune.lower() == 'like' else 'LEFT'

    # Stergem swipe-ul vechi daca exista pentru a permite re-swipe (Reset la login)
    Swipe.objects.filter(swiper=swiper, swiped_user=swiped_user).delete()

    # Salvam swipe-ul nou
    Swipe.objects.create(
        swiper=swiper,
        swiped_user=swiped_user,
        swipe_type=action
    )

    este_match = False
    if action == 'RIGHT':
        # Verificam daca swiped_user i-a dat deja RIGHT lui swiper
        reciproc = Swipe.objects.filter(
            swiper=swiped_user,
            swiped_user=swiper,
            swipe_type='RIGHT'
        ).exists()

        if reciproc:
            # Cream match-ul oficial in tabelul de Match
            Match.objects.get_or_create(user1=swiper, user2=swiped_user)
            este_match = True

    return JsonResponse({
        'status': 'success',
        'is_match': este_match,
        'matched_with': swiped_user.username if este_match else None
    })

# ==========================================
# 2. FILTRE SI DISCOVERY (PERMISIV)
# ==========================================
@api_view(['GET'])
def get_utilizatori_filtrati(request):
    try:
        user_id_url = request.GET.get('user_id')
        current_user = None

        if request.user.is_authenticated:
            current_user = request.user
        elif user_id_url:
            current_user = User.objects.filter(id=user_id_url).first()

        # Incepem cu toti userii
        potentiali = User.objects.all()

        if current_user:
            # Excludem doar propriul profil
            # NU mai folosim exclude(id__in=vazuti_ids) ca sa-i poti vedea iar
            potentiali = potentiali.exclude(id=current_user.id)

        rezultat_final = []
        for p in potentiali:
            try:
                profil_p = p.profile
                rezultat_final.append({
                    'id': p.id,
                    'username': p.username,
                    'age': profil_p.age or 20,
                    'bio': profil_p.bio or "Hey! Let's be buddies.",
                    'interests': profil_p.interests or "",
                    'profile_picture': profil_p.profile_picture.url if profil_p.profile_picture else None,
                })
            except Profile.DoesNotExist:
                continue

        return JsonResponse(rezultat_final, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

# ==========================================
# 3. ALTE FUNCTII
# ==========================================
def get_sugestii_interese(request):
    sugestii = ["Muzica", "Sport", "Filme", "Gaming", "Gatit", "Tehnologie"]
    return JsonResponse({'sugestii': sugestii})

@csrf_exempt
def actualizeaza_locatia(request):
    return JsonResponse({'status': 'ok'})