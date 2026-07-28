class TripSummary {
  const TripSummary({
    required this.name,
    required this.location,
    required this.dateRange,
    required this.travellerCount,
    required this.ledgerBalance,
  });

  final String name;
  final String location;
  final String dateRange;
  final int travellerCount;
  final int ledgerBalance;

  static const demo = TripSummary(
    name: 'Nyungwe National Park',
    location: 'Rwanda',
    dateRange: 'Oct 12 - Oct 18',
    travellerCount: 4,
    ledgerBalance: 35000,
  );
}
