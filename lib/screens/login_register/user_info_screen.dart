import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailappproject/screens/login_register/edit_user_info_screen.dart';
import 'package:emailappproject/screens/login_register/change_password_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key}) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<UserInfoScreen> {
  String? _name;
  String? _bio;
  String? _email;
  String? _phoneNumber;
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Người dùng chưa đăng nhập.");
      }

      // Lấy email và số điện thoại từ FirebaseAuth
      _email = user.email;
      _phoneNumber = user.phoneNumber;

      // Truy vấn thông tin chi tiết từ Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception("Không tìm thấy thông tin người dùng.");
      }

      final data = userDoc.data();
      if (data != null) {
        _name = data['name'];
        _bio = data['bio'];
        _photoUrl = data['photoUrl']; // Ảnh đại diện từ Firebase Storage
      }
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
      appBar: AppBar(title: const Text("Trang Chủ")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị ảnh đại diện
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : const AssetImage('assets/avatar_placeholder.png') as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),

            // Hiển thị thông tin người dùng
            Text(
              "Tên: ${_name ?? 'Chưa cập nhật'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Số Điện Thoại: ${_phoneNumber ?? 'Chưa cập nhật'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Email: ${_email ?? 'Chưa cập nhật'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Bio: ${_bio ?? 'Chưa cập nhật'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Các nút chức năng
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditUserInfoScreen()),
                );
              },
              child: const Text("Sửa Thông Tin Người Dùng"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
              child: const Text("Thay Đổi Mật Khẩu"),
            ),
          ],
        ),
      ),
    );
  }
}