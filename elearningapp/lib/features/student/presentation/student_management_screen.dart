import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/user_model.dart';
import '../../auth/data/auth_service.dart';
import '../data/student_csv_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentCsvService _csvService = StudentCsvService();
  final AuthService _authService = AuthService();

  // State cho Import
  List<CsvImportResult> _previewData = [];
  bool _isAnalyzing = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- LOGIC IMPORT ---
  void _pickAndAnalyzeCsv() async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await _csvService.pickCsvFile();
      if (result != null) {
        // Lấy bytes (Platform independent)
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final results = await _csvService.processCsvData(bytes);
          setState(() => _previewData = results);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đọc file: $e")));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _executeImport() async {
    // Lọc ra user hợp lệ
    final validUsers = _previewData
        .where((item) => !item.isDuplicate)
        .map((item) => item.user)
        .toList();

    if (validUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không có dữ liệu mới để nhập!")));
      return;
    }

    setState(() => _isImporting = true);
    try {
      await _authService.createStudentBatch(validUsers);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã nhập thành công ${validUsers.length} sinh viên!")));
      setState(() => _previewData = []); // Reset
      _tabController.animateTo(0); // Quay về tab danh sách
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi nhập liệu: $e")));
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Sinh viên"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "Danh sách"),
            Tab(icon: Icon(Icons.upload_file), text: "Nhập CSV"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentList(),
          _buildCsvImportView(),
        ],
      ),
    );
  }

  // --- TAB 1: DANH SÁCH ---
  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collUsers)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .orderBy('createdAt', descending: true) // Cần tạo index trong Firestore sau này
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Chưa có sinh viên nào."));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(child: Text(data['displayName']?[0] ?? "S")),
              title: Text(data['displayName'] ?? "No Name"),
              subtitle: Text(data['email'] ?? ""),
              trailing: const Icon(Icons.more_vert),
            );
          },
        );
      },
    );
  }

  // --- TAB 2: IMPORT VIEW (QUAN TRỌNG) ---
  Widget _buildCsvImportView() {
    return Column(
      children: [
        // Hướng dẫn & Nút chọn file
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Yêu cầu file CSV:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Cột 1: Mã SV | Cột 2: Họ tên | Cột 3: Email", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _pickAndAnalyzeCsv,
                icon: _isAnalyzing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.folder_open),
                label: const Text("Chọn File"),
              ),
            ],
          ),
        ),

        // Bảng Preview
        Expanded(
          child: _previewData.isEmpty
              ? const Center(child: Text("Vui lòng chọn file CSV để xem trước."))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Mã SV')),
                  DataColumn(label: Text('Họ Tên')),
                  DataColumn(label: Text('Email')),
                ],
                rows: _previewData.map((item) {
                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>((states) {
                      return item.isDuplicate ? Colors.grey[200] : Colors.green[50];
                    }),
                    cells: [
                      DataCell(
                          Row(
                            children: [
                              Icon(
                                item.isDuplicate ? Icons.warning : Icons.check_circle,
                                color: item.isDuplicate ? Colors.orange : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.statusMessage,
                                style: TextStyle(
                                    color: item.isDuplicate ? Colors.orange[800] : Colors.green[800],
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          )
                      ),
                      DataCell(Text(item.user.studentCode ?? "")),
                      DataCell(Text(item.user.displayName ?? "")),
                      DataCell(Text(item.user.email)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Footer Action
        if (_previewData.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sẽ nhập: ${_previewData.where((e) => !e.isDuplicate).length} sinh viên"),
                ElevatedButton(
                  onPressed: _isImporting ? null : _executeImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isImporting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("XÁC NHẬN NHẬP"),
                ),
              ],
            ),
          )
      ],
    );
  }
}