from django.db.models import Q
from django.http import JsonResponse
from django.contrib.auth.models import User
from .models import Match
from rest_framework.decorators import api_view
from chat.models import Thread # <-- Am adăugat importul pentru chat

@api_view(['GET'])
def lista_matchuri_utilizator(request):
    """
    Returneaza lista persoanelor cu care utilizatorul are un match reciproc.
    """
    user_id = request.GET.get('user_id')

    if not user_id:
        return JsonResponse({'error': 'ID utilizator lipsa'}, status=400)

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return JsonResponse({'error': 'Utilizator inexistent'}, status=404)

    matches = Match.objects.filter(Q(user1=user) | Q(user2=user))

    # --- FILTRU BLOCK ---
    from reports.models import Block
    blocked_by_me = Block.objects.filter(blocker=user).values_list('blocked_user_id', flat=True)
    blocked_me = Block.objects.filter(blocked_user=user).values_list('blocker_id', flat=True)
    exclude_ids = set(list(blocked_by_me) + list(blocked_me))

    data = []
    for m in matches:
        partner = m.user2 if m.user1 == user else m.user1

        if partner.id in exclude_ids:
            continue

        try:
            profil_p = partner.profile
            age = profil_p.age
            bio = profil_p.bio
        except:
            age = None
            bio = ""

        # --- Găsim sau creăm camera unică de chat pentru acești 2 useri ---
        thread = Thread.objects.filter(user1=user, user2=partner).first()
        if not thread:
            thread = Thread.objects.filter(user1=partner, user2=user).first()
        if not thread:
            thread = Thread.objects.create(user1=user, user2=partner)
        # -------------------------------------------------------------------

        data.append({
            'match_id': m.id,
            'user_id': partner.id,
            'username': partner.username,
            'age': age,
            'bio': bio,
            'data_match': m.created_at.strftime("%d-%m-%Y"),
            'thread_id': thread.id  # <-- ACUM TRIMITEM ID-UL REAL
        })

    return JsonResponse(data, safe=False)