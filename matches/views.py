from django.db.models import Q
from django.http import JsonResponse
from django.contrib.auth.models import User
from .models import Match
from rest_framework.decorators import api_view

@api_view(['GET'])
def lista_matchuri_utilizator(request):
    """
    Returneaza lista persoanelor cu care utilizatorul are un match reciproc.
    """
    # Luam user_id din URL (?user_id=X)
    user_id = request.GET.get('user_id')

    if not user_id:
        return JsonResponse({'error': 'ID utilizator lipsa'}, status=400)

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return JsonResponse({'error': 'Utilizator inexistent'}, status=404)

    # Cautam meciurile unde userul este fie user1, fie user2
    matches = Match.objects.filter(Q(user1=user) | Q(user2=user))

    data = []
    for m in matches:
        partner = m.user2 if m.user1 == user else m.user1

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

    # Returnam lista DIRECT (safe=False este esential aici)
    return JsonResponse(data, safe=False)