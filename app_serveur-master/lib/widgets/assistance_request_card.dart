import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/assistance_request.dart';

class AssistanceRequestCard extends StatelessWidget {
  final AssistanceRequest request;
  final Function(String) onComplete;

  const AssistanceRequestCard({
    Key? key,
    required this.request,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(request.createdAt);
    
    // Check all possible completed status values
    final bool isCompleted = 
        request.status == 'traitee' || 
        request.status == 'completed';
    
    // Format time ago
    String timeAgo;
    if (difference.inSeconds < 60) {
      timeAgo = 'il y a ${difference.inSeconds} secondes';
    } else if (difference.inMinutes < 60) {
      timeAgo = 'il y a ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      timeAgo = 'il y a ${difference.inHours} heures';
    } else {
      timeAgo = DateFormat('dd/MM HH:mm').format(request.createdAt);
    }

    // Background color: yellowish for completed requests
    final cardColor = isCompleted 
        ? Color(0xFFFFF8E1) // Light amber/yellow color for completed requests
        : Colors.white;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.priority_high_rounded,
                  color: isCompleted 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Demande d\'assistance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.table_bar,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table ${request.tableId.replaceAll('table', '')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCompleted ? null : () => onComplete(request.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted 
                      ? Colors.amber.shade700  // Darker amber for completed button
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: isCompleted
                      ? Colors.white
                      : Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.amber.shade700, // Keep color when disabled
                  disabledForegroundColor: Colors.white, // Keep text color when disabled
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isCompleted ? 'Traité' : 'Marquer comme traité'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssistanceRequestsWidget extends StatelessWidget {
  final List<AssistanceRequest> requests;
  final Function(String) onComplete;
  final bool showViewMore;
  final VoidCallback onViewMorePressed;

  const AssistanceRequestsWidget({
    Key? key,
    required this.requests,
    required this.onComplete,
    required this.showViewMore,
    required this.onViewMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune demande d\'assistance en attente',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...requests.map((request) => AssistanceRequestCard(
          request: request,
          onComplete: onComplete,
        )),
        if (showViewMore)
          TextButton(
            onPressed: onViewMorePressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Voir toutes les demandes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}