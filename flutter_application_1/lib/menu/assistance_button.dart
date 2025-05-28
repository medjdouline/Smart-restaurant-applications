import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user_service.dart';
import 'menu_assistance.dart';

class QuickAssistanceButton extends StatefulWidget {
  final String? tableId;
  
  const QuickAssistanceButton({Key? key, this.tableId}) : super(key: key);

  @override
  State<QuickAssistanceButton> createState() => _QuickAssistanceButtonState();
}

class _QuickAssistanceButtonState extends State<QuickAssistanceButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        return GestureDetector(
          onTap: _isLoading ? null : () => _navigateToAssistance(context),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey : Colors.blue[800],
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_search,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        );
      },
    );
  }

  void _navigateToAssistance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssistancePage(tableId: widget.tableId),
      ),
    );
  }
}