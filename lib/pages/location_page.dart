import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/services/location_service.dart';
import 'package:shelfaware_app/utils/address_suggestion_util.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(0.0, 0.0);
  LatLng _selectedLocation = LatLng(0.0, 0.0);
  Set<Marker> _markers = {};
  TextEditingController _addressController = TextEditingController();
  bool _isLocationSelected = false;
  bool _isLoading = true;
  List<dynamic> _addressSuggestions = [];
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _addressController.addListener(_onAddressChanged);
  }

  Future<void> _getUserLocation() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          GeoPoint? geoPoint = userDoc['location'];
          if (geoPoint != null) {
            setState(() {
              _currentLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
              _isLoading = false;

              _markers.add(Marker(
                markerId: MarkerId('user_location'),
                position: _currentLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: 'Your Location'),
              ));
            });
            if (_mapController != null) {
              _mapController!.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: _currentLocation, zoom: 15.0),
              ));
            }
          }
        }
      } catch (e) {
        print('Error fetching saved location: $e');
      }
    }

    if (_currentLocation.latitude == 0.0 && _currentLocation.longitude == 0.0) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
        _isLocationSelected = true;
        _isLoading = false;

        _markers.add(Marker(
          markerId: MarkerId('user_location'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Your Location'),
        ));

        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation, zoom: 15.0),
          ));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
      setState(() {
        _currentLocation = LatLng(0.0, 0.0);
        _isLoading = false;
      });
    }
  }

  void _onAddressChanged() {
    AddressSuggestionUtil.fetchAddressSuggestions(_addressController.text).then((suggestions) {
      setState(() {
        _addressSuggestions = suggestions;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching address suggestions')),
      );
    });
  }

  void _onSuggestionSelected(String address, double lat, double lon) {
    setState(() {
      _selectedLocation = LatLng(lat, lon);
      _isLocationSelected = true;
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('selected_location'),
        position: _selectedLocation,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: address),
      ));

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation, zoom: 15.0),
        ));
      }

      _addressSuggestions = [];
    });
  }

  void _setCurrentLocation() async {
    if (_isLocationSelected && _selectedLocation.latitude != 0.0 && _selectedLocation.longitude != 0.0) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'location': GeoPoint(_selectedLocation.latitude, _selectedLocation.longitude),
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location saved successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving location: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid location first')),
      );
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                ),
          if (_addressSuggestions.isNotEmpty)
            Positioned(
              top: 70,
              left: 10,
              right: 10,
              child: Container(
                color: Colors.white,
                height: 250,
                child: ListView.builder(
                  itemCount: _addressSuggestions.length,
                  itemBuilder: (context, index) {
                    var suggestion = _addressSuggestions[index];
                    String address = suggestion['place_name'];
                    double lat = suggestion['geometry']['coordinates'][1];
                    double lon = suggestion['geometry']['coordinates'][0];

                    return ListTile(
                      title: Text(address),
                      onTap: () => _onSuggestionSelected(address, lat, lon),
                    );
                  },
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 10,
            right: 10,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Search Address',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 10,
            right: 10,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: Icon(Icons.my_location, size: 20, color: Colors.white),
                  label: Text(
                    'Locate Me',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _setCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text(
                      'Set as Current Location',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}