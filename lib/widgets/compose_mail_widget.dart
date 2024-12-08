import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ComposeMail extends StatefulWidget {
  final VoidCallback onClose;
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;
  final Function(Map<String, dynamic> email) onEmailSent;
  final bool isDraft;
  final String? draftId;

  const ComposeMail({
    Key? key,
    required this.onClose,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
    required this.onEmailSent,
    this.isDraft = false,
    this.draftId,
  }) : super(key: key);

  @override
  State<ComposeMail> createState() => _ComposeMailState();
}

class _ComposeMailState extends State<ComposeMail> {
  final FocusNode _toFocusNode = FocusNode();
  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  late TextEditingController _toController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  bool _isMinimized = false;
  bool isDraftInProgress = false;
  List<PlatformFile> _attachments = [];
  String displaySubject = 'New Message';
  String? _draftId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialTo ?? "")
      ..addListener(draftEmail);
    _subjectController = TextEditingController(text: widget.initialSubject ?? "")
      ..addListener(draftEmail);
    _bodyController = TextEditingController(text: widget.initialBody ?? "")
      ..addListener(draftEmail);

    if (widget.draftId != null) {
      _draftId = widget.draftId;
      loadDraft();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _toFocusNode.dispose();
    _subjectFocusNode.dispose();
    _bodyFocusNode.dispose();
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  void loadDraft() async {
    try {
      String email = FirebaseAuth.instance.currentUser?.email ?? '';
      if (_draftId == null || email.isEmpty) return;

      var snapshot = await FirebaseFirestore.instance
          .collection('drafts')
          .doc(email)
          .collection('userDrafts')
          .doc(_draftId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data()!;
        setState(() {
          _toController.text = data['to'] ?? '';
          _subjectController.text = data['subject'] ?? '';
          _bodyController.text = data['body'] ?? '';
          _attachments = data['attachments'] != null
              ? List<PlatformFile>.from((data['attachments'] as List).map((e) => PlatformFile(name: e, size: 20)))
              : [];
          displaySubject = data['subject'] ?? 'New Message';
        });
      } else {
        print('Draft not found');
      }
    } catch (e) {
      print('Error loading draft: $e');
    }
  }

  void draftEmail() async {
    if (isDraftInProgress) return;

    String email = FirebaseAuth.instance.currentUser?.email ?? '';
    String to = _toController.text.trim();
    String subject = _subjectController.text.trim();
    String body = _bodyController.text.trim();

    if (to.isEmpty && subject.isEmpty && body.isEmpty && _attachments.isEmpty) {
      return;
    }

    setState(() {
      isDraftInProgress = true;
    });

    try {
      if (_draftId == null) {
        // Tạo mới thư nháp nếu chưa có _draftId
        String draftId = FirebaseFirestore.instance.collection('drafts').doc().id;

        final draftData = {
          "draftId": draftId,
          "to": to.isNotEmpty ? to : "",
          "subject": subject.isNotEmpty ? subject : "",
          "body": body.isNotEmpty ? body : "",
          "attachments": _attachments.map((e) => e.name).toList(),
          "timestamp": DateTime.now().toIso8601String(),
          "isStarred": false,
          "isDeleted": false,
          "emailType": "draft",
        };

        await FirebaseFirestore.instance
            .collection('drafts')
            .doc(email)
            .collection('userDrafts')
            .doc(draftId)
            .set(draftData, SetOptions(merge: true));

        setState(() {
          _draftId = draftId;  // Cập nhật _draftId sau khi tạo thư nháp
          displaySubject = subject.isNotEmpty ? subject : 'New Message';
        });

        print("Draft created successfully: $draftData");
      } else {
        // Cập nhật thư nháp nếu _draftId đã có
        String draftId = _draftId!;
        final draftData = {
          "fromName": 'Drafts',
          "to": to.isNotEmpty ? to : "",
          "subject": subject.isNotEmpty ? subject : "",
          "body": body.isNotEmpty ? body : "",
          "attachments": _attachments.map((e) => e.name).toList(),
          "timestamp": DateTime.now().toIso8601String(),
        };

        await FirebaseFirestore.instance
            .collection('drafts')
            .doc(email)
            .collection('userDrafts')
            .doc(draftId)
            .set(draftData, SetOptions(merge: true));

        setState(() {
          displaySubject = subject.isNotEmpty ? subject : 'New Message';
        });

        print("Draft updated successfully: $draftData");
      }

      setState(() {
        displaySubject = 'Draft Saved';
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          displaySubject = subject.isNotEmpty ? subject : 'New Message';
        });
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving draft: $error")),
      );
    } finally {
      setState(() {
        isDraftInProgress = false;
      });
    }
  }

  void sendEmail() async {
    String from = FirebaseAuth.instance.currentUser?.email ?? '';
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    String subject = _subjectController.text.trim();
    String body = _bodyController.text.trim();
    String toEmail = _toController.text.trim();

    if (from.isEmpty || subject.isEmpty || body.isEmpty || toEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    if (toEmail == from) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can not send email to yourself!")),
      );
      return;
    }

    // Kiểm tra email có tồn tại trong Firebase
    final QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: toEmail)
        .get();

    if (userQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email do not exist!")),
      );
      return;
    }

    // Thực hiện gửi email nếu tất cả kiểm tra đều hợp lệ
    try {
      // Lấy thông tin người dùng
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User data not found!")),
        );
        return;
      }

      String displayName = userDoc['name'] ?? 'Unknown';
      String emailId = FirebaseFirestore.instance.collection('emails').doc().id;

      List<Map<String, dynamic>> attachmentsData = [];
      List<String> fileNames = [];

      // Tải tệp đính kèm
      for (PlatformFile file in _attachments) {
        String downloadUrl = await _uploadFile(file);
        if (downloadUrl.isNotEmpty) {
          attachmentsData.add({"fileUrl": downloadUrl});
          fileNames.add(file.name);
        }
      }

      final emailData = {
        "emailId": emailId,
        "to": toEmail,
        "from": from,
        "fromName": displayName,
        "subject": subject,
        "body": body,
        "timestamp": DateTime.now().toIso8601String(),
        "status": "unread",
        "attachments": attachmentsData,
        "fileNames": fileNames,
        "isReplied": false,
        "isStarred": false,
        "isDeleted": false,
        "emailType": "inbox",
      };

      final sentData = {
        "emailId": emailId,
        "to": toEmail,
        "from": from,
        "fromName": displayName,
        "subject": subject,
        "body": body,
        "timestamp": DateTime.now().toIso8601String(),
        "status": "unread",
        "attachments": attachmentsData,
        "fileNames": fileNames,
        "isReplied": false,
        "isStarred": false,
        "isDeleted": false,
        "emailType": "sent",
      };

      await FirebaseFirestore.instance
          .collection('emails')
          .doc(toEmail)
          .collection('userEmails')
          .doc(emailId)
          .set(emailData);

      await FirebaseFirestore.instance
          .collection('sents')
          .doc(from)
          .collection('userSentEmails')
          .doc(emailId)
          .set(sentData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email sent successfully!")),
      );

      if (_draftId != null) {
        await FirebaseFirestore.instance
            .collection('drafts')
            .doc(from)
            .collection('userDrafts')
            .doc(_draftId)
            .delete();
      }

      widget.onClose();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending email: $error")),
      );
    }
  }

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });

        for (PlatformFile file in result.files) {
          print("File Name: ${file.name}");
          print("File Size: ${file.size} bytes");

          if (kIsWeb) {
            // Dành cho Web: Sử dụng bytes
            print("File Bytes: ${file.bytes != null ? "Available" : "Not Available"}");
          } else {
            print("File Path: ${file.path}");
          }
        }
      } else {
        print("User canceled the picker");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
    }
  }

  Future<String> _uploadFile(PlatformFile file) async {
    try {
      if (file.bytes != null) {
        // Tạo tham chiếu Firebase Storage
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('emails/attachments/${file.name}');

        // Tải tệp từ bytes
        UploadTask uploadTask = storageRef.putData(file.bytes!);

        // Chờ quá trình tải lên hoàn tất
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        print("File uploaded successfully. Download URL: $downloadUrl");

        // Trả về URL để sử dụng trong email
        return downloadUrl;
      } else {
        print("File bytes are null!");
        return '';
      }
    } catch (e) {
      print("Error uploading file: $e");
      return '';
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return Positioned(
        bottom: 0,
        right: 40,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 400,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Text(
                    displaySubject,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleMinimize,
                      icon: const Icon(Icons.open_in_full, size: 18, color: Colors.black54),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 0,
      right: 40,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 570,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        displaySubject,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleMinimize,
                          icon: const Icon(Icons.remove, size: 20, color: Colors.black54),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.cancel_outlined, size: 20, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              // Form Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // To
                    Row(
                      children: [
                        const Text('To:', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _toController,
                            focusNode: _toFocusNode,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              if (value.trim() == FirebaseAuth.instance.currentUser?.email) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Can not send email to yourself!!")),
                                );
                              }
                            },
                            onEditingComplete: () {
                              _subjectFocusNode.requestFocus();
                              draftEmail(); // Lưu thư nháp
                            },
                            decoration: const InputDecoration(
                              hintText: 'Recipient',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                      ],
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    // Subject
                    TextField(
                      controller: _subjectController,
                      focusNode: _subjectFocusNode,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        _bodyFocusNode.requestFocus();
                        draftEmail();  // Lưu thư nháp khi người dùng nhập xong trường 'Subject'
                      },
                      decoration: const InputDecoration(
                        hintText: 'Subject',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    maxLines: null,
                    expands: true,
                    onEditingComplete: () {
                      draftEmail();  // Lưu thư nháp khi người dùng nhập xong trường 'Body'
                    },
                    decoration: const InputDecoration(
                      hintText: 'Compose your email...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              // Attachments
              // List attachment previews
              if (_attachments.isNotEmpty)
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        child: Container(
                          margin: const EdgeInsets.only(right: 13),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              Text(
                                _attachments[index].name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(width: 15),
                              IconButton(
                                onPressed: () => _removeAttachment(index),
                                icon: const Icon(Icons.cancel_outlined),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: sendEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 18),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: (){},
                      icon: const Icon(Icons.text_format),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file_rounded),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
