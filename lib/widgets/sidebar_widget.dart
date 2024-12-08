import 'package:flutter/material.dart';

class SidebarWidget extends StatefulWidget {
  final Function(bool) onComposeVisibilityChanged;
  final int emailCount;
  final int draftCount;
  final Function(String) onMenuSelected;
  final Function(String) onLabelSelected;
  final List<String> labels;
  final Function(String) onAddLabel;
  final Function(String, String) onEditLabel;
  final Function(String) onDeleteLabel;

  const SidebarWidget({
    super.key,
    required this.onComposeVisibilityChanged,
    required this.emailCount,
    required this.onMenuSelected,
    required this.draftCount,
    required this.onLabelSelected,
    required this.labels,
    required this.onAddLabel,
    required this.onEditLabel,
    required this.onDeleteLabel,
  });
  @override
  _SidebarWidgetState createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool isHovered = false;
  int selectedIndex = 0;
  int hoveredIndexTab = -1;
  bool isComposeVisible = false;

  void _addLabelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Label'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Label Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  widget.onAddLabel(controller.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editLabelDialog(String oldLabel) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: oldLabel);
        return AlertDialog(
          title: const Text('Edit Label'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Label Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newLabel = controller.text.trim(); // Lấy nhãn mới từ TextField
                if (newLabel.isNotEmpty && newLabel != oldLabel) {
                  widget.onEditLabel(oldLabel, newLabel); // Truyền cả oldLabel và newLabel
                  Navigator.pop(context); // Đóng dialog
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Logo Gmail
          Row(
            children: [
              const SizedBox(width: 4),
              // Logo Gmail
              Image.asset(
                'assets/gmail_logo.png',
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 10),
              Text(
                'Gmail',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          // Compose button with hover effect
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() {
                isHovered = true; // Bật hiệu ứng hover
              });
            },
            onExit: (_) {
              setState(() {
                isHovered = false; // Tắt hiệu ứng hover
              });
            },
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isComposeVisible = true; // Hiển thị form compose
                });
                widget.onComposeVisibilityChanged(true); // Gửi thông báo lên parent
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 150,
                decoration: BoxDecoration(
                  color: isHovered ? Colors.lightBlue[100] : Colors.lightBlue[100],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isHovered
                      ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 0), // Hiệu ứng bóng khi hover
                    ),
                  ]
                      : [],
                ),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                child: Row(
                  children: [
                    Icon(Icons.create, color: Colors.black, size: 25),
                    const SizedBox(width: 8),
                    Text(
                      'Compose',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Menu items
          ...List<Widget>.generate(6, (index) {
            final menuItems = [
              {'icon': Icons.inbox, 'title': 'Inbox', 'count': widget.emailCount.toString()},
              {'icon': Icons.star, 'title': 'Starred'},
              {'icon': Icons.send, 'title': 'Sent'},
              {'icon': Icons.drafts, 'title': 'Drafts', 'countDraft': widget.draftCount.toString()},
              {'icon': Icons.delete_outline, 'title': 'Trashed'},
              {'icon': Icons.expand_more, 'title': 'More'},
            ];

            final item = menuItems[index];

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                setState(() {
                  hoveredIndexTab = index;
                });
              },
              onExit: (_) {
                setState(() {
                  hoveredIndexTab = -1;
                });
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  widget.onMenuSelected(item['title'] as String); // Gửi callback
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? Colors.blue[50]
                        : hoveredIndexTab == index
                        ? Colors.grey[200]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selectedIndex == index
                              ? Colors.blue[300]
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: selectedIndex == index
                              ? Colors.white
                              : Colors.grey[700],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontWeight: selectedIndex == index || index == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (item.containsKey('count'))
                        Text(
                          item['count'] as String,
                          style: TextStyle(
                            color: selectedIndex == index
                                ? Colors.black
                                : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      if (item.containsKey('countDraft'))
                        Text(
                          item['countDraft'] as String,
                          style: TextStyle(
                            color: selectedIndex == index
                                ? Colors.black
                                : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Divider(),
          Text(
            'Labels',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          // List of labels
          ...widget.labels.map((label) {
            return ListTile(
              onTap: () {
                widget.onLabelSelected(label); // Chọn nhãn để lọc email
              },
              leading: const Icon(Icons.label, color: Colors.blue),
              title: Text(label, style: const TextStyle(fontSize: 16)),
              trailing: PopupMenuButton(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editLabelDialog(label); // Sửa nhãn
                  } else if (value == 'delete') {
                    widget.onDeleteLabel(label); // Xóa nhãn
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          }),
          // Add label button
          ListTile(
            onTap: _addLabelDialog,
            leading: const Icon(Icons.add_circle_outline, color: Colors.black54),
            title: const Text('Add Label', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
