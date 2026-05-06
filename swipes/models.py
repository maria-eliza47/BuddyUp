from django.db import models
from django.contrib.auth.models import User

class Swipe(models.Model):
    TYPES = (('LIKE', 'Like'), ('PASS', 'Pass'))
    swiper = models.ForeignKey(User, on_delete=models.CASCADE, related_name='swipes_sent')
    swiped_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='swipes_received')
    swipe_type = models.CharField(max_length=10, choices=TYPES)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.swiper} -> {self.swipe_type} -> {self.swiped_user}"