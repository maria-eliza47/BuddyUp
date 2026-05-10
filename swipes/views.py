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
# UTILITARE (Normalizare si Curatare)
# ==========================================
def normalizeaza_text(text):
    """Elimina diacriticele si transforma in litere mici."""
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

    # Identificare Swiper (cel care trimite swipe-ul)
    swiper = None
    if request.user.is_authenticated:
        swiper = request.user
    elif from_user_id and from_user_id != 'null':
        swiper = User.objects.filter(id=from_user_id).first()

    if not swiper:
        return JsonResponse({'error': 'Utilizator sursa neidentificat'}, status=400)

    swiped_user = get_object_or_404(User, id=swiped_user_id)

    # Mapam actiunea din Flutter (like/dislike) -> DB (RIGHT/LEFT)
    action = 'RIGHT' if tip_actiune.lower() == 'like' else 'LEFT'

    # Stergem swipe-ul vechi daca exista pentru a permite re-swipe (Reset la login)
    Swipe.objects.filter(swiper=swiper, swiped_user=swiped_user).delete()

    # Salvam noul swipe
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
            # Cream match-ul oficial (evitam duplicatele prin sortarea ID-urilor)
            u1, u2 = (swiper, swiped_user) if swiper.id < swiped_user.id else (swiped_user, swiper)
            Match.objects.get_or_create(user1=u1, user2=u2)
            este_match = True

    return JsonResponse({
        'status': 'success',
        'is_match': este_match,
        'matched_with': swiped_user.username if este_match else None
    })

# ==========================================
# 2. FILTRE SI DISCOVERY (FIX PENTRU LOADING)
# ==========================================
@api_view(['GET'])
def get_utilizatori_filtrati(request):
    """
    Returneaza lista de utilizatori pentru ecranul de Swipe.
    """
    try:
        user_id_url = request.GET.get('user_id')
        current_user = None

        # Detectam utilizatorul curent
        if request.user.is_authenticated:
            current_user = request.user
        elif user_id_url and user_id_url != 'null':
            current_user = User.objects.filter(id=user_id_url).first()

        # Incepem cu toti utilizatorii
        potentiali = User.objects.all().select_related('profile')

        # Daca stim cine e user-ul, il excludem pe el insusi
        if current_user:
            potentiali = potentiali.exclude(id=current_user.id)

            # OPTIONAL: Daca vrei sa ascunzi userii carora le-ai dat deja swipe,
            # de-comenteaza linia de mai jos:
            # vazuti_ids = Swipe.objects.filter(swiper=current_user).values_list('swiped_user_id', flat=True)
            # potentiali = potentiali.exclude(id__in=vazuti_ids)

        rezultat_final = []
        for p in potentiali:
            try:
                # Daca utilizatorul nu are profil creat, il sarim pentru a evita erorile
                if not hasattr(p, 'profile'):
                    continue

                profil_p = p.profile

                # Rezolvam URL-ul pozei de profil
                foto_url = None
                if profil_p.profile_picture:
                    foto_url = profil_p.profile_picture.url

                rezultat_final.append({
                    'id': p.id,
                    'username': p.username,
                    'age': profil_p.age or 20,
                    'bio': profil_p.bio or "Hey! Let's be buddies.",
                    'interests': profil_p.interests or "",
                    'profile_picture': foto_url,
                })
            except Exception as e:
                # Daca un profil are date corupte, trecem peste el fara sa blocam lista
                print(f"Eroare la procesarea profilului {p.id}: {e}")
                continue

        # Returnam lista (chiar daca e goala, cercul de loading se va opri)
        return JsonResponse(rezultat_final, safe=False)

    except Exception as e:
        print(f"EROARE CRITICA SERVER: {e}")
        return JsonResponse({'error': str(e)}, status=500)

# ==========================================
# 3. ALTE FUNCTII
# ==========================================
def get_sugestii_interese(request):
    sugestii = ["Muzica", "Sport", "Filme", "Gaming", "Gatit", "Tehnologie", "Calatorii", "Arta"]
    return JsonResponse({'sugestii': sugestii})

@csrf_exempt
def actualizeaza_locatia(request):
    """Endpoint pentru update GPS (placeholder)."""
    return JsonResponse({'status': 'ok'})
from django.http import JsonResponse
from profiles.models import Profile  # Asigură-te că importul modelului e corect
import random

def get_ai_top_picks(request):
    user_id = request.GET.get('user_id')
    
    try:
        # 1. Luăm profilul tău ca să știm ce interese ai
        my_profile = Profile.objects.get(user_id=user_id)
        my_interests = my_profile.interests.lower() if my_profile.interests else ""

        # 2. Luăm toți ceilalți utilizatori (excluzându-te pe tine)
        other_profiles = Profile.objects.exclude(user_id=user_id)

        # 3. Logică simplă de Matchmaking: căutăm pe cineva cu interese similare
        best_match = None
        for p in other_profiles:
            if p.interests:
                # Verificăm dacă există cuvinte comune în interese
                common_interests = set(my_interests.split(',')) & set(p.interests.lower().split(','))
                if common_interests:
                    best_match = p
                    break
        
        # Dacă nu am găsit prin interese, luăm pe cineva la întâmplare ca să nu rămână gol
        if not best_match and other_profiles.exists():
            best_match = random.choice(other_profiles)

        if best_match:
            # Construim răspunsul cu date reale din DB
            recommendation = [{
                "id": best_match.user.id,
                "username": best_match.user.username,
                "age": best_match.age,
                "interests": best_match.interests,
                # Aici simulăm ce ar zice Llama3 bazat pe datele reale
                "ai_reason": f"✨ Recomandare specială! Am observat că amândoi sunteți interesați de '{best_match.interests}'. Bazat pe profilul tău, cred că ați avea multe de discutat!"
            }]
            return JsonResponse(recommendation, safe=False)
        else:
            return JsonResponse([], safe=False)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)