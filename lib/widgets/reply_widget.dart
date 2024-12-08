import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReplyWidget extends StatefulWidget {
  final String from;
  final String fromName;
  final String to;
  final VoidCallback onCancel;
  final String emailId;
  final VoidCallback onSendReply;

  const ReplyWidget({
    Key? key,
    required this.from,
    required this.fromName,
    required this.to,
    required this.onCancel,
    required this.emailId,
    required this.onSendReply,
  }) : super(key: key);

  @override
  State<ReplyWidget> createState() => _ReplyWidgetState();
}

class _ReplyWidgetState extends State<ReplyWidget> {
  late TextEditingController _replyController;

  @override
  void initState() {
    _replyController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  bool isLoading = false;

  Future<void> sendReply({
    required String parentId, // ID của thư gốc hoặc phản hồi trước
    required String replyContent, // Nội dung phản hồi
    required String toEmail, // Email người nhận
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return;
      }

      // Lấy thông tin người dùng từ Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        debugPrint('User data not found!');
        return;
      }

      // Kiểm tra trạng thái isReplied của thư gốc (parent email)
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection('emails')
          .doc(toEmail) // Email người nhận
          .collection('userEmails')
          .doc(parentId) // ID của thư gốc hoặc phản hồi trước
          .get();

      if (!parentDoc.exists) {
        debugPrint('Parent email document does not exist!');
        return;
      }

      // Chỉ truy cập trường isReplied nếu tài liệu tồn tại
      bool isParentReplied = parentDoc['isReplied'] ?? false;
      if (isParentReplied) {
        debugPrint('The parent email has already been replied to.');
        return;  // Nếu thư gốc đã có phản hồi, không gửi thêm phản hồi nữa
      }

      final repliesCollection = FirebaseFirestore.instance
          .collection('emails')
          .doc(toEmail) // Email người nhận
          .collection('userEmails')
          .doc(parentId) // ID của thư gốc hoặc phản hồi trước
          .collection('replies');

      DocumentReference newReplyRef = repliesCollection.doc(); // Tạo document mới và lấy reference
      String newReplyEmailId = newReplyRef.id; // Lấy ID của tài liệu mới

      // Tạo dữ liệu phản hồi mới
      final newReply = {
        'replyId': newReplyEmailId,
        'replyEmailId': parentId,
        'fromReply': user.email ?? 'unknown@example.com', // Người phản hồi
        'fromNameReply': userDoc['name'] ?? 'Unknown', // Tên người phản hồi
        'toReply': widget.from, // Người nhận phản hồi
        'bodyReply': replyContent, // Nội dung phản hồi
        'timestampReply': DateTime.now().toIso8601String(), // Thời gian
        'photoUrlReply': userDoc['photoUrl'] ?? '', // Ảnh đại diện
        'isReplied': false, // Mặc định chưa phản hồi tiếp
      };

      // Thêm phản hồi mới vào Firestore sử dụng newReplyId
      await newReplyRef.set(newReply);

      // Cập nhật trạng thái `isReplied` của thư gốc sau khi phản hồi
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(user.email)
          .collection('userEmails')
          .doc(parentId)
          .update({'isReplied': true});

      // Callback sau khi gửi phản hồi thành công
      widget.onSendReply();
      widget.onCancel();

      debugPrint('Reply sent successfully!');
    } catch (e) {
      debugPrint('Error sending reply: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _replyController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Reply to ${widget.fromName} ...',
              labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nút gửi và Cancel
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
              onPressed: () {
                  String replyContent = _replyController.text.trim();
                  if (replyContent.isNotEmpty) {
                    sendReply(
                      parentId: widget.emailId,
                      replyContent: replyContent,
                      toEmail: widget.to,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 16),
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
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {
                  widget.onCancel(); // Gửi callback khi nhấn nút
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 16),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
