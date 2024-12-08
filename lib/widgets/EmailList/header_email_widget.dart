import 'package:flutter/material.dart';

class HeaderEmailWidget extends StatelessWidget {
  final bool isDetailsView;
  final VoidCallback? onBack;
  const HeaderEmailWidget({super.key, this.isDetailsView = false, this.onBack,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      color: Colors.white,
      child: Row(
        children: isDetailsView
            ? [
          // Hàng đầu tiên: Icon Buttons
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22, color: Colors.black54),
            onPressed: onBack,
          ),
          const SizedBox(width: 13),
          IconButton(
            icon: const Icon(Icons.archive, size: 20, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.report_gmailerrorred, size: 20, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.black54),
            onPressed: () {},
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_unread, size: 20, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.access_time, size: 20, color: Colors.black54),
            onPressed: () {},
          ),
          const Icon(Icons.more_vert, size: 20, color: Colors.black54),
          const Spacer(),
          // Hàng thứ hai: Pagination và thông tin
          Text(
            '1 of 4', // Số lượng hiện tại
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ] : [
          // Header mặc định cho danh sách email
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_box_outline_blank),
                onPressed: () {},
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {},
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                '1-10 of 1',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

