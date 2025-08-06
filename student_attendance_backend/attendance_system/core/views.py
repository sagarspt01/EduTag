from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

from .models import Branch, Subject, Student, Teacher, AttendanceRecord
from .serializers import (
    BranchSerializer,
    SubjectSerializer,
    StudentSerializer,
    TeacherSerializer,
    AttendanceRecordSerializer,
)
from .permissions import IsTeacher


class BranchViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View to list all branches.
    """
    queryset = Branch.objects.all().order_by('name')
    serializer_class = BranchSerializer
    permission_classes = [IsTeacher]


class SubjectViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View to list all subjects, filtered by branch and semester.
    Example: /api/subjects/?branch=1 or /api/subjects/?branch=1&semester=3
    """
    queryset = Subject.objects.all().order_by('name')
    serializer_class = SubjectSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['branch', 'semester']


class StudentViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View to list students filtered by branch and semester.
    Includes a sub-route for attendance summary.
    """
    queryset = Student.objects.all().order_by('name')
    serializer_class = StudentSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['branch', 'semester']

    @action(detail=True, methods=['get'])
    def attendance_summary(self, request, pk=None):
        """
        Returns the attendance summary for a specific student.
        """
        student = self.get_object()
        total = AttendanceRecord.objects.filter(student=student).count()
        present = AttendanceRecord.objects.filter(student=student, status='present').count()
        percentage = (present / total) * 100 if total else 0
        return Response({
            'present': present,
            'total': total,
            'percentage': round(percentage, 2),
        })


class TeacherViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View to list all teachers.
    """
    queryset = Teacher.objects.all().order_by('id')
    serializer_class = TeacherSerializer
    permission_classes = [IsTeacher]


class AttendanceViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View to list attendance records.
    Supports filtering by subject, student, and optional date.
    """
    queryset = AttendanceRecord.objects.all().order_by('-timestamp')
    serializer_class = AttendanceRecordSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['subject', 'student']

    def get_queryset(self):
        queryset = super().get_queryset()
        date = self.request.query_params.get('date')
        if date:
            queryset = queryset.filter(timestamp__date=date)
        return queryset
