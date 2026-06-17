from django.db import models
from django.contrib.auth.models import User

class Thread(models.Model):
    # Cei doi participanți la discuție
    user1 = models.ForeignKey(User, related_name='threads_started', on_delete=models.CASCADE)
    user2 = models.ForeignKey(User, related_name='threads_received', on_delete=models.CASCADE)
    
    # Ca să știm când a fost trimis ultimul mesaj (pentru a ordona lista de conversații)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Conversație: {self.user1.username} & {self.user2.username}"

class Message(models.Model):
    # De care conversație aparține mesajul
    thread = models.ForeignKey(Thread, related_name='messages', on_delete=models.CASCADE)
    # Cine a scris mesajul
    sender = models.ForeignKey(User, related_name='sent_messages', on_delete=models.CASCADE)
    
    # Textul efectiv
    text = models.TextField()
    # Când a fost trimis
    created_at = models.DateTimeField(auto_now_add=True)
    # Dacă a fost văzut sau nu (pentru notificări tip "Seen")
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.sender.username}: {self.text[:20]}..."