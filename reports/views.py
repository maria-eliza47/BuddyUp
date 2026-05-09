import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from .models import Block, Report

@csrf_exempt
def block_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            # Extragem ID-urile din cerere
            blocker_id = data.get('blocker_id')
            blocked_id = data.get('blocked_id')
            
            blocker = User.objects.get(id=blocker_id)
            blocked_user = User.objects.get(id=blocked_id)
            
            # get_or_create ne asigură că dacă i-a dat deja block, nu va crea o dublură
            Block.objects.get_or_create(blocker=blocker, blocked_user=blocked_user)
            
            return JsonResponse({"success": True, "message": f"{blocker.username} l-a blocat pe {blocked_user.username}."})
        except User.DoesNotExist:
            return JsonResponse({"error": "Utilizatorul nu a fost găsit."}, status=404)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=400)
            
    return JsonResponse({"error": "Metodă nepermisă. Folosește POST."}, status=405)

@csrf_exempt
def report_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            reporter_id = data.get('reporter_id')
            reported_id = data.get('reported_id')
            reason = data.get('reason')
            description = data.get('description', '') # Opțional
            
            reporter = User.objects.get(id=reporter_id)
            reported_user = User.objects.get(id=reported_id)
            
            # Creăm raportul în baza de date
            Report.objects.create(
                reporter=reporter,
                reported_user=reported_user,
                reason=reason,
                description=description
            )
            
            return JsonResponse({"success": True, "message": f"Raportul pentru {reported_user.username} a fost înregistrat cu succes."})
        except User.DoesNotExist:
            return JsonResponse({"error": "Utilizatorul nu a fost găsit."}, status=404)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=400)
            
    return JsonResponse({"error": "Metodă nepermisă. Folosește POST."}, status=405)