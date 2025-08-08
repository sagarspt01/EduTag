from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Branch, Subject, Student, Teacher, AttendanceRecord


@admin.register(Teacher)
class TeacherAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ("Additional Info", {"fields": ("subjects",)}),
    )
    filter_horizontal = ("subjects",)


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ("reg_no", "name", "branch", "semester", "email")
    search_fields = ("reg_no", "name", "email")
    list_filter = ("branch", "semester")
    ordering = ("reg_no",)


@admin.register(AttendanceRecord)
class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ("student", "subject", "status", "timestamp")
    search_fields = ("student__reg_no", "subject__name")
    list_filter = ("subject__branch", "subject__semester", "timestamp", "status")
    ordering = ("-timestamp",)


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ("name", "branch", "semester", "year")
    list_filter = ("branch", "semester", "year")
    search_fields = ("name",)
