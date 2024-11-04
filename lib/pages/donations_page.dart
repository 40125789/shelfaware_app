import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/services/location_service.dart';
import 'package:shelfaware_app/services/map_service.dart';
import 'package:shelfaware_app/services/places_service.dart';
import 'package:shelfaware_app/models/place.dart';
import 'package:shelfaware_app/models/place_details.dart';
import 'package:shelfaware_app/components/map_widget.dart';

class DonationsPage extends StatefulWidget {
  @override
  _DonationsScreenState createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsPage>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final PlacesService _placesService = PlacesService();

  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _loadMap();
    } else {
      _showPermissionAlert();
    }
  }

  void _showPermissionAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Permission Required"),
        content: Text(
            "This app needs location access to show nearby donation points. Please enable location permissions in settings."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text("Go to Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMap() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

          // Logging current location
         print("User's current location: $_currentLocation");

      Set<Marker> donationMarkers = _mapService.getMarkers(
        _currentLocation!,
        [LatLng(54.6, -5.9)], // Replace with actual user donation locations
      );

      

      final foodBanks =
          await _placesService.getNearbyFoodBanks(_currentLocation!);
      Set<Marker> foodBankMarkers =
          await Future.wait(foodBanks.map((place) async {
        final details = await _placesService.getPlaceDetails(place.placeId);

        String snippetText;
        if (details != null &&
            details.openingHours != null &&
            details.openingHours!.isNotEmpty) {
          snippetText = details.openingHours!.first;
        } else {
          snippetText = "No opening hours available";
        }

        return Marker(
          markerId: MarkerId(place.name),
          position: place.location,
          infoWindow: InfoWindow(
            title: place.name,
            snippet: snippetText,
            onTap: () => _showPlaceDetails(context, place, details),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      }).toList())
              .then((markers) => markers.toSet());

      if (mounted) {
        setState(() {
          _markers = {...donationMarkers, ...foodBankMarkers};
        });
      }
    } catch (e) {
      print("Error loading map: $e");
    }
  }

  void _showPlaceDetails(
      BuildContext context, Place place, PlaceDetails? details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Address: ${details?.formattedAddress ?? 'N/A'}"),
            SizedBox(height: 8.0),
            if (details?.openingHours != null &&
                details!.openingHours!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Opening Hours:"),
                  ...details.openingHours!.map((hours) => Text(hours)),
                ],
              )
            else
              Text("No opening hours available"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Donations'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey[700],
            tabs: [
              Tab(text: "Donation List"),
              Tab(text: "Donation Map"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Center(
              child: Text("List of Donations"),
            ),
            _currentLocation == null
                ? Center(child: CircularProgressIndicator())
                : MapWidget(
                    initialPosition: _currentLocation!,
                    markers: _markers,
                  ),
          ],
        ),
      ),
    );
  }
}
