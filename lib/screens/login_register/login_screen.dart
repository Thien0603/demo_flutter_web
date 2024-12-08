import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_page/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId; // Lưu mã xác minh OTP
  bool _otpRequired = true; // Yêu cầu OTP
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFillEmail();
  }

  // Hàm tự động điền email từ SharedPreferences hoặc tài khoản cũ
  Future<void> _autoFillEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('savedEmail'); // Lấy email đã lưu từ SharedPreferences

    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Bắt đầu loading
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Đăng nhập bằng email và mật khẩu
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Đăng nhập thất bại. Vui lòng thử lại!");
      }

      // Lưu email vào SharedPreferences để tự động điền khi đăng nhập lại
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('savedEmail', email);

      // Lấy trạng thái OTP từ Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _otpRequired = doc.data()?['otpEnabled'] ?? true;

      if (!_otpRequired) {
        // Bỏ qua OTP nếu không yêu cầu
        _navigateToHome();
        return;
      }

      // Nếu OTP được bật, gửi mã OTP
      await _sendOtp(user.phoneNumber);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Dừng loading
      });
    }
  }

  // Gửi OTP đến số điện thoại
  Future<void> _sendOtp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception("Số điện thoại không hợp lệ.");
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Xác minh thành công
        await FirebaseAuth.instance.signInWithCredential(credential);
        _navigateToHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception("Xác thực OTP thất bại: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP đã được gửi!")),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // Xác minh OTP
  Future<void> _verifyOtp() async {
    try {
      final otp = _otpController.text.trim();
      if (_verificationId == null || otp.isEmpty) {
        throw Exception("Vui lòng nhập OTP hợp lệ.");
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi OTP: ${e.toString()}")),
      );
    }
  }

  // Chuyển hướng đến HomeScreen sau khi hoàn tất
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center( // Căn giữa container
        child: Container(
          margin: EdgeInsets.only(top: 20),
          width: 900,
          decoration: BoxDecoration(
            color: Colors.white,  // Màu nền trắng
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,  // Màu chữ đen
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Welcome to Gmail!',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,  // Màu chữ đen
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.black54),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.black54),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (_otpRequired && _verificationId != null)
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'Input OTP',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.sms, color: Colors.black54),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  // Row chứa các nút Login và Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.grey,
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _otpRequired && _verificationId == null
                            ? _login
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Text(
                          _otpRequired && _verificationId == null
                              ? 'Login'
                              : 'Verify OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








