from django.http import JsonResponse
from .models import Match
from django.db.models import Q

def lista_matchuri_utilizator(request):
    """
    Afisarea utilizatorilor cu care ai deja un match reciproc.
    """
    user = request.user
    # Cautam meciurile unde userul logat este fie user1, fie user2
    matches = Match.objects.filter(Q(user1=user) | Q(user2=user))

    data = []
    for m in matches:
        # Aflam cine este celalalt utilizator
        partner = m.user2 if m.user1 == user else m.user1
        data.append({
            'match_id': m.id,
            'user_id': partner.id,
            'username': partner.username,
            'data_match': m.created_at.strftime("%d-%m-%Y")
        })

    return JsonResponse({'my_matches': data})