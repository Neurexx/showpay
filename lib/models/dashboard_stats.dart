class DashboardStats {
  final TransactionStats transactions;
  final RevenueStats revenue;
  final TransactionStats failedTransactions;

  DashboardStats({
    required this.transactions,
    required this.revenue,
    required this.failedTransactions,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      transactions: TransactionStats.fromJson(json['transactions']),
      revenue: RevenueStats.fromJson(json['revenue']),
      failedTransactions: TransactionStats.fromJson(json['failedTransactions']),
    );
  }
}

class TransactionStats {
  final int today;
  final int thisWeek;

  TransactionStats({required this.today, required this.thisWeek});

  factory TransactionStats.fromJson(Map<String, dynamic> json) {
    return TransactionStats(
      today: json['today'],
      thisWeek: json['thisWeek'],
    );
  }
}

class RevenueStats {
  final double today;
  final double thisWeek;

  RevenueStats({required this.today, required this.thisWeek});

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      today: double.parse(json['today'].toString()),
      thisWeek: double.parse(json['thisWeek'].toString()),
    );
  }
}

class RevenueChartData {
  final String date;
  final double revenue;
  final int count;

  RevenueChartData({
    required this.date,
    required this.revenue,
    required this.count,
  });

  factory RevenueChartData.fromJson(Map<String, dynamic> json) {
    return RevenueChartData(
      date: json['date'],
      revenue: double.parse(json['revenue'].toString()),
      count: json['count'],
    );
  }
}