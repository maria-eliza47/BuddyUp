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

# ==========================================
# UTILITARE (Normalizare Text)
# ==========================================
def normalizeaza_text(text):
    if not text:
        return ""
    # 1. Litere mici
    text = text.lower()
    # 2. Scoatem diacriticele
    text = ''.join(c for c in unicodedata.normalize('NFD', text)
                   if unicodedata.category(c) != 'Mn')
    # 3. Scoatem spațiile de la margini
    return text.strip()

# ==========================================
# 1. LOGICA DE SWIPE SI MATCH
# ==========================================
def inregistreaza_swipe(request, swiped_user_id, tip_actiune):
    """
    Inregistreaza un swipe (LIKE/PASS) si verifica reciprocitatea pentru Match.
    """
    swiped_user = get_object_or_404(User, id=swiped_user_id)

    if request.user.id == swiped_user.id:
        return JsonResponse({'error': 'Nu iti poti da swipe singur'}, status=400)

    deja_vazut = Swipe.objects.filter(swiper=request.user, swiped_user=swiped_user).exists()
    if deja_vazut:
        return JsonResponse({'error': 'Ai dat deja swipe acestui utilizator'}, status=400)

    Swipe.objects.create(
        swiper=request.user,
        swiped_user=swiped_user,
        swipe_type=tip_actiune
    )

    este_match = False
    if tip_actiune == 'RIGHT':
        reciproc = Swipe.objects.filter(
            swiper=swiped_user,
            swiped_user=request.user,
            swipe_type='RIGHT'
        ).exists()

        if reciproc:
            Match.objects.get_or_create(user1=request.user, user2=swiped_user)
            este_match = True

    return JsonResponse({
        'status': 'success',
        'is_match': este_match,
        'message': 'Actiune inregistrata'
    })

# ==========================================
# 2. FILTRE, GPS SI DISCOVERY
# ==========================================
def get_utilizatori_filtrati(request):
    try:
        me = request.user.profile
        if me.latitude is None or me.longitude is None:
            return JsonResponse({'error': 'Locația ta nu este setată'}, status=400)
    except Profile.DoesNotExist:
        return JsonResponse({'error': 'Profil inexistent'}, status=404)

    # Parametri URL
    raza_maxima = float(request.GET.get('raza', 10))
    v_min = int(request.GET.get('varsta_min', 18))
    v_max = int(request.GET.get('varsta_max', 99))

    # Interesele mele
    if me.interests:
        my_interests = {normalizeaza_text(i) for i in me.interests.split(',') if i.strip()}
    else:
        my_interests = set()

    # Filtre de baza (activitate recenta + excludere swipe-uri vechi)
    limita_activitate = timezone.now() - timedelta(days=30)
    id_uri_swiped = Swipe.objects.filter(swiper=request.user).values_list('swiped_user_id', flat=True)

    potentiali = User.objects.exclude(id=request.user.id) \
        .exclude(id__in=id_uri_swiped) \
        .filter(last_login__gte=limita_activitate)

    rezultat_final = []

    for p in potentiali:
        try:
            profil_p = p.profile
            if profil_p.age is None:
                continue
        except Profile.DoesNotExist:
            continue

        # 1. FILTRU VÂRSTĂ
        if not (v_min <= profil_p.age <= v_max):
            continue

        # 2. FILTRU GPS
        distanta = geodesic((me.latitude, me.longitude), (profil_p.latitude, profil_p.longitude)).km
        if distanta > raza_maxima:
            continue

        # 3. CALCUL INTERESE COMUNE
        if profil_p.interests:
            p_interests = {normalizeaza_text(i) for i in profil_p.interests.split(',') if i.strip()}
        else:
            p_interests = set()
        comune = my_interests.intersection(p_interests)

        # 4. CALCUL STATUS ACTIVITATE
        acum = timezone.now()
        diferenta = acum - p.last_login
        if diferenta < timedelta(minutes=15):
            status = "Activ acum"
        elif diferenta < timedelta(hours=24):
            status = "Activ azi"
        else:
            status = f"Activ acum {diferenta.days} zile"

        # 5. CALCUL MEMBRU NOU (inscris in ultimele 48h)
        este_nou = p.date_joined > (timezone.now() - timedelta(days=2))

        rezultat_final.append({
            'id': p.id,
            'username': p.username,
            'distanta_km': round(distanta, 1),
            'interese_comune': list(comune),
            'scor_match': len(comune),
            'status_activitate': status,
            'este_nou': este_nou,
            'ultima_logare': p.last_login.strftime("%Y-%m-%d %H:%M")
        })

    # Sortare dupa scor
    rezultat_final = sorted(rezultat_final, key=lambda x: x['scor_match'], reverse=True)
    return JsonResponse({'users': rezultat_final})

# ==========================================
# 3. API SUGESTII INTERESE
# ==========================================
def get_sugestii_interese(request):
    """
    Returneaza lista oficiala de sugestii pentru interese.
    """
    sugestii = [
        "Muzică", "Sport", "Filme", "Călătorit", "Animale",
        "Gaming", "Gătit", "Fotografie", "Lectură", "Voluntariat",
        "Tehnologie", "Artă", "Cafea", "Drumeții", "Board Games",
        "Fitness", "Pictură", "Dans", "Programare", "Modă", "Seriale",
        "Fotbal", "Baschet", "Gym", "Yoga", "Pilates", "Boxing", "Ciclism",
        "Camping", "Design Interior", "Desen Grafic", "Astronomie", "Teatru",
    ]
    return JsonResponse({'sugestii': sugestii})

# ==========================================
# 4. ACTUALIZARE LOCATIE
# ==========================================
@csrf_exempt
def actualizeaza_locatia(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_profile = request.user.profile
            user_profile.latitude = data.get('latitude')
            user_profile.longitude = data.get('longitude')
            user_profile.save()
            return JsonResponse({'status': 'success', 'message': 'Locație salvată!'})
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)
    return JsonResponse({'status': 'error', 'message': 'Doar POST permis'}, status=405)