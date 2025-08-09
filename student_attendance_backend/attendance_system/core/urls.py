from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    BranchViewSet,
    SubjectViewSet,
    StudentViewSet,
    TeacherViewSet,
    AttendanceViewSet,
)

# Router to automatically handle CRUD URLs for ViewSets
router = DefaultRouter()
router.register(r'branches', BranchViewSet, basename='branch')
router.register(r'subjects', SubjectViewSet, basename='subject')
router.register(r'students', StudentViewSet, basename='student')
router.register(r'teachers', TeacherViewSet, basename='teacher')
router.register(r'attendance', AttendanceViewSet, basename='attendance')

# API URL patterns
urlpatterns = [
    path('', include(router.urls)),
]
