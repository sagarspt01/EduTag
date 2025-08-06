import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';
import 'views/students/student_list_page.dart';
import 'views/students/student_analysis_page.dart';

import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/attendance_provider.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Attendance System',
        initialRoute: AppRoutes.initial,
        routes: {
          AppRoutes.initial: (context) => const AuthWrapper(),
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.home: (context) => const HomePage(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.studentList:
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return MaterialPageRoute(
                  builder: (context) => StudentListPage(
                    branch: args['branch'],
                    semester: args['semester'],
                    subject: args['subject'],
                  ),
                );
              }
              return _errorRoute();
            case AppRoutes.studentAnalysis:
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args['student'] != null) {
                return MaterialPageRoute(
                  builder: (context) => StudentAnalysisPage(
                    // student: args['student'],
                  ),
                );
              }
              return _errorRoute();
            default:
              return null;
          }
        },
      ),
    );
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Page not found or missing arguments')),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return authProvider.isAuthenticated
            ? const HomePage()
            : const LoginPage();
      },
    );
  }
}
