import 'package:flutter/material.dart';
import 'package:emailappproject/widgets/email_list_widget.dart';
import 'package:emailappproject/widgets/email_details_widget.dart';
import 'package:emailappproject/widgets/EmailList/footer_email_widget.dart';
import 'package:emailappproject/widgets/EmailList/header_email_widget.dart';
class BodyEmailWidget extends StatelessWidget {
  final List<Map<String, dynamic>> emails;
  final List<Map<String, dynamic>> starredEmails;
  final List<Map<String, dynamic>> sentEmails;
  final List<Map<String, dynamic>> draftEmails;
  final List<Map<String, dynamic>> deleteEmails;
  final String selectedMenu;
  final int? hoveredIndexEmail;
  final Function(int, bool) onHover;
  final Function(Map<String, dynamic>) onEmailInbox;
  final Function(Map<String, dynamic>) onEmailStarred;
  final Function(Map<String, dynamic>) onSaveStarred;
  final Function(Map<String, dynamic>) onEmailUnstarred;
  final Function(Map<String, dynamic>) onEmailSent;
  final Function(Map<String, dynamic>) onEmailDraft;
  final Function(Map<String, dynamic>) onEmailDelete;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>, String) onEmailLabeled;
  final Map<String, dynamic>? selectedEmail;
  final Function onBack;
  final List<String> labels;

  const BodyEmailWidget({
    Key? key,
    required this.emails,
    required this.starredEmails,
    required this.selectedMenu,
    required this.draftEmails,
    required this.deleteEmails,
    required this.hoveredIndexEmail,
    required this.onHover,
    required this.onEmailInbox,
    required this.onEmailStarred,
    required this.onSaveStarred,
    required this.onEmailUnstarred,
    required this.onEmailSent,
    required this.onEmailDraft,
    required this.onEmailDelete,
    required this.onEmailLabeled,
    required this.selectedEmail,
    required this.sentEmails,
    required this.onDelete,
    required this.labels,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 16, right: 20, bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Header
            HeaderEmailWidget(
              isDetailsView: selectedEmail != null,
              onBack: () {
                onBack();
              },
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 0.5),
            // Body
            Expanded(
              child: selectedEmail == null
                  ? SingleChildScrollView(
                child: Column(
                  children: [
                    if (selectedMenu == 'Inbox')
                      emails.isEmpty ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "No email messages...",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ) : EmailListWidget(
                        emails: emails,
                        hoveredIndexEmail: hoveredIndexEmail,
                        selectedMenu: selectedMenu,
                        onHover: onHover,
                        onEmailInbox: onEmailInbox,
                        onEmailStarred: onEmailStarred,
                        onSaveStarred: onSaveStarred,
                        onEmailUnstarred: onEmailUnstarred,
                        onEmailSent: onEmailSent,
                        onEmailDraft: onEmailDraft,
                        onEmailLabeled: onEmailLabeled,
                        onDelete: onDelete,
                        onEmailDelete: onEmailDelete,
                        labels: labels,
                      )
                    else if (selectedMenu == 'Starred')
                      starredEmails.isEmpty ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "No starred messages. Stars let you give messages a special status to make them easier to find. To star a message, click on the star outline beside any message or conversation.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ) : EmailListWidget(
                        emails: starredEmails,
                        hoveredIndexEmail: hoveredIndexEmail,
                        selectedMenu: selectedMenu,
                        onHover: onHover,
                        onEmailInbox: onEmailInbox,
                        onEmailStarred: onEmailStarred,
                        onSaveStarred: onSaveStarred,
                        onEmailUnstarred: onEmailUnstarred,
                        onEmailSent: onEmailSent,
                        onEmailDraft: onEmailDraft,
                        onEmailDelete: onEmailDelete,
                        onEmailLabeled: onEmailLabeled,
                        onDelete: onDelete,
                        labels: labels,
                      )
                    else if (selectedMenu == 'Sent')
                      sentEmails.isEmpty ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "No sent messages! Send one now!",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ) : EmailListWidget(
                          emails: sentEmails,
                          hoveredIndexEmail: hoveredIndexEmail,
                          selectedMenu: selectedMenu,
                          onHover: onHover,
                          onEmailInbox: onEmailInbox,
                          onEmailStarred: onEmailStarred,
                          onSaveStarred: onSaveStarred,
                          onEmailUnstarred: onEmailUnstarred,
                          onEmailSent: onEmailSent,
                          onEmailDraft: onEmailDraft,
                          onEmailLabeled: onEmailLabeled,
                          onEmailDelete: onEmailDelete,
                          onDelete: onDelete,
                          labels: labels,
                        )
                    else if (selectedMenu == 'Drafts')
                          draftEmails.isEmpty ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "You don't have any saved drafts. Saving a draft allows you to keep a message you aren't ready to send yet.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ) : EmailListWidget(
                            emails: draftEmails,
                            hoveredIndexEmail: hoveredIndexEmail,
                            selectedMenu: selectedMenu,
                            onHover: onHover,
                            onEmailInbox: onEmailInbox,
                            onEmailStarred: onEmailStarred,
                            onSaveStarred: onSaveStarred,
                            onEmailUnstarred: onEmailUnstarred,
                            onEmailSent: onEmailSent,
                            onEmailDraft: onEmailDraft,
                            onEmailLabeled: onEmailLabeled,
                            onEmailDelete: onEmailDelete,
                            onDelete: onDelete,
                            labels: labels,
                        )
                    else if (selectedMenu == 'Trashed')
                      deleteEmails.isEmpty ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "You don't have any trashed here.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ) : EmailListWidget(
                        emails: deleteEmails,
                        hoveredIndexEmail: hoveredIndexEmail,
                        selectedMenu: selectedMenu,
                        onHover: onHover,
                        onEmailInbox: onEmailInbox,
                        onEmailStarred: onEmailStarred,
                        onSaveStarred: onSaveStarred,
                        onEmailUnstarred: onEmailUnstarred,
                        onEmailSent: onEmailSent,
                        onEmailDraft: onEmailDraft,
                        onEmailLabeled: onEmailLabeled,
                        onEmailDelete: onEmailDelete,
                        onDelete: onDelete,
                        labels: labels,
                      )
                  ],
                ),
              ) : EmailDetailsWidget(email: selectedEmail!)
            ),
            const Divider(color: Color(0xFFEEEEEE), height: 0.5),
            const FooterEmailWidget(), // Footer
          ],
        ),
      ),
    );
  }
}
