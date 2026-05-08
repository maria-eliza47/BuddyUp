from django.http import JsonResponse
from .services import AIAgentService
from profiles.models import Profile # <-- ACESTA este rândul care lipsea/era pus greșit

def test_icebreaker(request):
    agent = AIAgentService()
    
    # 1. Luăm profilurile din baza de date
    profiles = Profile.objects.all()
    
    # 2. Ne asigurăm că avem măcar 2 oameni pentru a face o conversație
    if profiles.count() < 2:
        return JsonResponse({"error": "Sunt necesare minim 2 profiluri în baza de date pentru a genera un icebreaker."})
        
    # 3. Selectăm primii doi utilizatori
    user1 = profiles[0]
    user2 = profiles[1]
    
    # 4. Extragem interesele lor reale (sau punem un text default dacă au lăsat gol)
    user1_interests = user1.interests if user1.interests else "discuții generale"
    user2_interests = user2.interests if user2.interests else "discuții generale"
    
    # 5. Generăm icebreaker-ul
    result = agent.generate_icebreaker(
        user_interests=user1_interests,
        match_interests=user2_interests,
        location="București"
    )
    
    return JsonResponse({
        "conversatie_intre": f"{user1.user.username} și {user2.user.username}",
        "user1_interese": user1_interests,
        "user2_interese": user2_interests,
        "icebreaker_suggestion": result
    })


def test_matchmaker(request):
    agent = AIAgentService()
    
    # Luăm toate profilurile reale create de tine în Admin
    all_profiles = Profile.objects.all()
    
    if not all_profiles.exists():
        return JsonResponse({"error": "Nu există profiluri în baza de date. Adaugă câteva din Admin!"})

    # Primul profil din listă este "utilizatorul curent"
    me = all_profiles[0]
    me_data = f"Nume: {me.user.username}. Interese: {me.interests}. Bio: {me.bio}"
    
    # Restul sunt potențialele potriviri
    others = []
    for p in all_profiles[1:]:
        others.append(f"Nume: {p.user.username}. Interese: {p.interests}. Bio: {p.bio}")
    
    # Trimitem datele către funcția din services.py
    result = agent.generate_smart_match(current_user_data=me_data, other_profiles_data=others)
    
    return JsonResponse({
        "matching_for": me.user.username,
        "ai_recommendation": result
    })