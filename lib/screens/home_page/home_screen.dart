import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:emailappproject/widgets/compose_mail_widget.dart';
import 'package:emailappproject/widgets/header_appbar_widget.dart';
import 'package:emailappproject/widgets/sidebar_widget.dart';
import 'package:emailappproject/widgets/EmailList/body_email_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allEmails = [];
  List<Map<String, dynamic>> emails = [];
  List<Map<String, dynamic>> starredEmails = [];
  List<Map<String, dynamic>> sentEmails = [];
  List<Map<String, dynamic>> draftEmails = [];
  List<Map<String, dynamic>> deleteEmails = [];
  Map<String, dynamic>? selectedEmail;
  String? _draftId;
  Map<String, dynamic>? tempDraftEmail;
  int? hoveredIndexEmail;
  bool isComposeVisible = false;
  String selectedMenu = 'Inbox';
  String? userEmail;
  List<String> labels = [];
  String? selectedLabel;

  late StreamSubscription _emailSubscription;
  late StreamSubscription _starredEmailSubscription;
  late StreamSubscription _sentEmailSubscription;
  late StreamSubscription _draftEmailSubscription;
  late StreamSubscription _deleteEmailSubscription;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }
  @override
  void dispose() {
    _emailSubscription.cancel();
    _starredEmailSubscription.cancel();
    _sentEmailSubscription.cancel();
    _draftEmailSubscription.cancel();
    _deleteEmailSubscription.cancel();
    super.dispose();
  }

  Future<void> _getUserEmail() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;
      setState(() {
        userEmail = user.email;
      });

      // Fetch labels from Firestore
      _firestore.collection('users').doc(userId).get().then((doc) {
        if (doc.exists) {
          setState(() {
            labels = List<String>.from(doc.data()?['labels'] ?? []); // Lấy danh sách labels
          });
        } else {
          print('No labels found for user.');
        }
      }).catchError((error) {
        print('Failed to fetch labels: $error');
      });

      _fetchEmails(userEmail!);
      _fetchStarred(userEmail!);
      _fetchSents(userEmail!);
      _fetchDraftEmails(userEmail!);
      _fetchDeleted(userEmail!);
    } else {
      print('User not logged in');
    }
  }

  //Inbox
  void _fetchEmails(String email) {
    _firestore
        .collection('emails')
        .doc(email)
        .collection('userEmails')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedEmails = [];
        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> emailData = doc.data();
          emailData['id'] = doc.id;
          fetchedEmails.add(emailData);
        }
        setState(() {
          _allEmails = fetchedEmails;
          emails = List.from(fetchedEmails);
          starredEmails = emails.where((email) => email['isStarred'] ?? false).toList();
        });
      } else {
        setState(() {
          _allEmails = [];
          emails = [];
        });
      }
    });
  }

  void _handleEmailInbox(Map<String, dynamic> email) {
    setState(() {
      selectedEmail = email;
    });
  }

  //Starred
  void _fetchStarred(String starredEmail) {
    FirebaseFirestore.instance
        .collection('starreds')
        .doc(starredEmail)
        .collection('userStarredEmails')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Chuyển đổi tài liệu Firestore thành danh sách
        final List<Map<String, dynamic>> fetchedStarredEmails = querySnapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        // Cập nhật danh sách starredEmails
        setState(() {
          starredEmails = fetchedStarredEmails;
        });

        print('Starred emails updated: $fetchedStarredEmails');
      } else {
        setState(() {
          starredEmails = [];
        });
        print('No starred emails found.');
      }
    });
  }

  void _handleEmailStarred(Map<String, dynamic> starredEmail) {
    if (starredEmail['emailType'] == 'draft') {
      _handleEmailDraft(starredEmail);
    } else {
      setState(() {
        selectedEmail = starredEmail;
      });
    }
  }

  void _unsaveEmailStarred(Map<String, dynamic> unstarredEmail) async {
    try {
      String from = FirebaseAuth.instance.currentUser?.email ?? '';
      final emailType = unstarredEmail['emailType'];
      final docId = unstarredEmail['emailId'] ?? unstarredEmail['draftId'];

      // Mã ánh xạ emailType với collection tương ứng
      final collectionMapping = {
        'inbox': 'emails',
        'sent': 'sents',
        'draft': 'drafts',
      };

      final collection2Mapping = {
        'inbox': 'userEmails',
        'sent': 'userSentEmails',
        'draft': 'userDrafts',
      };

      // Lấy tên collection tương ứng từ emailType
      final collectionName = collectionMapping[emailType];
      if (collectionName == null) {
        print('Email type không hợp lệ: $emailType');
        return; // Nếu không hợp lệ thì không làm gì cả
      }

      final collection2Name = collection2Mapping[emailType];
      if (collection2Name == null) {
        print('Email type không hợp lệ: $emailType');
        return; // Nếu không hợp lệ thì không làm gì cả
      }

      // Cập nhật trạng thái isStarred trong bộ sưu tập email tương ứng (Inbox, Sent, Draft)
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(from)
          .collection(collection2Name)
          .doc(docId)
          .update({
        'isStarred': false,
      });

      // Xóa email khỏi collection starreds
      await FirebaseFirestore.instance
          .collection('starreds')
          .doc(from) // Email người dùng
          .collection('userStarredEmails') // Bộ sưu tập email đã starred
          .doc(docId)
          .delete();

      print('Email đã được bỏ starred.');
    } catch (e) {
      print('Lỗi khi bỏ trạng thái starred: $e');
    }
  }

  void _saveEmailStarred(Map<String, dynamic> starredEmail) async {
    try {
      String from = FirebaseAuth.instance.currentUser?.email ?? '';
      final emailType = starredEmail['emailType'];
      final docId = starredEmail['emailId'] ?? starredEmail['draftId'];

      String fromName = starredEmail['fromName'];

      if (emailType == 'sent') {
        fromName = 'Me';
      } else if (emailType == 'draft') {
        fromName = 'Draft';
      }

      // Mã ánh xạ emailType với collection tương ứng
      final collectionMapping = {
        'inbox': 'emails',
        'sent': 'sents',
        'draft': 'drafts',
      };

      final collection2Mapping = {
        'inbox': 'userEmails',
        'sent': 'userSentEmails',
        'draft': 'userDrafts',
      };

      // Lấy tên collection tương ứng từ emailType
      final collectionName = collectionMapping[emailType];
      if (collectionName == null) {
        print('Email type không hợp lệ: $emailType');
        return; // Nếu không hợp lệ thì không làm gì cả
      }

      final collection2Name = collection2Mapping[emailType];
      if (collection2Name == null) {
        print('Email type không hợp lệ: $emailType');
        return; // Nếu không hợp lệ thì không làm gì cả
      }

      // Cập nhật trạng thái isStarred trong bộ sưu tập email tương ứng (Inbox, Sent, Draft)
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(from)
          .collection(collection2Name)
          .doc(docId)
          .update({
        'isStarred': true,
      });

      // Lưu email vào collection starreds để đánh dấu email starred
      await FirebaseFirestore.instance
          .collection('starreds')
          .doc(from)
          .collection('userStarredEmails')
          .doc(docId)
          .set({
        ...starredEmail,
        'isStarred': true,
        'emailType': emailType,
        'fromName': fromName,
      });

      print('Email đã được lưu với trạng thái isStarred = true');
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái starred: $e');
    }
  }

  //Sent
  void _fetchSents(String sentEmail) {
    _firestore
        .collection('sents')
        .doc(sentEmail)
        .collection('userSentEmails')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedSentEmails = [];
        for (var doc in querySnapshot.docs) {
          var sentEmail = doc.data();

          if (sentEmail['from'] == sentEmail) {
            sentEmail['fromName'] = 'me';
          }

          fetchedSentEmails.add(sentEmail);
        }
        setState(() {
          sentEmails = fetchedSentEmails;
        });
      } else {
        setState(() {
          sentEmails = [];
        });
      }
    });
  }

  void _handleEmailSent(Map<String, dynamic> sentEmail) {
    setState(() {
      selectedEmail = sentEmail;
    });
  }

  void _updateSentEmails(Map<String, dynamic> sentEmail) {
    setState(() {
      sentEmails.insert(0, sentEmail);
    });
  }

  //Draft
  void _fetchDraftEmails(String draftEmail) {
    _firestore
        .collection('drafts')
        .doc(draftEmail)
        .collection('userDrafts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedDrafts = [];
        for (var doc in querySnapshot.docs) {
          fetchedDrafts.add(doc.data());
        }
        setState(() {
          draftEmails = fetchedDrafts;
        });
      } else {
        setState(() {
          draftEmails = [];
        });
      }
    });
  }

  _handleEmailDraft(Map<String, dynamic> email) {
    if (email['draftId'] != null) {
      // Lấy thông tin thư nháp từ Firestore theo draftID
      _firestore.collection('drafts')
          .doc(userEmail)
          .collection('userDrafts')
          .doc(email['draftId'])
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          setState(() {
            selectedEmail = null;  // Đóng các thư khác khi mở Compose
            isComposeVisible = true;  // Hiển thị Compose Form

            // Kiểm tra xem thư nháp có thay đổi hay không
            if (tempDraftEmail == null || tempDraftEmail!['draftId'] != email['draftId']) {
              tempDraftEmail = docSnapshot.data();  // Cập nhật thư nháp hiện tại vào tempDraftEmail
              _draftId = email['draftId'];  // Cập nhật _draftId
            }
          });
        }
      }).catchError((e) {
        print("Error fetching draft: $e");
      });
    }
  }

  //Delete
  void _fetchDeleted(String deleteEmail) {
    FirebaseFirestore.instance
        .collection('deleted')
        .doc(deleteEmail)
        .collection('deletedEmails')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Chuyển đổi tài liệu Firestore thành danh sách
        final List<Map<String, dynamic>> fetchedDeletedEmails = querySnapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        // Cập nhật danh sách starredEmails
        setState(() {
          deleteEmails = fetchedDeletedEmails;
        });

      } else {
        setState(() {
          deleteEmails = [];
        });
        print('No deleted emails found.');
      }
    });
  }

  void _handleEmailDelete(Map<String, dynamic> deleteEmail){
    setState(() {
      selectedEmail = deleteEmail;
    });
  }

  void _deleteEmail(Map<String, dynamic> deleteEmail) async {
    try {
      String from = FirebaseAuth.instance.currentUser?.email ?? '';
      final emailType = deleteEmail['emailType'];
      final docId = deleteEmail['emailId'] ?? deleteEmail['draftId'];
      // Lấy emailId từ email

      print('Deleting email with id: $docId');

      // 2. Xóa email khỏi danh sách hiện tại
      setState(() {
        emails.removeWhere((e) => e['emailId'] == docId);
      });

      await FirebaseFirestore.instance
          .collection('starreds')
          .doc(from)
          .collection('deletedEmails')
          .doc(docId)
          .set({
        ...deleteEmail,
        'isDeleted': true,
      });

      print('Email deleted and saved to Firestore: $docId');
    } catch (error) {
      print('Error deleting email: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting email: $error')),
      );
    }
  }


  //label
  void _filterEmails(String query) {
    setState(() {
      if (query.isEmpty) {
        emails = _allEmails;
      } else {
        emails = _allEmails.where((email) {
          final subject = email['subject']?.toLowerCase() ?? '';
          final content = email['content']?.toLowerCase() ?? '';
          return subject.contains(query.toLowerCase()) || content.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _addLabel(String label) {
    setState(() {
      labels.add(label); // Cập nhật danh sách labels trong giao diện
    });
    _saveLabelToFirestore(label); // Lưu nhãn vào Firestore
  }

  void _editLabel(String oldLabel, String newLabel) {
    final userId = _auth.currentUser?.uid; // Lấy UID của người dùng hiện tại
    final userEmail = _auth.currentUser?.email; // Lấy email của người dùng hiện tại

    if (userId == null || userEmail == null) {
      print('User not logged in');
      return;
    }

    // Lấy danh sách nhãn hiện tại và cập nhật nhãn mới
    _firestore.collection('users').doc(userId).get().then((docSnapshot) {
      if (docSnapshot.exists) {
        List<String> currentLabels = List<String>.from(docSnapshot.data()?['labels'] ?? []);
        if (currentLabels.contains(oldLabel)) {
          currentLabels.remove(oldLabel);
          currentLabels.add(newLabel);

          // Cập nhật danh sách labels trong tài liệu 'users'
          _firestore.collection('users').doc(userId).update({'labels': currentLabels}).then((_) {

            // Cập nhật nhãn trong các email
            _updateEmailsLabel(userEmail, oldLabel, newLabel);

            setState(() {
              labels = currentLabels; // Cập nhật giao diện
            });


          }).catchError((error) {
            print('Failed to update label in Firestore: $error');
          });
        } else {
          print('Old label not found in current labels.');
        }
      } else {
        print('User document does not exist.');
      }
    }).catchError((error) {
      print('Failed to fetch user document: $error');
    });
  }

  void _updateEmailsLabel(String userEmail, String oldLabel, String newLabel) {
    // Tìm tất cả email chứa oldLabel
    _firestore
        .collection('emails')
        .doc(userEmail)
        .collection('userEmails')
        .where('labels', arrayContains: oldLabel)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        print('No emails found with label: $oldLabel');
        return;
      }

      for (var doc in querySnapshot.docs) {
        // Cập nhật danh sách labels trong email
        Map<String, dynamic> emailData = doc.data();
        List<String> emailLabels = List<String>.from(emailData['labels'] ?? []);
        emailLabels.remove(oldLabel);
        emailLabels.add(newLabel);

        // Cập nhật tài liệu email trong Firestore
        _firestore
            .collection('emails')
            .doc(userEmail)
            .collection('userEmails')
            .doc(doc.id)
            .update({'labels': emailLabels}).then((_) {
          print('Updated label in email ${doc.id}');
        }).catchError((error) {
          print('Failed to update email label: $error');
        });
      }
    }).catchError((error) {
      print('Failed to fetch emails for label update: $error');
    });
  }

  void _deleteLabel(String label) async {
    final userEmail = _auth.currentUser?.email; // Sử dụng email để truy vấn email
    final userId = _auth.currentUser?.uid; // Sử dụng UID để truy vấn nhãn của người dùng

    if (userEmail == null || userId == null) {
      print('User not logged in');
      return;
    }

    try {
      // **Bước 1**: Xóa nhãn khỏi danh sách nhãn của người dùng
      await _firestore.collection('users').doc(userId).update({
        'labels': FieldValue.arrayRemove([label]),
      });
      print('Label "$label" deleted successfully from user labels.');

      // **Bước 2**: Lấy danh sách email chứa nhãn cần xóa
      final querySnapshot = await _firestore
          .collection('emails')
          .doc(userEmail)
          .collection('userEmails')
          .where('labels', arrayContains: label)
          .get();

      // **Bước 3**: Xóa nhãn khỏi danh sách nhãn của từng email
      for (var doc in querySnapshot.docs) {
        await _firestore
            .collection('emails')
            .doc(userEmail)
            .collection('userEmails')
            .doc(doc.id)
            .update({
          'labels': FieldValue.arrayRemove([label]),
        });
        print('Label "$label" removed from email ${doc.id}');
      }

      // **Bước 4**: Cập nhật giao diện
      setState(() {
        labels.remove(label);
      });
    } catch (error) {
      print('Failed to delete label: $error');
    }
  }

  void _filterByLabel(String label) {
    final userEmail = _auth.currentUser?.email;

    if (userEmail == null) {
      print('User not logged in');
      return;
    }

    print('Filtering emails by label: $label');
    _firestore
        .collection('emails')
        .doc(userEmail)
        .collection('userEmails')
        .where('labels', arrayContains: label)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        print('No emails found with label: $label');
        setState(() {
          emails = []; // Xóa danh sách email nếu không có email nào khớp
        });
        return;
      }

      // Cập nhật danh sách emails từ kết quả truy vấn
      setState(() {
        emails = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Gắn document ID vào dữ liệu email
          return data;
        }).toList();
      });

      print('Found ${emails.length} emails with label: $label');
    }).catchError((error) {
      print('Failed to filter emails by label: $error');
    });
  }

  void _labelEmail(Map<String, dynamic> email, String label) {
    final emailId = email['id'];
    final userEmail = _auth.currentUser?.email; // Sử dụng email thay vì UID

    if (userEmail == null) {
      print('User not logged in');
      return; // Ngừng xử lý nếu không có email người dùng
    }

    if (emailId == null) {
      print('Email ID is null');
      return; // Ngừng xử lý nếu không có emailId
    }

    setState(() {
      email['labels'] ??= []; // Đảm bảo danh sách labels tồn tại
      if (!email['labels'].contains(label)) {
        email['labels'].add(label); // Thêm nhãn mới
      }
    });

    // Lưu nhãn vào Firestore
    _firestore
        .collection('emails')
        .doc(userEmail) // Sử dụng email để xác định tài liệu của người dùng
        .collection('userEmails')
        .doc(emailId)
        .set({
      ...email, // Lưu toàn bộ dữ liệu email
      'labels': email['labels'], // Ghi đè trường labels
    }, SetOptions(merge: true)) // Merge để không ghi đè các trường khác
        .then((_) {
      print('Labels updated successfully for email $emailId');
    }).catchError((error) {
      print('Failed to update labels: $error');
    });
  }

  void _saveLabelToFirestore(String label) {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      final userDocRef = _firestore.collection('users').doc(userId);

      userDocRef.get().then((docSnapshot) {
        if (docSnapshot.exists) {
          // Tài liệu tồn tại, thêm nhãn vào mảng labels
          userDocRef.update({
            'labels': FieldValue.arrayUnion([label]),
          }).then((_) {
            print('Label "$label" saved successfully.');
          }).catchError((error) {
            print('Failed to update label: $error');
          });
        } else {
          // Tài liệu không tồn tại, tạo mới
          userDocRef.set({
            'labels': [label],
          }).then((_) {
            print('Label "$label" created successfully.');
          }).catchError((error) {
            print('Failed to create label: $error');
          });
        }
      }).catchError((error) {
        print('Failed to check document existence: $error');
      });
    } else {
      print('User not logged in');
    }
  }

  //search
  void _filtersearchEmails(Map<String, dynamic> filters) {
    setState(() {
      emails = _allEmails.where((email) {
        final query = filters['query']?.toLowerCase() ?? '';
        final from = filters['from']?.toLowerCase() ?? '';
        final to = filters['to']?.toLowerCase() ?? '';
        final date = filters['date'] as DateTime?;

        final subject = email['subject']?.toLowerCase() ?? '';
        final emailFrom = email['from']?.toLowerCase() ?? '';
        final emailTo = email['to']?.toLowerCase() ?? '';
        final timestamp = email['timestamp'] != null
            ? DateTime.parse(email['timestamp'])
            : null;

        final matchesQuery = query.isEmpty || subject.contains(query);
        final matchesFrom = from.isEmpty || emailFrom.contains(from);
        final matchesTo = to.isEmpty || emailTo.contains(to);
        final matchesDate =
            date == null || (timestamp != null && timestamp.isAtSameMomentAs(date));

        return matchesQuery && matchesFrom && matchesTo && matchesDate;
      }).toList();
    });
  }

  void _onHover(int index, bool isHovered) {
    setState(() {
      hoveredIndexEmail = isHovered ? index : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: Row(
                  children: [
                    // Sidebar
                    Flexible(
                      flex: 2,
                      child: SidebarWidget(
                        emailCount: emails.length,
                        labels: labels,
                        draftCount: draftEmails.length,
                        onComposeVisibilityChanged: (isVisible) {
                          setState(() {
                            isComposeVisible = isVisible;
                          });
                        },
                        onMenuSelected: (menu) {
                          setState(() {
                            selectedMenu = menu;
                            selectedEmail = null;
                            selectedLabel = null;
                            emails = _allEmails;
                          });
                        },
                        onLabelSelected: _filterByLabel,
                        onAddLabel: _addLabel,
                        onEditLabel: _editLabel,
                        onDeleteLabel: _deleteLabel,
                      ),
                    ),
                    // Main content
                    Flexible(
                      flex: 11,
                      child: Column(
                        children: [
                          Flexible(
                            flex: 8,
                            child: HeaderAppBarWidget(onSearchChanged: _filtersearchEmails,),
                          ),
                          Flexible(
                            flex: 80,
                            child: BodyEmailWidget(
                              emails: emails,
                              starredEmails: starredEmails,
                              sentEmails: sentEmails,
                              draftEmails: draftEmails,
                              deleteEmails: deleteEmails,
                              selectedMenu: selectedMenu,
                              hoveredIndexEmail: hoveredIndexEmail,
                              onHover: _onHover,
                              onEmailInbox: _handleEmailInbox,
                              onEmailStarred: _handleEmailStarred,
                              onSaveStarred: _saveEmailStarred,
                              onEmailUnstarred: _unsaveEmailStarred,
                              onEmailSent: _handleEmailSent,
                              onEmailDraft: _handleEmailDraft,
                              onEmailDelete: _handleEmailDelete,
                              onDelete: _deleteEmail,
                              selectedEmail: selectedEmail,
                              onEmailLabeled: _labelEmail,
                              labels: labels,
                              onBack: () {
                                setState(() {
                                  selectedEmail = null;  // Khi quay lại sẽ không hiển thị detail email
                                  isComposeVisible = false;  // Ẩn Compose Form
                                });
                              },
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Compose Email
          if (isComposeVisible)
            ComposeMail(
              onClose: () {
                setState(() {
                  isComposeVisible = false;
                  tempDraftEmail = null;
                  _draftId = null;
                });
              },
              // Chuyển thông tin từ tempDraftEmail vào compose
              initialTo: tempDraftEmail?['to'] ?? '',
              initialSubject: tempDraftEmail?['subject'] ?? '',
              initialBody: tempDraftEmail?['body'] ?? '',
              draftId: _draftId,
              onEmailSent: _updateSentEmails,
            )
        ],
      ),
    );
  }
}
