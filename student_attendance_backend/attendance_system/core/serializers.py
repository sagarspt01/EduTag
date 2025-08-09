from rest_framework import serializers
from django.conf import settings
from .models import Branch, Subject, Student, Teacher, AttendanceRecord


# ------------------ Branch Serializer ------------------
class BranchSerializer(serializers.ModelSerializer):
    """Serializer for the Branch model."""

    class Meta:
        model = Branch
        fields = '__all__'


# ------------------ Subject Serializer ------------------
class SubjectSerializer(serializers.ModelSerializer):
    """Serializer for the Subject model, including branch name."""
    branch_name = serializers.ReadOnlyField(source='branch.name')

    class Meta:
        model = Subject
        fields = ['id', 'name', 'semester', 'year', 'branch', 'branch_name']


# ------------------ Student Serializer ------------------
class StudentSerializer(serializers.ModelSerializer):
    """Serializer for the Student model with profile picture URL."""
    branch_name = serializers.ReadOnlyField(source='branch.name')
    profile_pic_url = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = [
            'reg_no',
            'name',
            'semester',
            'branch',
            'branch_name',
            'email',
            'profile_pic',
            'profile_pic_url',
            'created_at',
            'updated_at',
        ]

    def validate_email(self, value):
        """Ensure student email is a valid college email."""
        if not value.endswith('@college.edu'):
            raise serializers.ValidationError("Email must be a college email.")
        return value

    def get_profile_pic_url(self, obj):
        """Return an absolute URL for the student's profile picture."""
        request = self.context.get('request')
        if obj.profile_pic and hasattr(obj.profile_pic, 'url'):
            if request:
                return request.build_absolute_uri(obj.profile_pic.url)
            else:
                # Fallback without request context
                return f"{settings.MEDIA_URL}{obj.profile_pic.name}"
        return None


# ------------------ Teacher Serializer ------------------
class TeacherSerializer(serializers.ModelSerializer):
    """Serializer for the Teacher model with related subject names."""
    subject_names = serializers.SerializerMethodField()

    class Meta:
        model = Teacher
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'subjects',
            'subject_names',
        ]

    def get_subject_names(self, obj):
        """Return a list of subject names assigned to the teacher."""
        return [sub.name for sub in obj.subjects.all()]


# ------------------ Attendance Record Serializer ------------------
class AttendanceRecordSerializer(serializers.ModelSerializer):
    """
    Serializer for AttendanceRecord.
    Uses student registration number as slug.
    Includes student and subject names plus profile picture URL.
    """
    student = serializers.SlugRelatedField(
        slug_field='reg_no',
        queryset=Student.objects.all()
    )
    student_name = serializers.ReadOnlyField(source='student.name')
    subject_name = serializers.ReadOnlyField(source='subject.name')
    reg_no = serializers.ReadOnlyField(source='student.reg_no')
    profile_pic_url = serializers.SerializerMethodField()

    class Meta:
        model = AttendanceRecord
        fields = [
            'id',
            'student',
            'student_name',
            'reg_no',
            'subject',
            'subject_name',
            'status',
            'timestamp',
            'profile_pic_url',
        ]

    def get_profile_pic_url(self, obj):
        """Return an absolute URL for the student's profile picture."""
        request = self.context.get('request')
        if obj.student.profile_pic and hasattr(obj.student.profile_pic, 'url'):
            if request:
                return request.build_absolute_uri(obj.student.profile_pic.url)
            else:
                # Fallback without request context
                return f"{settings.MEDIA_URL}{obj.student.profile_pic.name}"
        return None