from django.utils import timezone
from datetime import timedelta
from django.http import JsonResponse
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404
from .models import Swipe
from matches.models import Match
from geopy.distance import geodesic
import json
import requests
import unicodedata
from django.views.decorators.csrf import csrf_exempt
from profiles.models import (
    Profile,
    ProfileImage
)
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
    elif from_user_id and from_user_id != 'null':
        swiper = User.objects.filter(id=from_user_id).first()

    if not swiper:
        return JsonResponse({'error': 'Utilizator sursa neidentificat'}, status=400)

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
            u1, u2 = (swiper, swiped_user) if swiper.id < swiped_user.id else (swiped_user, swiper)
            Match.objects.get_or_create(user1=u1, user2=u2)
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
            # Excludem doar propriul profil
            # NU mai folosim exclude(id__in=vazuti_ids) ca sa-i poti vedea iar
            potentiali = potentiali.exclude(id=current_user.id)

        rezultat_final = []
        for p in potentiali:
            try:
                profil_p = p.profile

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


                # Rezolvam URL-ul pozei de profil
                foto_url = None
                if profil_p.profile_picture:
                     foto_url = request.build_absolute_uri(
                        profil_p.profile_picture.url
                    )

                gallery_images = []

                for img in ProfileImage.objects.filter(
                    profile=profil_p
                )[:6]:

                    gallery_images.append(
                        request.build_absolute_uri(
                            img.image.url
                         )
                     )

                rezultat_final.append({
                'id': p.id,
                'username': p.username,
                'age': profil_p.age or 20,
                'bio': profil_p.bio or "Hey! Let's be buddies.",
                'interests': profil_p.interests or "",
                'profile_picture': foto_url,
                'gallery_images': gallery_images,
                'distance_km': distance_km,
            })
            except Exception as e:
                # Daca un profil are date corupte, trecem peste el fara sa blocam lista
                print(f"Eroare la procesarea profilului {p.id}: {e}")
                continue

        return JsonResponse(rezultat_final, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
    

@csrf_exempt
def actualizeaza_locatia(request):
    """
    Primeste latitudinea si longitudinea de la Flutter
    si le salveaza in Profile.

    Body JSON:
    {
        "user_id": 1,
        "latitude": 44.43,
        "longitude": 26.10
    }
    """

    if request.method != 'POST':
        return JsonResponse(
            {'error': 'POST required'},
            status=405
        )

    try:
        data = json.loads(request.body)

        user_id = data.get('user_id')
        lat = data.get('latitude')
        lon = data.get('longitude')

        if (
            user_id is None or
            lat is None or
            lon is None
        ):
            return JsonResponse(
                {
                    'error':
                    'Missing fields: user_id, latitude, longitude'
                },
                status=400
            )

        profile = Profile.objects.get(
            user_id=user_id
        )

        profile.latitude = float(lat)
        profile.longitude = float(lon)

        profile.save(
            update_fields=[
                'latitude',
                'longitude'
            ]
        )

        return JsonResponse({
            'status': 'ok'
        })

    except Profile.DoesNotExist:

        return JsonResponse(
            {'error': 'Profile not found'},
            status=404
        )

    except (
        json.JSONDecodeError,
        TypeError,
        ValueError
    ) as e:

        return JsonResponse(
            {'error': f'Invalid data: {e}'},
            status=400
        )

    except Exception as e:

        return JsonResponse(
            {'error': str(e)},
            status=500
        )



# ==========================================
# 3. ALTE FUNCTII
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


def get_ai_top_picks(request):
    user_id = request.GET.get('user_id')

    try:
        my_profile = Profile.objects.get(
            user_id=user_id
        )

        my_interests = (
            my_profile.interests
            if my_profile.interests
            else ""
        )

        my_bio = (
            my_profile.bio
            if my_profile.bio
            else ""
        )

        other_profiles = Profile.objects.exclude(
            user_id=user_id
        )

        if not other_profiles.exists():
            return JsonResponse(
                [],
                safe=False
            )

        best_match = None

        for p in other_profiles:

            if p.interests and my_interests:

                common = (
                    set(my_interests.lower().split(','))
                    &
                    set(p.interests.lower().split(','))
                )

                if common:
                    best_match = p
                    break

        if not best_match:
            best_match = random.choice(
                other_profiles
            )

        interese_afisate = (
            best_match.interests
            if best_match.interests
            else "Diverse pasiuni"
        )

        prompt = (
            f"Ești expertul în matchmaking AI al aplicației BuddyUp- folosita pentru a lega prietenii."
            f"Analizează aceste două profiluri și generează o justificare scurtă și convingătoare în limba română (maxim 2 propoziții) "
            f"despre de ce acești doi utilizatori sunt o potrivire excelentă.\n"
            f"Utilizatorul 1: Interese: {my_interests}, Bio: {my_bio}\n"
            f"Utilizatorul 2: Username: {best_match.user.username}, Interese: {best_match.interests}, Bio: {best_match.bio}\n"
            f"Începe textul direct cu un emoji steluță (✨) și nu folosi introduceri plictisitoare. Justificarea trebuie să fie adresată direct primului utilizator."
        )

        ollama_url = (
            "http://localhost:11434/api/generate"
        )

        payload = {
            "model": "llama3",
            "prompt": prompt,
            "stream": False
        }

        try:
            response = requests.post(
                ollama_url,
                json=payload,
                timeout=120
            )

            if response.status_code == 200:

                result = response.json()

                ai_reason = result.get(
                    'response',
                    ''
                ).strip()

            else:
                ai_reason = (
                    f"✨ Recomandare specială! "
                    f"Analiza AI indică compatibilitate ridicată "
                    f"pe baza interesului pentru: "
                    f"{interese_afisate}."
                )

        except Exception as e:

            print(
                f"❌ Eroare AI Local (Matchmaker): {e}"
            )

            ai_reason = (
                "✨ Recomandare specială! "
                "Potrivire ridicată pe baza "
                "profilurilor voastre din baza de date."
            )

        recommendation = [{
            "id": best_match.user.id,
            "username": best_match.user.username,
            "age": best_match.age or 20,
            "interests": interese_afisate,
            "ai_reason": ai_reason
        }]

        return JsonResponse(
            recommendation,
            safe=False
        )

    except Exception as e:

        return JsonResponse(
            {'error': str(e)},
            status=500
        )