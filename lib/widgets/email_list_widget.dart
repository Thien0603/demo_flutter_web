import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> emails;
  final int? hoveredIndexEmail;
  final Function(int index, bool isHovered) onHover;
  final Function(Map<String, dynamic> email) onEmailInbox;
  final Function(Map<String, dynamic> email) onEmailStarred;
  final Function(Map<String, dynamic> email) onSaveStarred;
  final Function(Map<String, dynamic> email) onEmailUnstarred;
  final Function(Map<String, dynamic> email) onDelete;
  final Function(Map<String, dynamic> email) onEmailSent;
  final Function(Map<String, dynamic> email) onEmailDraft;
  final Function(Map<String, dynamic> email) onEmailDelete;
  final String selectedMenu;
  final Function(Map<String, dynamic> email, String label) onEmailLabeled;
  final List<String> labels;

  const EmailListWidget({
    super.key,
    required this.emails,
    required this.hoveredIndexEmail,
    required this.onHover,
    required this.onEmailInbox,
    required this.onEmailStarred,
    required this.onSaveStarred,
    required this.onEmailUnstarred,
    required this.onEmailSent,
    required this.selectedMenu,
    required this.onEmailDraft,
    required this.onEmailDelete,
    required this.onEmailLabeled,
    required this.onDelete,
    required this.labels,
  });

  @override
  _EmailListWidgetState createState() => _EmailListWidgetState();
}

class _EmailListWidgetState extends State<EmailListWidget> {

  Future<void> _openAttachment(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.emails.length,
            (index) {
          final email = widget.emails[index];
          bool isChecked = email['isChecked'] ?? false;
          bool isStarred = email['isStarred'] ?? false;

          // Tạo biến displayName dựa trên selectedMenu
          String displayName = widget.selectedMenu == 'Sent'
              ? ('To: ${email['to']}')
              : widget.selectedMenu == 'Drafts'
              ? 'Draft'
              : (email['fromName'] == 'me' ? 'me' : (email['fromName'] ?? 'No name available'));

          List<dynamic>? attachments = email['attachments'];

          return GestureDetector(
            onTap: () {
              if (widget.selectedMenu == 'Drafts') {
                widget.onEmailDraft(email);  // Gọi hàm xử lý mở Compose Form
              }
              else if(widget.selectedMenu == 'Sent' || widget.selectedMenu == 'Inbox'){
                widget.onEmailInbox(email);
              }
              else {
                widget.onEmailStarred(email);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => widget.onHover(index, true),
              onExit: (_) => widget.onHover(index, false),
              child: Stack(
                children: [
                  // Nội dung chính của email
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1),
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: widget.hoveredIndexEmail == index ? Colors.grey[100] : Colors.white,
                      border: Border(
                        top: index == 0
                            ? BorderSide.none
                            : const BorderSide(
                          color: Color(0xFFEEEEEE),
                          width: 0.5,
                        ),
                        bottom: index == widget.emails.length - 1
                            ? BorderSide.none
                            : const BorderSide(
                          color: Color(0xFFEEEEEE),
                          width: 0.5,
                        ),
                      ),
                      boxShadow: widget.hoveredIndexEmail == index
                          ? [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 0.5,
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : [],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Checkbox
                        Checkbox(
                          value: isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              email['isChecked'] = value ?? false;
                            });
                          },
                          activeColor: widget.hoveredIndexEmail == index
                              ? Colors.lightBlueAccent
                              : Colors.lightBlueAccent,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: widget.hoveredIndexEmail == index
                                ? Colors.grey[700]!
                                : Colors.grey,
                            width: 2.0,
                          ),
                        ),
                        // Star Icon
                        IconButton(
                          icon: Icon(
                            isStarred ? Icons.star : Icons.star_border,
                            color: isStarred ? Colors.yellow : (widget.hoveredIndexEmail == index ? Colors.grey[700] : Colors.grey),
                            size: 23,
                          ),
                          onPressed: () async {
                            setState(() {
                              isStarred = !isStarred; // Toggle trạng thái starred
                            });

                            // Gửi trạng thái starred vào Firestore
                            if (isStarred) {
                              await widget.onSaveStarred(email);
                            } else {
                              await widget.onEmailUnstarred(email);
                            }
                          },
                        ),
                        // Label Icon
                        IconButton(
                          icon: const Icon(Icons.label_outline, color: Colors.grey),
                          onPressed: () {
                            _showLabelSelectionDialog(email);
                          },
                        ),
                        const SizedBox(width: 8),
                        // Sender/Receiver based on menu
                        SizedBox(
                          width: 200,
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: widget.selectedMenu == 'Drafts' ? FontWeight.normal : FontWeight.bold,
                              color: widget.selectedMenu == 'Drafts' ? Colors.red : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Subject and Body Combined
                        SizedBox(
                          width: 900,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,  // Căn giữa theo chiều dọc
                            children: [
                              // Hiển thị Subject và Body
                              Align(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: email['subject']?.isNotEmpty == true
                                            ? email['subject']
                                            : 'No Subject',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' - ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      TextSpan(
                                        text: email['body']?.isNotEmpty == true
                                            ? email['body']
                                            : 'No Content',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (attachments != null && attachments.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Duyệt qua danh sách attachments và hiển thị tên từng tệp
                                    for (int i = 0; i < attachments.length; i++)
                                      MouseRegion(
                                        onEnter: (_) {
                                          setState(() {
                                            _isHovered = true;
                                          });
                                        },
                                        onExit: (_) {
                                          setState(() {
                                            _isHovered = false;
                                          });
                                        },
                                        child: GestureDetector(
                                          onTap: () {
                                            // Lấy fileUrl tương ứng với tệp hiện tại
                                            String fileUrl = attachments[i]['fileUrl'];
                                            _openAttachment(fileUrl);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            margin: const EdgeInsets.only(top:2, right: 5),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.black45,
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              color: _isHovered ? Colors.blue.shade100 : Colors.transparent,
                                            ),
                                            child: Text(
                                              email['fileNames'][i] ?? 'No file name',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _isHovered ? Colors.blue.shade700 : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Timestamp
                        SizedBox(
                          width: 100,
                          child: Opacity(
                            opacity: widget.hoveredIndexEmail == index ? 0.0 : 1.0,
                            child: Text(
                              _formatTimestamp(email['timestamp']),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.hoveredIndexEmail == index)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.only(right: 15),
                        width: 180,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.archive, color: Colors.black54, size: 19),
                              onPressed: () {
                                print("Archive email: ${email['id']}");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.black54, size: 20),
                              onPressed: () {
                                widget.onDelete(email);
                                print("Delete email: ${email['id']}");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.mark_email_read, color: Colors.black54, size: 19),
                              onPressed: () {
                                print("Mark as read: ${email['id']}");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.timer, color: Colors.black54, size: 19),
                              onPressed: () {
                                print("Snooze email: ${email['id']}");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "Unknown Time";
    try {
      final dateTime = DateTime.parse(timestamp);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return "Invalid Time";
    }
  }

  void _showLabelSelectionDialog(Map<String, dynamic> email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Label'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.labels.map((label) {
                return ListTile(
                  title: Text(label),
                  onTap: () {
                    widget.onEmailLabeled(email, label);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
