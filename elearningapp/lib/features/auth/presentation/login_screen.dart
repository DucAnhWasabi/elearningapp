import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../home/presentation/instructor_dashboard.dart';
import '../../home/presentation/student_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = await _authService.signIn(
        _emailController.text,
        _passController.text,
      );

      if (!mounted) return;

      // Login thành công!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xin chào ${userModel.role}: ${userModel.displayName ?? 'User'}")),
      );

      // Điều hướng dựa trên Role
      if (userModel.isInstructor) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => InstructorDashboard(user: userModel))
        );
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentHome(user: userModel))
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "IT E-LEARNING",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email hoặc Mã số (admin)",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Lưu ý: Giảng viên sử dụng tài khoản admin/admin",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}