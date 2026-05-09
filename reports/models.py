from django.db import models
from django.contrib.auth.models import User

class Block(models.Model):
    # Cel care dă block
    blocker = models.ForeignKey(User, related_name='blocking', on_delete=models.CASCADE)
    # Cel care primește block
    blocked_user = models.ForeignKey(User, related_name='blocked_by', on_delete=models.CASCADE)
    
    # Când a fost dat block-ul
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Ne asigurăm că User A nu îi poate da block lui User B de 10 ori (evităm duplicatele)
        unique_together = ('blocker', 'blocked_user')

    def __str__(self):
        return f"{self.blocker.username} blocked {self.blocked_user.username}"


class Report(models.Model):
    # Motive prestabilite din care utilizatorul poate alege
    REASON_CHOICES = [
        ('spam', 'Spam sau reclame'),
        ('inappropriate', 'Limbaj sau conținut inadecvat'),
        ('fake', 'Profil fals'),
        ('other', 'Alt motiv'),
    ]

    # Cel care face raportarea
    reporter = models.ForeignKey(User, related_name='reports_made', on_delete=models.CASCADE)
    # Cel care este raportat
    reported_user = models.ForeignKey(User, related_name='reports_received', on_delete=models.CASCADE)
    
    # Motivul
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    # Detalii extra (opțional)
    description = models.TextField(blank=True, null=True)
    
    # Când a fost făcut report-ul
    created_at = models.DateTimeField(auto_now_add=True)
    # Să știm dacă adminii au rezolvat problema
    is_resolved = models.BooleanField(default=False)

    def __str__(self):
        return f"Report by {self.reporter.username} against {self.reported_user.username}"