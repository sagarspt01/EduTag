from django.db import models
from django.contrib.auth.models import AbstractUser


class Branch(models.Model):
    name = models.CharField(max_length=100, unique=True, null=True, blank=True)

    def __str__(self):
        return self.name or "Unnamed Branch"


class Subject(models.Model):
    name = models.CharField(max_length=100, null=True, blank=True)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name='subjects')
    semester = models.IntegerField(default=1)
    year = models.IntegerField(default=2025)

    def __str__(self):
        return f"{self.name} ({self.branch.name} - Sem {self.semester})"


class Student(models.Model):
    reg_no = models.CharField(max_length=20, primary_key=True)
    name = models.CharField(max_length=100, null=True, blank=True)
    semester = models.IntegerField(default=1)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE)
    email = models.EmailField(unique=True)
    profile_pic = models.ImageField(upload_to='students/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.reg_no})"


class Teacher(AbstractUser):
    subjects = models.ManyToManyField(Subject, blank=True)

    def __str__(self):
        return self.get_full_name() or self.username


class AttendanceRecord(models.Model):
    reg_no = models.CharField(max_length=20,null=True)  # Just store the reg_no as string
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.reg_no} - {self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
