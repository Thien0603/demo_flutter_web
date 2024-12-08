import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isOtpSent = false;
  bool _isLoading = false;

  Future<void> _validateAndSendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (newPassword != confirmPassword) {
        throw Exception("Mật khẩu mới không khớp!");
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Không tìm thấy người dùng.");
      }

      // Reauthenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Gửi OTP
      final phoneNumber = user.phoneNumber;
      if (phoneNumber == null) {
        throw Exception("Không tìm thấy số điện thoại liên kết với tài khoản.");
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception("Gửi OTP thất bại: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP đã được gửi!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final otp = _otpController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      if (_verificationId == null) {
        throw Exception("Không tìm thấy mã OTP.");
      }

      // Verify OTP
      final otpCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(otpCredential);

      // Update password
      final user = FirebaseAuth.instance.currentUser;
      await user?.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu đã được thay đổi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thay Đổi Mật Khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isOtpSent) ...[
              TextField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: 'Mật Khẩu Hiện Tại'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Mật Khẩu Mới'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Xác Nhận Mật Khẩu Mới'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _validateAndSendOtp,
                child: const Text("Xác Nhận"),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'OTP'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _changePassword,
                child: const Text("Đổi Mật Khẩu"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}