from django.shortcuts import render
from django.contrib.auth.models import User
from .models import Swipe
from matches.models import Match
def inregistreaza_swipe(request, swiped_user_id, tip_actiune):
    # swiper = utilizatorul logat
    # swiped_user = utilizatorul de pe ecran
    # tip_actiune = 'LIKE' sau 'PASS'

    # 1. Salvăm swipe-ul în baza de date
    swipe = Swipe.objects.create(
        swiper=request.user,
        swiped_user_id=swiped_user_id,
        swipe_type=tip_actiune
    ) [cite: 45-49, 71, 91]

    # 2. Algoritm Match: Verificăm dacă și celălalt i-a dat LIKE
    if tip_actiune == 'LIKE':
        reciproc = Swipe.objects.filter(
            swiper_id=swiped_user_id,
            swiped_user=request.user,
            swipe_type='LIKE'
        ).exists() [cite: 106, 148]

        if reciproc:
            Match.objects.create(user1=request.user, user2_id=swiped_user_id) [cite: 50-53, 74, 92]
            return "Este un Match!"

    return "Swipe înregistrat"

from geopy.distance import geodesic

def filtreaza_dupa_distanta(user_profile, lista_utilizatori, raza_km):
    # Coordonatele tale
    punct_start = (user_profile.latitude, user_profile.longitude) # [cite: 40, 41]

    rezultat = []
    for u in lista_utilizatori:
        punct_destinatie = (u.profile.latitude, u.profile.longitude)
        distanta = geodesic(punct_start, punct_destinatie).km
        if distanta <= raza_km:
            rezultat.append(u)
    return rezultat