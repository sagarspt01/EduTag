from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404

from .models import Branch, Subject, Student, Teacher, AttendanceRecord
from .serializers import (
    BranchSerializer,
    SubjectSerializer,
    StudentSerializer,
    TeacherSerializer,
    AttendanceRecordSerializer,
)
from .permissions import IsTeacher


# ---------------- Branch ----------------
class BranchViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Branch.objects.all().order_by('name')
    serializer_class = BranchSerializer
    permission_classes = [IsTeacher]


# ---------------- Subject ----------------
class SubjectViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Subject.objects.all().order_by('name')
    serializer_class = SubjectSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['branch', 'semester']


# ---------------- Student ----------------
class StudentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Student.objects.all().order_by('name')
    serializer_class = StudentSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['branch', 'semester', 'reg_no']  # Added reg_no for filtering
    lookup_field = 'reg_no'

    def get_queryset(self):
        """Override to handle reg_no filtering properly"""
        queryset = super().get_queryset()
        
        # Handle reg_no query parameter specifically
        reg_no = self.request.query_params.get('reg_no')
        if reg_no:
            # Filter by exact registration number match
            queryset = queryset.filter(reg_no=reg_no)
        
        return queryset

    def list(self, request, *args, **kwargs):
        """Override list to ensure proper reg_no filtering"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # If reg_no is provided, ensure we return only that specific student
        reg_no = request.query_params.get('reg_no')
        if reg_no:
            queryset = queryset.filter(reg_no=reg_no)
            if not queryset.exists():
                return Response(
                    {'detail': f'Student with registration number {reg_no} not found.'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to handle reg_no lookup properly"""
        reg_no = kwargs.get('reg_no')
        if reg_no:
            student = get_object_or_404(Student, reg_no=reg_no)
            serializer = self.get_serializer(student)
            return Response(serializer.data)
        return super().retrieve(request, *args, **kwargs)

    @action(detail=True, methods=['get'])
    def attendance_summary(self, request, reg_no=None):
        """Get attendance summary for a specific student by reg_no"""
        student = get_object_or_404(Student, reg_no=reg_no)
        
        # Get subject filter if provided
        subject_id = request.query_params.get('subject')
        attendance_filter = {'student': student}
        
        if subject_id:
            attendance_filter['subject_id'] = subject_id
        
        total = AttendanceRecord.objects.filter(**attendance_filter).count()
        present = AttendanceRecord.objects.filter(**attendance_filter, status='P').count()
        absent = total - present
        percentage = (present / total) * 100 if total else 0

        return Response({
            'student_name': student.name,
            'reg_no': student.reg_no,
            'present': present,
            'absent': absent,
            'total': total,
            'percentage': round(percentage, 2),
        })

    @action(detail=True, methods=['get'], url_path='same-batch-students')
    def same_batch_students(self, request, reg_no=None):
        """Get students from same batch as the specified student"""
        student = get_object_or_404(Student, reg_no=reg_no)
        same_batch = Student.objects.filter(
            branch=student.branch,
            semester=student.semester
        ).exclude(reg_no=student.reg_no).order_by('name')

        serializer = self.get_serializer(same_batch, many=True)
        return Response(serializer.data)


# ---------------- Teacher ----------------
class TeacherViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Teacher.objects.all().order_by('id')
    serializer_class = TeacherSerializer
    permission_classes = [IsTeacher]


# ---------------- Attendance ----------------
class AttendanceViewSet(viewsets.ModelViewSet):
    queryset = AttendanceRecord.objects.all().order_by('-timestamp')
    serializer_class = AttendanceRecordSerializer
    permission_classes = [IsTeacher]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['subject', 'student__reg_no', 'status']

    def get_queryset(self):
        """Enhanced queryset filtering"""
        queryset = super().get_queryset()
        
        # Handle date filtering
        date = self.request.query_params.get('date')
        if date:
            queryset = queryset.filter(timestamp__date=date)
        
        # Handle reg_no filtering specifically
        reg_no = self.request.query_params.get('reg_no')
        if reg_no:
            queryset = queryset.filter(student__reg_no=reg_no)
        
        # Handle subject filtering
        subject = self.request.query_params.get('subject')
        if subject:
            queryset = queryset.filter(subject_id=subject)
            
        return queryset

    @action(detail=False, methods=['get'], url_path='student-summary')
    def student_summary(self, request):
        """Get attendance summary for a specific student and subject"""
        reg_no = request.query_params.get('reg_no')
        subject_id = request.query_params.get('subject')
        
        if not reg_no:
            return Response(
                {'error': 'reg_no parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get the student
        student = get_object_or_404(Student, reg_no=reg_no)
        
        # Build attendance query
        attendance_filter = {'student': student}
        if subject_id:
            attendance_filter['subject_id'] = subject_id
        
        # Get attendance records
        records = AttendanceRecord.objects.filter(**attendance_filter)
        total = records.count()
        present = records.filter(status='P').count()
        absent = total - present
        percentage = (present / total) * 100 if total else 0
        
        # Serialize student data
        student_serializer = StudentSerializer(student, context={'request': request})
        
        return Response({
            'student': student_serializer.data,
            'attendance_summary': {
                'total': total,
                'present': present,
                'absent': absent,
                'percentage': round(percentage, 2)
            }
        })

    @action(detail=False, methods=['post'], url_path='toggle')
    def toggle_attendance(self, request):
        """Toggle attendance for a student on current date"""
        reg_no = request.data.get("reg_no")
        subject_id = request.data.get("subject_id")

        if not reg_no or not subject_id:
            return Response(
                {"error": "reg_no and subject_id are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        student = get_object_or_404(Student, reg_no=reg_no)
        subject = get_object_or_404(Subject, pk=subject_id)

        today = timezone.now().date()
        existing = AttendanceRecord.objects.filter(
            student=student,
            subject=subject,
            timestamp__date=today
        ).first()

        if existing:
            existing.delete()
            return Response(
                {
                    "message": "Attendance removed (marked absent).",
                    "student_name": student.name,
                    "reg_no": student.reg_no
                },
                status=status.HTTP_200_OK
            )

        record = AttendanceRecord.objects.create(
            student=student,
            subject=subject,
            status='P',  # Present
            timestamp=timezone.now()
        )
        serializer = self.get_serializer(record)
        return Response({
            "message": "Attendance marked present.",
            "record": serializer.data
        }, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='bulk')
    def bulk_create(self, request):
        """Bulk create attendance records"""
        if not isinstance(request.data, list):
            return Response(
                {"error": "Expected a list of attendance records."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        serializer = AttendanceRecordSerializer(
            data=request.data, 
            many=True,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(
                {
                    "message": f"{len(serializer.data)} attendance records saved.",
                    "records": serializer.data
                },
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['put'], url_path='update')
    def update_attendance(self, request):
        """Update existing attendance record"""
        reg_no = request.data.get("reg_no")
        subject_id = request.data.get("subject_id")
        status_val = request.data.get("status")
        timestamp = request.data.get("timestamp")

        if not all([reg_no, subject_id, status_val, timestamp]):
            return Response(
                {"error": "reg_no, subject_id, status, and timestamp are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        student = get_object_or_404(Student, reg_no=reg_no)
        subject = get_object_or_404(Subject, pk=subject_id)

        record = AttendanceRecord.objects.filter(
            student=student,
            subject=subject,
            timestamp=timestamp
        ).first()

        if not record:
            return Response(
                {"error": "Attendance record not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        record.status = status_val
        record.save()
        
        serializer = self.get_serializer(record)
        return Response({
            "message": "Attendance record updated successfully.",
            "record": serializer.data
        }, status=status.HTTP_200_OK)