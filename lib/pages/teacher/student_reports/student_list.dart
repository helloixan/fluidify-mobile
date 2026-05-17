import 'package:fluidify_mobile/components/fluidy_circularprogress.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/teacher/student_reports/single_report.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await _supabaseService.getAllStudents();
      final gamifications = await _supabaseService.getAllStudentsGamification();
      if (students != null) {
        for (var student in students) {
          var gamification = gamifications.firstWhere(
            (g) => g['user_id'] == student['id'], 
            orElse: () => <String, dynamic>{}
          );
          student['current_streak'] = gamification['current_streak'] ?? 0;
        }
        students.sort((a, b) => a['display_name']!.compareTo(b['display_name']!));
        setState(() {
          _students = students;
          _filteredStudents = students;
        });
      }
    } catch (e) {
      print('Error fetching students: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getFilterOptions() {
    Set<String> options = {'Semua', 'Tidak Aktif'};
    for (var student in _students) {
      final className = student['classes']?['class_name'];
      if (className != null && className.toString().isNotEmpty) {
        options.add('Kelas: $className');
      }
    }
    return options.toList();
  }

  void _applyFilter() {
    setState(() {
      _filteredStudents = _students.where((student) {
        final name = (student['display_name'] ?? '').toLowerCase();
        final searchQuery = _searchController.text.toLowerCase();
        if (!name.contains(searchQuery)) return false;

        if (_selectedFilter == 'Tidak Aktif') {
          if ((student['current_streak'] ?? 0) != 0) return false;
        } else if (_selectedFilter.startsWith('Kelas: ')) {
          final targetClass = _selectedFilter.replaceFirst('Kelas: ', '');
          final studentClass = student['classes']?['class_name'] ?? '';
          if (studentClass != targetClass) return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Daftar Siswa",
            style: fBoldTextStyle.copyWith(color: regularBlue),
          ),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: regularBlue))
            : _students.isEmpty
                ? const Center(child: Text("Belum ada data siswa"))
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => _applyFilter(),
                            decoration: InputDecoration(
                              hintText: "Cari siswa...",
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: regularBlue),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.filter_list, color: regularBlue, size: 28),
                            tooltip: 'Filter Siswa',
                            color: Colors.white,
                            onSelected: (value) {
                              setState(() {
                                _selectedFilter = value;
                                _applyFilter();
                              });
                            },
                            itemBuilder: (context) {
                              return _getFilterOptions().map((option) {
                                return PopupMenuItem<String>(
                                  value: option,
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontWeight: _selectedFilter == option ? FontWeight.bold : FontWeight.normal,
                                      color: _selectedFilter == option ? regularBlue : Colors.black,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ],),
                    ),
                    if (_filteredStudents.isEmpty)
                      const Expanded(child: Center(child: Text("Siswa tidak ditemukan.")))
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              color: appBackgroundColor,
                              child: ListTile(
                                minTileHeight: 65,
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(student['avatar_url'] ?? dummyAvatarUrl),
                                  backgroundColor: appBackgroundColor,
                                ),
                                title: Text(student['display_name'] ?? "Siswa Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  "Kelas: ${student['classes']?['class_name'] ?? '-'} | Streak: ${student['current_streak'] ?? 0}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SingleStudentReportPage(studentId: student['id']),
                                    ),
                                  ); 
                                }
                              ),
                            );
                          },
                        ),
                      )
                  ]));
  }
}
