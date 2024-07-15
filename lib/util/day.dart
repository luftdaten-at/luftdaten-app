class Date {
  const Date(this.day, this.month, this.year);

  final int day, month, year;

  @override
  int get hashCode => Object.hash(day, month, year);

  @override
  bool operator ==(Object other) {
    return other is Date && day == other.day && month == other.month && year == other.year;
  }
}

extension GetDate on DateTime {
  Date get date => Date(day, month, year);
}