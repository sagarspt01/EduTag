from rest_framework import serializers
from .models import Branch, Subject, Student, Teacher, AttendanceRecord

class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = '__all__'

class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = '__all__'

class StudentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Student
        fields = '__all__'

    def validate_email(self, value):
        if not value.endswith('@college.edu'):
            raise serializers.ValidationError("Email must be a college email.")
        return value

class TeacherSerializer(serializers.ModelSerializer):
    class Meta:
        model = Teacher
        fields = ['id', 'username', 'email', 'subjects']

class AttendanceRecordSerializer(serializers.ModelSerializer):
    student_name = serializers.ReadOnlyField(source='student.name')
    reg_no = serializers.ReadOnlyField(source='student.reg_no')
    subject_name = serializers.ReadOnlyField(source='subject.name')

    class Meta:
        model = AttendanceRecord
        fields = ['id', 'student', 'reg_no', 'student_name', 'subject', 'subject_name', 'status', 'timestamp']
