import 'dart:io' as io;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditUserInfoScreen extends StatefulWidget {
  const EditUserInfoScreen({Key? key}) : super(key: key);

  @override
  State<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  dynamic _image; // File ảnh đại diện mới
  String? _photoUrl;
  bool _isOtpEnabled = false; // Trạng thái bật/tắt OTP
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
        throw Exception("Không tìm thấy người dùng.");
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _nameController.text = data?['name'] ?? '';
        _bioController.text = data?['bio'] ?? '';
        _emailController.text = user.email ?? '';
        _photoUrl = data?['photoUrl']?? '';
        _isOtpEnabled = data?['otpEnabled'] ?? true;
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

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Trường hợp Web: Chọn file từ máy tính
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files!.first;
        setState(() {
          _image = file; // Lưu file HTML
          _photoUrl = html.Url.createObjectUrlFromBlob(_image);
        });
      });
    } else {
      // Trường hợp Mobile: Chọn file từ thư viện
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = io.File(pickedFile.path); // Lưu file Dart IO
          _photoUrl = pickedFile.path;
        });
      }
    }
  }





  Future<void> _updateUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Không tìm thấy người dùng.");
      }
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${user.uid}.jpg');

      if (kIsWeb) {
        // Trường hợp Web: Sử dụng putBlob
        await ref.putBlob(_image as html.File);
      } else {
        // Trường hợp Mobile: Sử dụng putFile
        await ref.putFile(_image as io.File);
      }

      final downloadUrl = await ref.getDownloadURL();
      setState(() {
        _photoUrl = downloadUrl;
      });

      // Cập nhật Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'otpEnabled': _isOtpEnabled,
      });

      // Cập nhật email
      await user.updateEmail(_emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công!")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sửa Thông Tin Người Dùng")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                      radius: 50,
                      backgroundImage: _photoUrl != null
                          ? (kIsWeb
                          ? NetworkImage(_photoUrl!) // Web: Hiển thị ảnh từ URL
                          : FileImage(io.File(_photoUrl!)) as ImageProvider)
                          : const AssetImage('assets/placeholder.png') // Fallback placeholder
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Bật OTP Khi Đăng Nhập"),
              value: _isOtpEnabled,
              onChanged: (value) {
                setState(() {
                  _isOtpEnabled = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUserInfo,
              child: const Text("Cập Nhật"),
            ),
          ],
        ),
      ),
    );
  }
}