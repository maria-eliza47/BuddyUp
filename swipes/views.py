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
# 1. LOGICA DE SWIPE SI MATCH
# ==========================================
def normalizeaza_text(text):
    if not text:
        return ""
    # 1. Litere mici
    text = text.lower()
    # 2. Scoatem diacriticele (ă->a, î->i, etc.)
    text = ''.join(c for c in unicodedata.normalize('NFD', text)
                   if unicodedata.category(c) != 'Mn')
    # 3. Scoatem spațiile de la margini
    return text.strip()
def inregistreaza_swipe(request, swiped_user_id, tip_actiune):
    """
    Inregistreaza un swipe (LIKE/PASS) si verifica reciprocitatea pentru Match.
    """
    swiped_user = get_object_or_404(User, id=swiped_user_id)

    # SIGURANTA: Nu poti sa-ti dai swipe singur
    if request.user.id == swiped_user.id:
        return JsonResponse({'error': 'Nu iti poti da swipe singur'}, status=400)

    # SIGURANTA: Verificam daca ai mai dat deja swipe acestui utilizator (anti-duplicat)
    deja_vazut = Swipe.objects.filter(swiper=request.user, swiped_user=swiped_user).exists()
    if deja_vazut:
        return JsonResponse({'error': 'Ai dat deja swipe acestui utilizator'}, status=400)

    # SALVARE: Inregistram actiunea in baza de date
    Swipe.objects.create(
        swiper=request.user,
        swiped_user=swiped_user,
        swipe_type=tip_actiune
    )

    este_match = False

    if tip_actiune == 'RIGHT':
        # ALGORITM MATCH: Verificam daca si celalalt utilizator ti-a dat RIGHT anterior
        reciproc = Swipe.objects.filter(
            swiper=swiped_user,
            swiped_user=request.user,
            swipe_type='RIGHT'
        ).exists()

        if reciproc:
            # Cream Match-ul oficial (get_or_create previne erorile de duplicare la nivel de DB)
            Match.objects.get_or_create(user1=request.user, user2=swiped_user)
            este_match = True

    return JsonResponse({
        'status': 'success',
        'is_match': este_match,
        'message': 'Actiune inregistrata'
    })

# ==========================================
# 2. FILTRE SI GPS DISTANCE
# ==========================================

def get_utilizatori_filtrati(request):
    try:
        me = request.user.profile
        if me.latitude is None or me.longitude is None:
            return JsonResponse({'error': 'Locația ta nu este setată'}, status=400)
    except Profile.DoesNotExist:
        return JsonResponse({'error': 'Profil inexistent'}, status=404)
    # Parametri primiți din URL (ex: ?raza=10&varsta_min=18&varsta_max=25)
    raza_maxima = float(request.GET.get('raza', 10))
    v_min = int(request.GET.get('varsta_min', 18))
    v_max = int(request.GET.get('varsta_max', 99))

    if me.interests:
        my_interests = {normalizeaza_text(i) for i in me.interests.split(',') if i.strip()}
    else:
        my_interests = set()

    id_uri_swiped = Swipe.objects.filter(swiper=request.user).values_list('swiped_user_id', flat=True)
    potentiali = User.objects.exclude(id=request.user.id).exclude(id__in=id_uri_swiped)

    rezultat_final = []

    for p in potentiali:
        try:
            profil_p = p.profile
            if profil_p.age is None:
                continue
        except Profile.DoesNotExist:
            continue

        # Acestea trebuie să fie aliniate cu try-ul (nu în interiorul lui!)
        # 1. FILTRU VÂRSTĂ
        if not (v_min <= profil_p.age <= v_max):
            continue

        # 2. FILTRU GPS
        distanta = geodesic((me.latitude, me.longitude), (profil_p.latitude, profil_p.longitude)).km
        if distanta > raza_maxima:
            continue


        if profil_p.interests:
            p_interests = {normalizeaza_text(i) for i in profil_p.interests.split(',') if i.strip()}
        else:
            p_interests = set()

        comune = my_interests.intersection(p_interests)

        rezultat_final.append({
            'id': p.id,
            'username': p.username,
            'distanta_km': round(distanta, 1),
            'interese_comune': list(comune),
            'scor_match': len(comune)
        })

    # Sortăm lista după numărul de interese comune (cei mai compatibili primii)
    rezultat_final = sorted(rezultat_final, key=lambda x: x['scor_match'], reverse=True)

    return JsonResponse({'users': rezultat_final})

@csrf_exempt # Important pentru cererile de pe mobil
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