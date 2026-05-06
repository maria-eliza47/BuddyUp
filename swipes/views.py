from django.http import JsonResponse
from .models import Swipe
from matches.models import Match
from django.contrib.auth.models import User

def inregistreaza_swipe(request, swiped_user_id, tip_actiune):
    # 1. Salvează swipe-ul curent în baza de date
    swipe = Swipe.objects.create(
        swiper=request.user,
        swiped_user_id=swiped_user_id,
        swipe_type=tip_actiune
    )

    match_gasit = False
    if tip_actiune == 'RIGHT':
        # 2. Algoritmul de Match: Căutăm dacă și celălalt a dat LIKE
        reciproc = Swipe.objects.filter(
            swiper_id=swiped_user_id,
            swiped_user=request.user,
            swipe_type='RIGHT'
        ).exists()

        if reciproc:
            # 3. Creăm Match-ul oficial
            Match.objects.create(user1=request.user, user2_id=swiped_user_id)
            match_gasit = True

    return JsonResponse({'status': 'success', 'match': match_gasit})
from geopy.distance import geodesic

def filtreaza_utilizatori_apropiati(request, raza_km=10):
    # 1. Luăm profilul utilizatorului logat (presupunem că are lat/lon)
    # În mod normal, Laura se ocupă de Profiles, dar tu ai nevoie de ele aici
    me = request.user.profile
    my_coords = (me.latitude, me.longitude)

    # 2. Luăm toți ceilalți utilizatori
    toti_ceilalți = User.objects.exclude(id=request.user.id)
    utilizatori_in_raza = []

    for user in toti_ceilalți:
        friend_coords = (user.profile.latitude, user.profile.longitude)

        # 3. Calculăm distanța folosind librăria instalată
        distanta = geodesic(my_coords, friend_coords).km

        if distanta <= raza_km:
            utilizatori_in_raza.append(user)

    # Această listă va fi trimisă către Frontend pentru a fi afișată
    return utilizatori_in_raza