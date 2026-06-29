class DueCalculator {
  /// Returns how many installments should be due by now,
  /// based on group start date and frequency.
  static int expectedInstallments(String startDateStr, String frequency) {
    DateTime startDate;
    try {
      startDate = DateTime.parse(startDateStr);
    } catch (e) {
      return 0;
    }

    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;

    final daysPassed = now.difference(startDate).inDays;

    switch (frequency) {
      case 'Weekly':
        return (daysPassed / 7).floor() + 1;
      case 'Bi-Monthly':
        return (daysPassed / 15).floor() + 1;
      case 'Monthly':
      default:
        // approximate months passed
        int months = (now.year - startDate.year) * 12 +
            (now.month - startDate.month);
        if (now.day < startDate.day) months -= 1;
        return months + 1;
    }
  }

  /// Calculates pending amount for one member in one group.
  static double pendingAmount({
    required String groupStartDate,
    required String groupFrequency,
    required double installmentAmount,
    required double totalPaid,
  }) {
    final expected = expectedInstallments(groupStartDate, groupFrequency);
    final expectedTotal = expected * installmentAmount;
    final pending = expectedTotal - totalPaid;
    return pending > 0 ? pending : 0;
  }
}