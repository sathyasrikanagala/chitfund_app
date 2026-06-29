import 'package:uuid/uuid.dart';

class ChitGroup {
  final String id;
  final String name;
  final double amount;
  final int totalMembers;
  final String frequency;
  final String drawMethod;
  final double commissionPercent;
  final String startDate;
  final String status;
  final String createdAt;

  ChitGroup({
    String? id,
    required this.name,
    required this.amount,
    required this.totalMembers,
    required this.frequency,
    this.drawMethod = 'Auction',
    this.commissionPercent = 0,
    required this.startDate,
    this.status = 'Active',
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'total_members': totalMembers,
      'frequency': frequency,
      'draw_method': drawMethod,
      'commission_percent': commissionPercent,
      'start_date': startDate,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory ChitGroup.fromMap(Map<String, dynamic> map) {
    return ChitGroup(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      totalMembers: map['total_members'],
      frequency: map['frequency'],
      drawMethod: map['draw_method'] ?? 'Auction',
      commissionPercent: (map['commission_percent'] as num?)?.toDouble() ?? 0,
      startDate: map['start_date'],
      status: map['status'] ?? 'Active',
      createdAt: map['created_at'],
    );
  }
}