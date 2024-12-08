import 'package:emailappproject/widgets/user_account_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeaderAppBarWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSearchChanged;

  const HeaderAppBarWidget({Key? key, required this.onSearchChanged}) : super(key: key);

  @override
  _HeaderAppBarWidgetState createState() => _HeaderAppBarWidgetState();
}

class _HeaderAppBarWidgetState extends State<HeaderAppBarWidget> {
  OverlayEntry? _overlayEntry;
  String? _photoUrl;
  List<Map<String, dynamic>> _emails = [];
  List<Map<String, dynamic>> _filteredEmails = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime? _selectedDate;

  bool _isAdvancedSearchVisible = false;
  bool _isDatePickerVisible = false;
  bool _isHovered = false;
  OverlayEntry? _overlayDatePicker;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchEmails();
  }

  void _selectDate(BuildContext context) {
    // Kiểm tra trạng thái DatePicker
    if (_isDatePickerVisible) {
      _overlayDatePicker?.remove();
      setState(() {
        _isDatePickerVisible = false;
      });
      return;
    }

    // Nếu chưa hiển thị, tạo overlay mới
    _isDatePickerVisible = true;

    _overlayDatePicker = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: MediaQuery.of(context).size.width * 0.38,
          right: MediaQuery.of(context).size.width * 0.45,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CalendarDatePicker(
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (DateTime date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _overlayDatePicker?.remove();
                      setState(() {
                        _isDatePickerVisible = false;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _overlayDatePicker?.remove();
                      setState(() {
                        _isDatePickerVisible = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayDatePicker!);
  }

  void _applyFilters() {
    widget.onSearchChanged({
      'query': _searchController.text,
      'from': _fromController.text,
      'to': _toController.text,
      'date': _selectedDate,
    });
  }

  // Tạo OverlayEntry
  OverlayEntry _createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.24,
        right: 15,
        top: 80,
        child: Material(
          color: Colors.transparent,
          child: UserAccountWidget(
            onClose: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
            },
          ),
        ),
      ),
    );
  }

  // Hiển thị hoặc ẩn overlay
  void _toggleOverlay(BuildContext context) {
    if (_overlayEntry == null) {
      // Hiển thị overlay ngay lập tức
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);

      // Tiến hành tải dữ liệu người dùng sau khi overlay đã được hiển thị
      _fetchAndSaveUserData();
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  // Lấy ảnh người dùng từ Firestore và lưu vào SharedPreferences
  Future<void> _fetchAndSaveUserData() async {
    var userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (userData.exists) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? photoUrl = userData['photoUrl'];

      // Lưu vào SharedPreferences nếu có photoUrl
      if (photoUrl != null) {
        await prefs.setString('photoUrl', photoUrl);
        setState(() {
          _photoUrl = photoUrl;
        });
      }
    }
  }

  // Đọc ảnh người dùng từ SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPhotoUrl = prefs.getString('photoUrl');

    if (savedPhotoUrl != null) {
      setState(() {
        _photoUrl = savedPhotoUrl;
      });
    } else {
      await _fetchAndSaveUserData();
    }
  }

  // Fetch emails from Firestore
  Future<void> _fetchEmails() async {
    var emailCollection = await FirebaseFirestore.instance
        .collection('emails')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    setState(() {
      _emails = emailCollection.docs.map((doc) => doc.data()).toList();
      _filteredEmails = _emails; // Initially, show all emails
    });
  }

  void _toggleOverlaySearch(BuildContext context) {
    final overlay = Overlay.of(context);
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 75,
          left: 275,
          right: 740,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _fromController,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _toController,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _selectDate(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate != null
                                ? 'Date: ${_selectedDate!}'.split(' ')[1]
                                : 'Select Date', // Hiển thị ngày hoặc nhắc nhở
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          MouseRegion(
                            onEnter: (_) {
                              _isHovered = true;
                            },
                            onExit: (_) {
                              _isHovered = false;
                            },
                            cursor: SystemMouseCursors.click,
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      overlay.insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (_isDatePickerVisible) {
        _overlayDatePicker?.remove();
        setState(() {
          _isDatePickerVisible = false;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 16, right: 19, bottom: 10),
      child: Row(
        children: [
          // Thanh tìm kiếm
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search mail',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.expand_more, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _isAdvancedSearchVisible = !_isAdvancedSearchVisible;
                    });
                    _toggleOverlaySearch(context); // Toggle overlay khi click
                  },
                ),
                SizedBox(width: 10)
              ],
            ),
          ),
          // Icon buttons
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEmails.length,
              itemBuilder: (context, index) {
                final email = _filteredEmails[index];
                return ListTile(
                  title: Text(email['subject'] ?? 'No Subject'),
                  subtitle: Text(email['content'] ?? 'No Content'),
                  leading: const Icon(Icons.email),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54, size: 27),
            onPressed: () {},
          ),
          const SizedBox(width: 18),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {},
          ),
          const SizedBox(width: 18),
          IconButton(
            icon: const Icon(Icons.apps, color: Colors.black54),
            onPressed: () {},
          ),
          const SizedBox(width: 18),
          // Avatar
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _toggleOverlay(context),
              child: CircleAvatar(
                radius: 21,
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
