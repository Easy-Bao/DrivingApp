class DriverAccountSnapshot {
  const DriverAccountSnapshot({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.vehicleType = '',
    this.plateNumber = '',
    this.ratingLabel = '—',
    this.totalTrips = 0,
    this.completedTrips = 0,
    this.lifetimeEarnings = 0,
    this.averageRating = 0,
  });

  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String plateNumber;
  final String ratingLabel;
  final int totalTrips;
  final int completedTrips;
  final double lifetimeEarnings;
  final double averageRating;
}
