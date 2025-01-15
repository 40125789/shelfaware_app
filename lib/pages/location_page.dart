import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication

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
        // Fetch the saved location from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          GeoPoint? geoPoint = userDoc['location'];
          if (geoPoint != null) {
            // Use the saved location if available
            setState(() {
              _currentLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
              _isLoading = false;

              _markers.add(Marker(
                markerId: MarkerId('user_location'),
                position: _currentLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
        // Handle errors if any
        print('Error fetching saved location: $e');
      }
    }

    // If no saved location, use the geolocator
    if (_currentLocation.latitude == 0.0 && _currentLocation.longitude == 0.0) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      PermissionStatus status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;

        _markers.add(Marker(
          markerId: MarkerId('user_location'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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

  Future<void> _searchAddressSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }

    var response = await http.get(
      Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=pk.eyJ1Ijoic215dGg2NjgiLCJhIjoiY200MDdncmZtMjhuZDJsczdoY2V1bnRneiJ9.LDb-l-_uzNOgzmqgFYMDjQ&limit=5',
      ),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _addressSuggestions = data['features'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching address suggestions')),
      );
    }
  }

  void _onAddressChanged() {
    _searchAddressSuggestions(_addressController.text);
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
    // Check if _selectedLocation has been set
    if (_isLocationSelected &&
        _selectedLocation.latitude != 0.0 &&
        _selectedLocation.longitude != 0.0) {
      // Save the selected location to Firestore
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Log the current values
          print(
              'Saving location: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}');

          // Firestore update
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'location': GeoPoint(
                _selectedLocation.latitude, _selectedLocation.longitude),
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location saved successfully!')),
          );
        } catch (e) {
          // Log error if any
          print('Error saving location: $e');
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
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Google Map widget
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

          // Positioned container for search results
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

          // Positioned text field for searching addresses
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
                  fillColor: Colors.white, 
                  labelText: 'Search Address',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
Positioned(
  bottom: 0, // Position buttons at the very bottom
  left: 10,
  right: 10,
  child: Column(
    children: [
      // Just text with an icon, not a button
      GestureDetector(
        onTap: _getCurrentLocation, // Trigger action when tapped
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location, size: 20, color: Colors.blue), // Location icon
            SizedBox(width: 8),
            Text(
              'Locate Me',
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
      SizedBox(height: 8),
      // Set as Current Location button
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
      SizedBox(height: 16), // Add extra spacing below the button
    ],
  ),
),
        ],
      ),
    );
  }   
}