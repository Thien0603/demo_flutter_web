import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterEmailWidget extends StatefulWidget {
  const FooterEmailWidget({super.key});

  @override
  State<FooterEmailWidget> createState() => _FooterEmailWidgetState();
}

class _FooterEmailWidgetState extends State<FooterEmailWidget> {
  bool isHoveringGoogle = false;
  bool isHoveringDetails = false;
  bool isHoveringPolicies = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Stack(
        children: [
          // Nội dung Footer cũ
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => isHoveringPolicies = true),
                            onExit: (_) => setState(() => isHoveringPolicies = false),
                            child: GestureDetector(
                              onTap: () {
                                print('Program Policies clicked');
                              },
                              child: Text(
                                'Program Policies',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: isHoveringPolicies
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => isHoveringGoogle = true),
                            onExit: (_) => setState(() => isHoveringGoogle = false),
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(Uri.parse("https://www.google.com/"));
                              },
                              child: Text(
                                'Powered By Google',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: isHoveringGoogle
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Nội dung mới hiển thị đè
          Align(
            alignment: Alignment.topRight,
            child: Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Last account activity: 16 minutes ago',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => isHoveringDetails = true),
                    onExit: (_) => setState(() => isHoveringDetails = false),
                    child: GestureDetector(
                      onTap: () {
                        print('Details clicked');
                      },
                      child: Text(
                        'Details',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: isHoveringDetails
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
