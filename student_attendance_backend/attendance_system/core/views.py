from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from django.db.models import Q

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
    queryset = Branch.objects.all().order_by('name')
    serializer_class = BranchSerializer
    permission_classes = [IsTeacher]


class SubjectViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Subject.objects.all().order_by('name')
    serializer_class = SubjectSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['branch', 'semester']


class StudentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Student.objects.all().order_by('name')
    serializer_class = StudentSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['branch', 'semester']

    @action(detail=True, methods=['get'])
    def attendance_summary(self, request, pk=None):
        student = self.get_object()
        total = AttendanceRecord.objects.filter(student=student).count()
        present = AttendanceRecord.objects.filter(student=student, status='present').count()
        percentage = (present / total) * 100 if total else 0
        return Response({
            'present': present,
            'total': total,
            'percentage': round(percentage, 2),
        })

    @action(detail=True, methods=['get'], url_path='same-batch-students')
    def same_batch_students(self, request, pk=None):
        student = self.get_object()
        same_batch = Student.objects.filter(
            branch=student.branch,
            semester=student.semester
        ).exclude(id=student.id).order_by('name')
        serializer = self.get_serializer(same_batch, many=True)
        return Response(serializer.data)


class TeacherViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Teacher.objects.all().order_by('id')
    serializer_class = TeacherSerializer
    permission_classes = [IsTeacher]


class AttendanceViewSet(viewsets.ModelViewSet):
    queryset = AttendanceRecord.objects.all().order_by('-timestamp')
    serializer_class = AttendanceRecordSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['subject', 'student__reg_no']

    def get_queryset(self):
        queryset = super().get_queryset()
        date = self.request.query_params.get('date')
        if date:
            queryset = queryset.filter(timestamp__date=date)
        return queryset

    @action(detail=False, methods=['post'], url_path='toggle')
    def toggle_attendance(self, request):
        reg_no = request.data.get("reg_no")
        subject_id = request.data.get("subject_id")

        if not reg_no or not subject_id:
            return Response(
                {"error": "reg_no and subject_id are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            student = Student.objects.get(reg_no=reg_no)
        except Student.DoesNotExist:
            return Response({"error": "Student not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            subject = Subject.objects.get(pk=subject_id)
        except Subject.DoesNotExist:
            return Response({"error": "Subject not found."}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()

        existing = AttendanceRecord.objects.filter(
            student=student,
            subject=subject,
            timestamp__date=today
        ).first()

        if existing:
            existing.delete()
            return Response({"message": "Attendance removed (marked absent)."}, status=status.HTTP_200_OK)

        record = AttendanceRecord.objects.create(
            student=student,
            subject=subject,
            status='present',
            timestamp=timezone.now()
        )
        serializer = self.get_serializer(record)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='bulk')
    def bulk_create(self, request):
        serializer = AttendanceRecordSerializer(data=request.data, many=True)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "Attendance records saved."},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['put'], url_path='update')
    def update_attendance(self, request):
        reg_no = request.data.get("reg_no")
        subject_id = request.data.get("subject_id")
        status_val = request.data.get("status")
        timestamp = request.data.get("timestamp")

        if not (reg_no and subject_id and status_val and timestamp):
            return Response({"error": "All fields are required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            student = Student.objects.get(reg_no=reg_no)
            subject = Subject.objects.get(pk=subject_id)
        except (Student.DoesNotExist, Subject.DoesNotExist):
            return Response({"error": "Student or Subject not found."}, status=status.HTTP_404_NOT_FOUND)

        record = AttendanceRecord.objects.filter(
            student=student,
            subject=subject,
            timestamp=timestamp
        ).first()

        if not record:
            return Response({"error": "Attendance record not found."}, status=status.HTTP_404_NOT_FOUND)

        record.status = status_val
        record.save()
        serializer = self.get_serializer(record)
        return Response(serializer.data, status=status.HTTP_200_OK)
