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
import random
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

    swiper = None
    if request.user.is_authenticated:
        swiper = request.user
    elif from_user_id and from_user_id != 'null':
        swiper = User.objects.filter(id=from_user_id).first()

    if not swiper:
        return JsonResponse({'error': 'Utilizator sursa neidentificat'}, status=400)

    swiped_user = get_object_or_404(User, id=swiped_user_id)
    action = 'RIGHT' if tip_actiune.lower() == 'like' else 'LEFT'

    Swipe.objects.filter(swiper=swiper, swiped_user=swiped_user).delete()
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
            u1, u2 = (swiper, swiped_user) if swiper.id < swiped_user.id else (swiped_user, swiper)
            Match.objects.get_or_create(user1=u1, user2=u2)
            este_match = True

    return JsonResponse({
        'status': 'success',
        'is_match': este_match,
        'matched_with': swiped_user.username if este_match else None
    })


# ==========================================
# 2. FILTRE SI DISCOVERY
# ==========================================

@api_view(['GET'])
def get_utilizatori_filtrati(request):
    """
    Returneaza lista de utilizatori pentru ecranul de Swipe,
    inclusiv distanta fata de utilizatorul curent (daca are locatia salvata).
    """
    try:
        user_id_url = request.GET.get('user_id')
        current_user = None

        if request.user.is_authenticated:
            current_user = request.user
        elif user_id_url and user_id_url != 'null':
            current_user = User.objects.filter(id=user_id_url).first()

        # Preluam coordonatele utilizatorului curent pentru calculul distantei
        my_lat, my_lon = None, None
        if current_user:
            try:
                my_lat = current_user.profile.latitude
                my_lon = current_user.profile.longitude
            except Exception:
                pass

        potentiali = User.objects.all().select_related('profile')

        if current_user:
            potentiali = potentiali.exclude(id=current_user.id)

        rezultat_final = []
        for p in potentiali:
            try:
                if not hasattr(p, 'profile'):
                    continue

                profil_p = p.profile

                foto_url = None
                if profil_p.profile_picture:
                    foto_url = profil_p.profile_picture.url

                # Calculam distanta cu geopy daca ambii au coordonate
                distance_km = None
                if (my_lat is not None and my_lon is not None
                        and profil_p.latitude is not None
                        and profil_p.longitude is not None):
                    distance_km = round(
                        geodesic(
                            (my_lat, my_lon),
                            (profil_p.latitude, profil_p.longitude)
                        ).km,
                        1
                    )

                rezultat_final.append({
                    'id': p.id,
                    'username': p.username,
                    'age': profil_p.age or 20,
                    'bio': profil_p.bio or "Hey! Let's be buddies.",
                    'interests': profil_p.interests or "",
                    'profile_picture': foto_url,
                    'distance_km': distance_km,
                })
            except Exception as e:
                print(f"Eroare la procesarea profilului {p.id}: {e}")
                continue

        return JsonResponse(rezultat_final, safe=False)

    except Exception as e:
        print(f"EROARE CRITICA SERVER: {e}")
        return JsonResponse({'error': str(e)}, status=500)


# ==========================================
# 3. UPDATE LOCATIE GPS
# ==========================================

@csrf_exempt
def actualizeaza_locatia(request):
    """
    Primeste latitudinea si longitudinea de la Flutter si le salveaza in Profile.
    Body JSON: { "user_id": 1, "latitude": 44.43, "longitude": 26.10 }
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)

    try:
        data = json.loads(request.body)
        user_id = data.get('user_id')
        lat = data.get('latitude')
        lon = data.get('longitude')

        if user_id is None or lat is None or lon is None:
            return JsonResponse({'error': 'Missing fields: user_id, latitude, longitude'}, status=400)

        profile = Profile.objects.get(user_id=user_id)
        profile.latitude = float(lat)
        profile.longitude = float(lon)
        profile.save(update_fields=['latitude', 'longitude'])

        return JsonResponse({'status': 'ok'})

    except Profile.DoesNotExist:
        return JsonResponse({'error': 'Profile not found'}, status=404)
    except (json.JSONDecodeError, TypeError, ValueError) as e:
        return JsonResponse({'error': f'Invalid data: {e}'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ==========================================
# 4. ALTE FUNCTII
# ==========================================

def get_sugestii_interese(request):
    sugestii = ["Muzica", "Sport", "Filme", "Gaming", "Gatit", "Tehnologie", "Calatorii", "Arta"]
    return JsonResponse({'sugestii': sugestii})

@csrf_exempt
def actualizeaza_locatia(request):
    """Endpoint pentru update GPS (placeholder)."""
    return JsonResponse({'status': 'ok'})

def get_ai_top_picks(request):
    user_id = request.GET.get('user_id')

    try:
        my_profile = Profile.objects.get(user_id=user_id)
        my_interests = my_profile.interests.lower() if my_profile.interests else ""

        other_profiles = Profile.objects.exclude(user_id=user_id)

        best_match = None
        for p in other_profiles:
            if p.interests:
                common_interests = set(my_interests.split(',')) & set(p.interests.lower().split(','))
                if common_interests:
                    best_match = p
                    break

        if not best_match and other_profiles.exists():
            best_match = random.choice(other_profiles)

        if best_match:
            recommendation = [{
                "id": best_match.user.id,
                "username": best_match.user.username,
                "age": best_match.age,
                "interests": best_match.interests,
                "ai_reason": (
                    f"✨ Recomandare specială! Am observat că amândoi sunteți interesați de "
                    f"'{best_match.interests}'. Bazat pe profilul tău, cred că ați avea multe de discutat!"
                )
            }]
            return JsonResponse(recommendation, safe=False)
        else:
            return JsonResponse([], safe=False)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
