class DashboardStats {
  final int totalQuotations;
  final int thisMonthCount;
  final double totalValue;
  final int last7DaysCount;

  const DashboardStats({
    required this.totalQuotations,
    required this.thisMonthCount,
    required this.totalValue,
    required this.last7DaysCount,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalQuotations: (map['total'] as num?)?.toInt() ?? 0,
      thisMonthCount: (map['this_month'] as num?)?.toInt() ?? 0,
      totalValue: (map['total_value'] as num?)?.toDouble() ?? 0,
      last7DaysCount: (map['last_7d'] as num?)?.toInt() ?? 0,
    );
  }

  static const DashboardStats empty = DashboardStats(
    totalQuotations: 0,
    thisMonthCount: 0,
    totalValue: 0,
    last7DaysCount: 0,
  );
}
