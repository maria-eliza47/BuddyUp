from django.db.models import Q
from django.http import JsonResponse
from .models import Match

def lista_matchuri_utilizator(request):
    """
    Returnează lista persoanelor cu care utilizatorul logat are un match reciproc.
    """
    user = request.user

    # Siguranță: dacă utilizatorul nu e logat (sesiune expirată)
    if not user.is_authenticated:
        return JsonResponse({'error': 'Trebuie să fii logat'}, status=401)

    # Căutăm meciurile unde userul logat este fie user1, fie user2
    matches = Match.objects.filter(Q(user1=user) | Q(user2=user))

    data = []
    for m in matches:
        partner = m.user2 if m.user1 == user else m.user1

        # Luăm și profilul partenerului pentru extra detalii (vârstă, bio)
        try:
            profil_p = partner.profile
            age = profil_p.age
            bio = profil_p.bio
        except:
            age = None
            bio = ""

        data.append({
            'match_id': m.id,
            'user_id': partner.id,
            'username': partner.username,
            'age': age,
            'bio': bio,
            'data_match': m.created_at.strftime("%d-%m-%Y")
        })

    return JsonResponse({'my_matches': data})