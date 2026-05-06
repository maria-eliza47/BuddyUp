from django.db import models
from django.contrib.auth.models import User

class Match(models.Model):
    user1 = models.ForeignKey(User, on_delete=models.CASCADE, related_name='match_set1')
    user2 = models.ForeignKey(User, on_delete=models.CASCADE, related_name='match_set2')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Match: {self.user1} & {self.user2}"