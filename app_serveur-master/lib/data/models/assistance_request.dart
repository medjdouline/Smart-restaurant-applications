// lib/data/models/assistance_request.dart
class AssistanceRequest {
  final String id;
  final String tableId;
  final String userId;
  final DateTime createdAt;
  final String status;

  AssistanceRequest({
    required this.id,
    required this.tableId,
    required this.userId,
    required this.createdAt,
    required this.status,
  });

  factory AssistanceRequest.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      // Handle both Timestamp and ISO8601 string formats
      if (json['createdAt'] is String) {
        parsedDate = DateTime.parse(json['createdAt']);
      } else if (json['createdAt'] != null) {
        // Handle Firestore timestamp conversion
        parsedDate = DateTime.fromMillisecondsSinceEpoch(
            (json['createdAt'].seconds * 1000) +
                (json['createdAt'].nanoseconds ~/ 1000000));
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return AssistanceRequest(
      id: json['id'] as String,
      tableId: json['tableId'] as String? ?? json['idTable'] as String? ?? '',
      userId: json['userId'] as String? ?? json['idC'] as String? ?? '',
      createdAt: parsedDate,
      // Handle both 'status' and 'etat' field names from backend
      status: json['status'] as String? ?? json['etat'] as String? ?? 'non traitee',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  AssistanceRequest copyWith({
    String? id,
    String? tableId,
    String? userId,
    DateTime? createdAt,
    String? status,
  }) {
    return AssistanceRequest(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}