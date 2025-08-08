from rest_framework import serializers
from .models import Branch, Subject, Student, Teacher, AttendanceRecord

# ------------------ Branch ------------------
class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = '__all__'


# ------------------ Subject ------------------
class SubjectSerializer(serializers.ModelSerializer):
    branch_name = serializers.ReadOnlyField(source='branch.name')

    class Meta:
        model = Subject
        fields = ['id', 'name', 'semester', 'year', 'branch', 'branch_name']


# ------------------ Student ------------------
class StudentSerializer(serializers.ModelSerializer):
    branch_name = serializers.ReadOnlyField(source='branch.name')

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
            'created_at',
            'updated_at',
        ]

    def validate_email(self, value):
        if not value.endswith('@college.edu'):
            raise serializers.ValidationError("Email must be a college email.")
        return value


# ------------------ Teacher ------------------
class TeacherSerializer(serializers.ModelSerializer):
    subject_names = serializers.SerializerMethodField()

    class Meta:
        model = Teacher
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'subjects', 'subject_names']

    def get_subject_names(self, obj):
        return [sub.name for sub in obj.subjects.all()]


# ------------------ Attendance Record ------------------
class AttendanceRecordSerializer(serializers.ModelSerializer):
    student = serializers.SlugRelatedField(
        slug_field='reg_no',
        queryset=Student.objects.all()
    )
    student_name = serializers.ReadOnlyField(source='student.name')
    subject_name = serializers.ReadOnlyField(source='subject.name')
    reg_no = serializers.ReadOnlyField(source='student.reg_no')

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
        ]
