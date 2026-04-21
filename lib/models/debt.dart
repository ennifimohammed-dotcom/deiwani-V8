class Payment {
  final double amount;
  final DateTime date;
  final String? note;

  const Payment({
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
      );
}

class Debt {
  final int? id;
  final String name;
  final String phone;
  final double amount;
  final String type; // 'lend' | 'borrow'
  final String? note;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isSettled;
  final List<Payment> payments;

  const Debt({
    this.id,
    required this.name,
    required this.phone,
    required this.amount,
    required this.type,
    this.note,
    required this.createdAt,
    this.dueDate,
    this.isSettled = false,
    this.payments = const [],
  });

  double get paidAmount =>
      payments.fold(0.0, (double s, p) => s + p.amount);
  double get remainingAmount =>
      (amount - paidAmount).clamp(0.0, amount);
  double get progressPercent =>
      amount > 0.0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      !isSettled;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'amount': amount,
        'type': type,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'is_settled': isSettled ? 1 : 0,
      };

  factory Debt.fromMap(
          Map<String, dynamic> map, List<Payment> payments) =>
      Debt(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        dueDate: map['due_date'] != null
            ? DateTime.parse(map['due_date'] as String)
            : null,
        isSettled: (map['is_settled'] as int? ?? 0) == 1,
        payments: payments,
      );

  Debt copyWith({
    int? id,
    String? name,
    String? phone,
    double? amount,
    String? type,
    String? note,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isSettled,
    List<Payment>? payments,
  }) =>
      Debt(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        dueDate: dueDate ?? this.dueDate,
        isSettled: isSettled ?? this.isSettled,
        payments: payments ?? this.payments,
      );
}
