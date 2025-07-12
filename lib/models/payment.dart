enum PaymentStatus { pending, success, failed }
enum PaymentMethod { credit_card, paypal, bank_transfer, crypto }

class Payment {
  final int id;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String receiverName;
  final String? receiverEmail;
  final String? description;
  final String transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.receiverName,
    this.receiverEmail,
    this.description,
    required this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      receiverName: json['receiver_name'],
      receiverEmail: json['receiver_email'],
      description: json['description'],
      transactionId: json['transaction_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod.name,
      'status': status.name,
      'receiver_name': receiverName,
      'receiver_email': receiverEmail,
      'description': description,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}