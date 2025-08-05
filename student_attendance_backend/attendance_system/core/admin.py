from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import *

@admin.register(Teacher)
class TeacherAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('subjects',)}),
    )

admin.site.register(Branch)
admin.site.register(Subject)
admin.site.register(Student)
admin.site.register(AttendanceRecord)
