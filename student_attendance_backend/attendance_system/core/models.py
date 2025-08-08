from django.db import models
from django.contrib.auth.models import AbstractUser


# ------------------ Branch ------------------
class Branch(models.Model):
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name


# ------------------ Subject ------------------
class Subject(models.Model):
    name = models.CharField(max_length=100)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name='subjects')
    semester = models.PositiveIntegerField(default=1)
    year = models.PositiveIntegerField(default=2025)

    def __str__(self):
        return f"{self.name} ({self.branch.name} - Sem {self.semester})"


# ------------------ Student ------------------
class Student(models.Model):
    reg_no = models.CharField(max_length=20, unique=True)
    name = models.CharField(max_length=100)
    semester = models.PositiveIntegerField(default=1)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name='students')
    email = models.EmailField(unique=True)
    profile_pic = models.ImageField(upload_to='students/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.reg_no})"


# ------------------ Teacher (custom user) ------------------
class Teacher(AbstractUser):
    subjects = models.ManyToManyField(Subject, blank=True, related_name='teachers')

    def __str__(self):
        return self.get_full_name() or self.username


# ------------------ Attendance Record ------------------
class AttendanceRecord(models.Model):
    STATUS_CHOICES = [
        ('P', 'Present'),
        ('A', 'Absent'),
    ]

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='attendance_records')
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE, related_name='attendance_records')
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default='A')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        constraints = [
            models.UniqueConstraint(fields=['student', 'subject', 'timestamp'], name='unique_attendance_entry')
        ]

    def __str__(self):
        return f"{self.student.reg_no} - {self.subject.name} - {self.get_status_display()} on {self.timestamp.strftime('%Y-%m-%d')}"
