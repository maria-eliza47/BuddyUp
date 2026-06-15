import json
import requests
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
@csrf_exempt
@csrf_exempt
@csrf_exempt
def generate_icebreaker(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            target_username = data.get('target_user')
            
            # Găsim userii
            user1 = User.objects.get(id=user_id)
            user2 = User.objects.get(username=target_username)
            
            # Preluăm datele reale din tabelele voastre
            p1_interests = user1.profile.interests if hasattr(user1, 'profile') and user1.profile.interests else "Nespecificat"
            p2_interests = user2.profile.interests if hasattr(user2, 'profile') and user2.profile.interests else "Nespecificat"
            p2_bio = user2.profile.bio if hasattr(user2, 'profile') and user2.profile.bio else ""

            # Promptul care îi spune lui Llama 3 ce are de făcut
            prompt = (
                f"Ești un asistent AI pentru aplicația de matchmaking BuddyUp. Aplicatia ajuta persoane de pretutindeni sa lege prietenii. "
                f"Trebuie să generezi un spărgător de gheață (icebreaker) personalizat în limba română pentru doi utilizatori.\n"
                f"Utilizatorul curent: {user1.username} (Interese: {p1_interests}).\n"
                f"Utilizatorul țintă: {target_username} (Interese: {p2_interests}, Bio: {p2_bio}).\n"
                f"Cerință: Generează un singur mesaj de salut direct, prietenos și amuzant, axat pe interesele lor comune sau pe interesele utilizatorului țintă. "
                f"Nu include explicații, introduceri sau ghilimele. Returnează DOAR mesajul propriu-zis care va fi trimis direct pe chat."
                
            )

            # --- Conexiunea cu OLLAMA LOCAL (Fără Chei API) ---
            # Ollama ascultă implicit pe portul 11434 pe calculatorul tău
            ollama_url = "http://localhost:11434/api/generate"
            payload = {
                "model": "llama3",
                "prompt": prompt,
                "stream": False
            }
            
            # Trimitem cererea către AI-ul local
            # Am pus timeout-ul mai mare (30 secunde) pentru că generarea locală durează puțin mai mult decât pe serverele din cloud
            response = requests.post(ollama_url, json=payload, timeout=120)
            
            if response.status_code == 200:
                result = response.json()
                mesaj_generat = result.get('response', '').strip()
            else:
                mesaj_generat = f"Hei {target_username}! Mi-a atras atenția profilul tău. Cum îți merge ziua?"
            
            return JsonResponse({'suggestion': mesaj_generat}, status=200)
            
        except Exception as e:
            # Afișăm eroarea în terminalul Django ca să știm exact dacă a picat conexiunea cu Ollama
            print(f"❌ Eroare AI Local: {e}")
            return JsonResponse({'error': str(e)}, status=400)
            
    return JsonResponse({'error': 'Invalid request'}, status=405)