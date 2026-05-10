import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from .models import Thread, Message

# 1. Pornește sau găsește o conversație
@csrf_exempt
def get_or_create_thread(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user1_id = data.get('user1_id')
            user2_id = data.get('user2_id')

            user1 = User.objects.get(id=user1_id)
            user2 = User.objects.get(id=user2_id)

            # Verificăm dacă există deja o discuție între ei (indiferent cine a început-o)
            thread = Thread.objects.filter(user1=user1, user2=user2).first()
            if not thread:
                thread = Thread.objects.filter(user1=user2, user2=user1).first()

            # Dacă nu au mai vorbit niciodată, le creăm o cameră nouă
            if not thread:
                thread = Thread.objects.create(user1=user1, user2=user2)

            return JsonResponse({"success": True, "thread_id": thread.id})
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=400)
    return JsonResponse({"error": "Folosește POST"}, status=405)


# 2. Trimite un mesaj nou
@csrf_exempt
def send_message(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            thread_id = data.get('thread_id')
            sender_id = data.get('sender_id')
            text = data.get('text')

            thread = Thread.objects.get(id=thread_id)
            sender = User.objects.get(id=sender_id)

            # Salvăm mesajul în baza de date
            msg = Message.objects.create(thread=thread, sender=sender, text=text)

            # Actualizăm timpul conversației (ca să apară prima în listă, la fel ca pe WhatsApp)
            thread.save()

            return JsonResponse({"success": True, "message_id": msg.id, "text": msg.text})
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=400)
    return JsonResponse({"error": "Folosește POST"}, status=405)


# 3. Citește istoricul de mesaje
def get_messages(request, thread_id):
    if request.method == 'GET':
        try:
            thread = Thread.objects.get(id=thread_id)
            # Extragem toate mesajele din această conversație, ordonate după dată
            messages = thread.messages.all().order_by('created_at')
            
            # Le transformăm într-o listă pe care aplicația o poate citi
            msg_list = []
            for m in messages:
                msg_list.append({
                    "id": m.id,
                    "sender": m.sender.username,
                    "text": m.text,
                    "created_at": m.created_at.strftime("%Y-%m-%d %H:%M:%S")
                })

            return JsonResponse({"success": True, "thread_id": thread.id, "messages": msg_list})
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=400)
    return JsonResponse({"error": "Folosește GET"}, status=405)
@csrf_exempt
def generate_icebreaker(request):
    if request.method == 'POST':
        try:
            # Citim datele trimise de Flutter (ID-ul tau, numele lui, etc.)
            data = json.loads(request.body)
            user_id = data.get('user_id')
            target_user = data.get('target_user')
            
            # ---------------------------------------------------------
            # AICI VA VENI CODUL TAU PENTRU LLAMA 3 IN VIITOR
            # Ex: suggestion = llama_agent.generate(user_id, target_user, location="Ploiesti")
            # ---------------------------------------------------------
            
            # Pentru testarea interfetei, generam un raspuns "fals" temporar:
            mesaj_generat = f"Hei! Amândoi suntem din Ploiești. Ce-ar fi să spargem gheața cu o cafea prin centru la final de săptămână?"
            
            # Il trimitem inapoi catre Flutter exact in formatul asteptat
            return JsonResponse({'suggestion': mesaj_generat}, status=200)
            
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)
            
    return JsonResponse({'error': 'Invalid request'}, status=405)