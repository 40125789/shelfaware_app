import 'package:latlong2/latlong.dart' as latlong2;
import 'package:shelfaware_app/models/donation.dart';


List<DonationLocation> filterDonations(
  List<DonationLocation> donations,
  bool filterExpiringSoon,
  bool filterNewlyAdded,
  double filterDistance,
  latlong2.LatLng referenceLocation,
) {
  final now = DateTime.now();
  final distanceCalculator = latlong2.Distance();

  return donations.where((donation) {
    // Check "Expiring Soon" filter
    final isExpiringSoon = !filterExpiringSoon ||
        DateTime.parse(donation.expiryDate).isBefore(now.add(Duration(days: 3)));

    // Check "Newly Added" filter
    final isNewlyAdded = !filterNewlyAdded ||
        DateTime.parse(donation.addedOn).isAfter(now.subtract(Duration(hours: 24)));

    // Check "Distance" filter
    final donationLocation = latlong2.LatLng(
      donation.location.latitude,
      donation.location.longitude,
    );
    final distance = distanceCalculator(referenceLocation, donationLocation);
    final isWithinDistance = distance <= filterDistance;

    // Include donation only if all active filters pass
    return isExpiringSoon && isNewlyAdded && isWithinDistance;
  }).toList();
}


