import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/services/location_service.dart';
import 'package:shelfaware_app/services/map_service.dart';
import 'package:shelfaware_app/components/map_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/auth_controller.dart';



class DonationsPage extends StatefulWidget {
  @override
  _DonationsScreenState createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsPage>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestLocationPermission(); // Request permission first
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _loadMap(); // Load map if permission is granted
    } else {
      // Optionally, guide the user to enable permissions in settings
      await openAppSettings();
    }
  }

Future<void> _loadMap() async {
  try {
    final position = await _locationService.getCurrentLocation();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers = _mapService.getMarkers(
        _currentLocation!,
        [
          LatLng(54.6, -5.9), // Example donation points, replace with real data
        ],
      );
    });
  } catch (e) {
    print("Error loading map: $e");
    // You can show a dialog or Snackbar here to inform the user
  }
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
          labelColor: Colors.green, // Set the active tab text color to green
          unselectedLabelColor: Colors.grey[700], // Optional: Set the inactive tab text color
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
            child: Text("List of Donations"), // Placeholder for donation list
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