import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> loadStudentData() async {
  final jsonString = await rootBundle.loadString(
    'assets/data/student.data.json',
  );

  return jsonDecode(jsonString) as Map<String, dynamic>;
}

Widget buildSummaryCard(
  String value,
  String label,
  IconData icon,
) {
  return Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildCourseItem(Map<String, dynamic> course) {
  final String status = course['status'] as String;

  final bool isDone = status == 'done';
  final bool isActive = status == 'active';

  final IconData statusIcon = isDone
      ? Icons.check_circle
      : isActive
          ? Icons.play_circle
          : Icons.schedule;

  final Color statusColor = isDone
      ? Colors.green
      : isActive
          ? Colors.blue
          : Colors.orange;

  final String statusText = isDone
      ? 'Selesai'
      : isActive
          ? 'Aktif'
          : 'Rencana';

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: Icon(
        statusIcon,
        color: statusColor,
      ),
      title: Text(
        course['title'] as String,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${course['code']} • ${course['credits']} SKS',
      ),
      trailing: Text(
        statusText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    ),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> studentFuture;

  @override
  void initState() {
    super.initState();
    studentFuture = loadStudentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat data:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Data tidak tersedia'),
            );
          }

          final data = snapshot.data!;

          final student =
              data['student'] as Map<String, dynamic>;

          final courses =
              data['courses'] as List<dynamic>;

          final int totalCourses = courses.length;

          final int totalCredits = courses.fold(
            0,
            (total, course) =>
                total + (course['credits'] as int),
          );

          final int completedCourses = courses
              .where(
                (course) => course['status'] == 'done',
              )
              .length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 48,
                            backgroundImage: AssetImage(
                              'assets/images/profile.jpg',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            student['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student['nim'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Semester ${student['semester']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      buildSummaryCard(
                        '$totalCourses',
                        'Total Course',
                        Icons.menu_book,
                      ),
                      buildSummaryCard(
                        '$totalCredits',
                        'Total SKS',
                        Icons.school,
                      ),
                      buildSummaryCard(
                        '$completedCourses',
                        'Selesai',
                        Icons.check_circle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Daftar Mata Kuliah',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$completedCourses dari $totalCourses course selesai',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course =
                          courses[index] as Map<String, dynamic>;

                      return buildCourseItem(course);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learning Dashboard',
      home: const DashboardPage(),
    );
  }
}

void main() {
  runApp(const MyApp());
}