import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailappproject/screens/login_register/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAccountWidget extends StatefulWidget {
  final VoidCallback onClose;

  const UserAccountWidget({Key? key, required this.onClose}) : super(key: key);

  @override
  _UserAccountWidgetState createState() => _UserAccountWidgetState();
}

class _UserAccountWidgetState extends State<UserAccountWidget> {
  bool isExpanded = true;
  Map<String, dynamic>? userData;
  bool isLoading = false;
  List<Map<String, dynamic>> savedAccounts = [];
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences and Firebase
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserData = prefs.getString('userData');

    if (storedUserData != null) {
      setState(() {
        userData = jsonDecode(storedUserData);
      });
    } else {
      await _fetchAndSaveUserData();
    }

    await _loadSavedAccounts();
  }

  // Fetch and save user data from Firebase
  Future<void> _fetchAndSaveUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data() as Map<String, dynamic>;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(userData));
      } else {
        setState(() {
          userData = null;
        });
      }
    } catch (e) {
      setState(() {
        userData = null;
      });
    }
  }

  // Load saved accounts from SharedPreferences
  Future<void> _loadSavedAccounts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedAccounts = prefs.getStringList('savedAccounts');

    if (storedAccounts != null) {
      setState(() {
        savedAccounts = storedAccounts
            .map((account) => jsonDecode(account) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  // Save a new account to SharedPreferences
  Future<void> _saveAccount(Map<String, dynamic> account) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedAccountsList = prefs.getStringList('savedAccounts') ?? [];

    savedAccountsList.add(jsonEncode(account));

    await prefs.setStringList('savedAccounts', savedAccountsList);
  }

  // Switch to another account
  Future<void> _switchAccount(Map<String, dynamic> account) async {
    if (userData != null) {
      await _saveAccount(userData!);
    }

    _emailController.text = account['email'] ?? '';

    setState(() {
      userData = account;
    });
  }

  // Sign out and clear data
  Future<void> _signOut() async {
    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.signOut();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('userData'); // Remove user data

      widget.onClose();

      // Use PageRouteBuilder for transition effect
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error signing out: $e");
    }
  }

  // Add another account and clear old data
  Future<void> _addAnotherAccount() async {
    setState(() {
      isLoading = true;
    });

    widget.onClose();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userData'); // Clear old user data

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData != null
              ? _buildContent(userData!)
              : const Center(child: Text('')),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> userData) {
    String? photoUrl = userData['photoUrl'];
    String name = userData['name'] ?? 'User';
    String email = userData['email'] ?? '';

    return Container(
      height: 620,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: widget.onClose,
            ),
          ),
          CircleAvatar(
            radius: 50,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(
            'Hi, $name!',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.black54,
              size: 24,
            ),
            title: Text(
              isExpanded ? 'Hide more accounts' : 'Show more accounts',
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (isExpanded) ...[
                    _buildListTile(
                      userData['name'] ?? 'User',
                      userData['email'] ?? '',
                      userData['photoUrl'],
                    ),
                    const Divider(color: Color(0xFFEEEEEE), height: 1),
                  ],
                  ...savedAccounts.map((account) {
                    return Column(
                      children: [
                        _buildListTile(
                          account['name'] ?? 'User',
                          account['email'] ?? '',
                          account['photoUrl'],
                          onTap: () => _switchAccount(account),
                        ),
                        const Divider(color: Color(0xFFEEEEEE), height: 1),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10), // Thêm margin dưới cho nút Add another account
                  child: ElevatedButton(
                    onPressed: _addAnotherAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                      backgroundColor: Color(0xFFEEEEEE),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
                      ),
                    ).copyWith(
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.black;
                        }
                        return Colors.black54;
                      }),
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.add_circle_outline_outlined, size: 26),
                        const SizedBox(width: 3),
                        const Text(
                          'Add another account',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 20), // Thêm margin dưới cho nút Sign Out
                  child: ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 20),
                      backgroundColor: Color(0xFFEEEEEE),
                      shadowColor: Colors.black54,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
                      ),
                    ).copyWith(
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.black;
                        }
                        return Colors.black54;
                      }),
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.logout, size: 26),
                        const SizedBox(width: 3),
                        const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
      String title,
      String subtitle,
      String? photoUrl, {
        IconData? icon,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 23,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : const AssetImage('assets/default_avatar.png') as ImageProvider,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: icon != null ? Icon(icon, color: Colors.black54) : null,
      onTap: onTap,
    );
  }
}
