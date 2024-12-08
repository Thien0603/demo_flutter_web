import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:emailappproject/widgets/reply_widget.dart';
import 'package:dotted_line/dotted_line.dart';

class EmailDetailsWidget extends StatefulWidget {
  final Map<String, dynamic> email;

  const EmailDetailsWidget({super.key, required this.email});

  @override
  State<EmailDetailsWidget> createState() => _EmailDetailsWidgetState();
}

class _EmailDetailsWidgetState extends State<EmailDetailsWidget> {
  Future<Map<String, dynamic>?>? userData;
  Map<String, bool> replyStatus = {};

  @override
  void initState() {
    super.initState();
    replyStatus[widget.email['emailId']] = false;
    userData = getUserData(widget.email['from']);
  }

  // Lấy dữ liệu người gửi từ Firestore
  Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }

  // Khi nhấn nút reply, thay đổi trạng thái isReplying cho email hiện tại
  void _onReplyButtonPressed({String? replyId}) async {
    try {
      DocumentReference docRef;
      if (replyId != null) {
        docRef = FirebaseFirestore.instance
            .collection('emails')
            .doc(widget.email['to'])
            .collection('userEmails')
            .doc(widget.email['emailId'])
            .collection('replies')
            .doc(replyId);
      } else {
        docRef = FirebaseFirestore.instance
            .collection('emails')
            .doc(widget.email['to'])
            .collection('userEmails')
            .doc(widget.email['emailId']);
      }

      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists && !(docSnapshot['isReplied'] ?? false)) {
        setState(() {
          replyStatus[widget.email['emailId']] = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email or reply has already been replied to.')),
        );
      }
    } catch (e) {
      print('Error checking isReplied: $e');
    }
  }

  void _onSendReply() {
    setState(() {
      replyStatus[widget.email['emailId']] = false; // Ẩn reply widget sau khi gửi
      // Cập nhật trạng thái "isReplied" hoặc tạo thư phản hồi mới nếu cần
    });
  }

  // Định dạng thời gian email
  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown Time';

    try {
      DateTime emailTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();

      String formattedDate =
      DateFormat('dd-MM-yyyy, hh:mm a').format(emailTime);

      Duration difference = now.difference(emailTime);
      String timeAgo;

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} tiếng trước';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes} phút trước';
      } else {
        timeAgo = 'Vừa xong';
      }

      return '$formattedDate ($timeAgo)';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  // Mở tệp đính kèm
  Future<void> _openAttachment(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Cannot open URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading sender data"));
        }

        final senderData = snapshot.data;
        final senderPhotoUrl = senderData?['photoUrl'];

        return Stack(
          children: [
            Scrollbar(
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubjectRow(),
                    _buildSenderInfo(senderPhotoUrl),
                    _buildEmailBody(widget.email['body'] ?? 'No content'),
                    _showReplyEmail()
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị chủ đề email
  Widget _buildSubjectRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(left: 65, right: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.email['subject'] ?? 'No Subject',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print, size: 24, color: Colors.black54),
            onPressed: () {
              debugPrint('Print button clicked');
            },
          ),
        ],
      ),
    );
  }

  // Hiển thị thông tin thư gốc
  Widget _buildSenderInfo(String? senderPhotoUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.grey[300],
            backgroundImage: senderPhotoUrl != null
                ? NetworkImage(
                senderPhotoUrl)
                : null,
            child: senderPhotoUrl == null
                ? const Icon(
                Icons.person, size: 24, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          // Sender and timestamp details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: TextSpan và Timestamp với Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween,
                  children: [
                    // RichText chứa fromName và fromEmail
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: widget.email['fromName'] ??
                                'unknown user',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' <${widget.email['from'] ??
                                'unknown@example.com'}>',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                              height: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timestamp và Icons
                    Row(
                      children: [
                        Text(
                          formatTimestamp(
                              widget.email['timestamp']),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                              Icons.star_border, size: 22,
                              color: Colors.black54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.reply, size: 22,
                              color: Colors.black54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.more_vert, size: 20,
                              color: Colors.black54),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                // Hàng 2: Text cho "to"
                Text(
                  'to ${widget.email['to']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 0.3,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị nội dung email thư gốc
  Widget _buildEmailBody(String emailBody) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(left: 65, bottom: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emailBody,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (widget.email['attachments'] != null &&
              widget.email['attachments'].isNotEmpty)
            _buildAttachments(),
          // Hiển thị nút Reply và Forward nếu chưa trả lời
          if (!replyStatus[widget.email['emailId']]!)
            _buildReplyButtons(), // Hiển thị nút reply và forward
          // Nếu đang trả lời thì hiển thị reply widget
          if (replyStatus[widget.email['emailId']]!)
            _buildReplyWidget(),
        ],
      ),
    );
  }

  // Hiển thị nút Reply và Forward của thư gốc
  Widget _buildReplyButtons() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.email['to'])
          .collection('userEmails')
          .doc(widget.email['emailId'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Error loading data');
        }

        bool isReplied = snapshot.data!['isReplied'] ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!isReplied && !replyStatus[widget.email['emailId']]!)
              OutlinedButton.icon(
                onPressed: () {
                  _onReplyButtonPressed();
                },
                icon: const Icon(Icons.quickreply_outlined, size: 20),
                label: const Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 33),
                  foregroundColor: Colors.black,
                ),
              ),
          ],
        );
      },
    );
  }

  // Hiển thị thông tin thư phản hồi
  Widget _buildSenderInfoReply(String? senderPhotoUrlReply, String? fromReply, String? fromNameReply, String? toReply, String? timeReply) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.grey[300],
            backgroundImage: senderPhotoUrlReply != null
                ? NetworkImage(
                senderPhotoUrlReply)
                : null,
            child: senderPhotoUrlReply == null
                ? const Icon(
                Icons.person, size: 24, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          // Sender and timestamp details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: TextSpan và Timestamp với Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween,
                  children: [
                    // RichText chứa fromName và fromEmail
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: fromNameReply ??
                                'unknown user',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' <${fromReply ??
                                'unknown@example.com'}>',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                              height: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timestamp và Icons
                    Row(
                      children: [
                        Text(
                          formatTimestamp(timeReply),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                              Icons.star_border, size: 22,
                              color: Colors.black54),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.reply, size: 22,
                              color: Colors.black54),
                          onPressed: () {
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.more_vert, size: 20,
                              color: Colors.black54),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                // Hàng 2: Text cho "to"
                Text(
                  'to ${toReply}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 0.3,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị nội dung email thư phản hồi
  Widget _buildEmailBodyReply(String? emailBodyReply, String idReply) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(left: 65, bottom: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emailBodyReply ?? 'No content reply',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (!replyStatus[widget.email['emailId']]!)
            _buildNewReplyButtons(idReply),
          if (replyStatus[widget.email['emailId']]!)
            _buildReplyWidget(),
        ],
      ),
    );
  }

  Widget _buildNewReplyButtons(String replyId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.email['to'])
          .collection('userEmails')
          .doc(widget.email['emailId'])
          .collection('replies')
          .doc(replyId)
          .snapshots(),
      builder: (context, snapshot) {
        // In ra dữ liệu của snapshot để kiểm tra
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return const Text('không thể lấy dữ liệu ở thư phản hồi');
        }

        // In ra dữ liệu reply từ Firestore
        debugPrint('Reply Data: ${snapshot.data!.data()}');

        bool isReplied = snapshot.data!['isReplied'] ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!isReplied && !replyStatus[replyId]!)
              OutlinedButton.icon(
                onPressed: () {
                  _onReplyButtonPressed(replyId: replyId);
                },
                icon: const Icon(Icons.quickreply_outlined, size: 20),
                label: const Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 33),
                  foregroundColor: Colors.black,
                ),
              ),
          ],
        );
      },
    );
  }

  //Hiển thị ReplyEmail
  Widget _showReplyEmail() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.email['to'])
          .collection('userEmails')
          .doc(widget.email['emailId'])
          .collection('replies')
          .orderBy('timestampReply', descending: false)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading replies"));
        }

        // In ra toàn bộ dữ liệu trả về từ Firestore
        debugPrint('Replies Data: ${snapshot.data!.docs.map((e) => e.data()).toList()}');

        final replies = snapshot.data!.docs;
        return Column(
          children: [
            const SizedBox(height: 10),
            if (replies.isNotEmpty)
              const Divider(color: Color(0xFFEEEEEE), height: 0.5),
            ...List.generate(replies.length, (index) {
              final reply = replies[index].data() as Map<String, dynamic>;

              String replyId = reply.containsKey('replyId') ? reply['replyId'] : 'Unknown ReplyId';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSenderInfoReply(
                    reply['photoUrlReply'] ?? 'No photoUrlReply',
                    reply['fromReply'] ?? 'No fromReply',
                    reply['fromNameReply'] ?? 'No fromNameReply',
                    reply['toReply'] ?? 'No toReply',
                    reply['timestampReply'] ?? 'Unknown time',
                  ),
                  const SizedBox(height: 8),
                  _buildEmailBodyReply(reply['bodyReply'] ?? 'No content', replyId),
                  if (index < replies.length - 1)
                    const Divider(color: Color(0xFFEEEEEE), height: 0.5),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  // Hiển thị tệp đính kèm
  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DottedLine(dashColor: Colors.grey),
        const SizedBox(height: 10),
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        ...List.generate(widget.email['fileNames'].length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: InkWell(
              onTap: () {
                _openAttachment(widget.email['attachments'][index]['fileUrl']);
              },
              child: Text(
                widget.email['fileNames'][index],
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Hiển thị ReplyWidget
  Widget _buildReplyWidget() {
    if (!replyStatus[widget.email['emailId']]!) {
      return const SizedBox();
    }
    return ReplyWidget(
      from: widget.email['from'],
      fromName: widget.email['fromName'],
      emailId: widget.email['emailId'],
      to: widget.email['to'],
      onCancel: () => setState(() {
        replyStatus[widget.email['emailId']] = false;
      }),
      onSendReply: _onSendReply,
    );
  }
}