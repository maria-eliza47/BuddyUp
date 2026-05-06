from django.http import JsonResponse
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404
from .models import Swipe
from matches.models import Match
from geopy.distance import geodesic

# ==========================================
# 1. LOGICA DE SWIPE SI MATCH
# ==========================================

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
    """
    Returneaza utilizatorii din apropiere, excluzand pe cei deja vazuti.
    """
    # Parametrii de filtrare (raza implicita 10km)
    raza_maxima = float(request.GET.get('raza', 10))

    # Presupunem ca datele GPS sunt in modelul Profile
    user_profil = request.user.profile
    my_coords = (user_profil.latitude, user_profil.longitude)

    # 1. Gasim ID-urile utilizatorilor carora le-ai dat deja swipe
    id_uri_swiped = Swipe.objects.filter(swiper=request.user).values_list('swiped_user_id', flat=True)

    # 2. Luam potentialii prieteni (excluzandu-te pe tine si pe cei deja swiped)
    potentiali = User.objects.exclude(id=request.user.id).exclude(id__in=id_uri_swiped)

    rezultat_final = []

    for p in potentiali:
        try:
            # Coordonatele potentialului prieten
            p_coords = (p.profile.latitude, p.profile.longitude)

            # CALCUL GPS: Folosim libraria geopy
            distanta = geodesic(my_coords, p_coords).km

            # FILTRARE: Doar daca este in raza de km setata
            if distanta <= raza_maxima:
                rezultat_final.append({
                    'id': p.id,
                    'username': p.username,
                    'distanta_km': round(distanta, 1),
                    'bio': p.profile.bio,
                    'interese': p.profile.interests
                })
        except AttributeError:
            # Sarim peste utilizatorii care nu au profilul completat (lat/lon lipsa)
            continue

    return JsonResponse({'users': rezultat_final})