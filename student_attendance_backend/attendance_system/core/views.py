# --------------------- views.py ---------------------
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Branch, Subject, Student, Teacher, AttendanceRecord
from .serializers import *
from .permissions import IsTeacher

class BranchViewSet(viewsets.ModelViewSet):
    queryset = Branch.objects.all()
    serializer_class = BranchSerializer
    permission_classes = [IsTeacher]

class SubjectViewSet(viewsets.ModelViewSet):
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    permission_classes = [IsTeacher]

class StudentViewSet(viewsets.ModelViewSet):
    queryset = Student.objects.all()
    serializer_class = StudentSerializer
    permission_classes = [IsTeacher]

    @action(detail=True, methods=['get'])
    def attendance_summary(self, request, pk=None):
        student = self.get_object()
        total = AttendanceRecord.objects.filter(student=student).count()
        present = AttendanceRecord.objects.filter(student=student, status='present').count()
        percentage = (present / total) * 100 if total else 0
        return Response({'present': present, 'total': total, 'percentage': percentage})

class TeacherViewSet(viewsets.ModelViewSet):
    queryset = Teacher.objects.all()
    serializer_class = TeacherSerializer
    permission_classes = [IsTeacher]

class AttendanceViewSet(viewsets.ModelViewSet):
    queryset = AttendanceRecord.objects.all()
    serializer_class = AttendanceRecordSerializer
    permission_classes = [IsTeacher]

    def get_queryset(self):
        queryset = super().get_queryset()
        subject_id = self.request.query_params.get('subject_id')
        student_id = self.request.query_params.get('student_id')
        date = self.request.query_params.get('date')

        if subject_id:
            queryset = queryset.filter(subject_id=subject_id)
        if student_id:
            queryset = queryset.filter(student_id=student_id)
        if date:
            queryset = queryset.filter(timestamp__date=date)

        return queryset
