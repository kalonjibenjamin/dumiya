class Delivery {
  final int id;
  final String name;
  final String saleOrder;
  final String customer;
  final String address;
  final String phone;
  final String state;
  final String currency;
  final String targetPos;
  final double amountToCollect;
  final double amountCollected;
  final DateTime? scheduledDate;

  Delivery({
    required this.id,
    required this.name,
    required this.saleOrder,
    required this.customer,
    required this.address,
    required this.phone,
    required this.state,
    required this.currency,
    required this.targetPos,
    required this.amountToCollect,
    required this.amountCollected,
    required this.scheduledDate,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      saleOrder: (json['sale_order'] ?? '') as String,
      customer: (json['customer'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      currency: (json['currency'] ?? '') as String,
      targetPos: (json['target_pos'] ?? '') as String,
      amountToCollect: (json['amount_to_collect'] ?? 0).toDouble(),
      amountCollected: (json['amount_collected'] ?? 0).toDouble(),
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'] as String)
          : null,
    );
  }
}
