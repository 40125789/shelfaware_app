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
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
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
    AddressSuggestionUtil.fetchAddressSuggestions(_addressController.text)
        .then((suggestions) {
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

      // Clear suggestions immediately
      _addressSuggestions = [];
      
      // Set address text without triggering suggestions
      _addressController.removeListener(_onAddressChanged);
      _addressController.text = address;
      _addressController.addListener(_onAddressChanged);
    });
  }

  void _setCurrentLocation() async {
    if (_isLocationSelected &&
        _selectedLocation.latitude != 0.0 &&
        _selectedLocation.longitude != 0.0) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'location': GeoPoint(
                _selectedLocation.latitude, _selectedLocation.longitude),
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location saved successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving location: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a valid location first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        elevation: 0,
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
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
          _buildSearchBar(),
          if (_addressSuggestions.isNotEmpty) _buildSuggestionsList(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _addressController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[800] 
                : Colors.white,
            hintText: 'Search for a location',
            prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
            suffixIcon: _addressController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _addressController.clear();
                      setState(() {
                        _addressSuggestions = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        constraints: BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            itemCount: _addressSuggestions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              var suggestion = _addressSuggestions[index];
              String address = suggestion['place_name'];
              double lat = suggestion['geometry']['coordinates'][1];
              double lon = suggestion['geometry']['coordinates'][0];

              return ListTile(
                leading: Icon(
                  Icons.location_on, 
                  color: Colors.blue.shade700
                ),
                title: Text(
                  address,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () => _onSuggestionSelected(address, lat, lon),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.my_location, size: 20, color: Colors.white),
              label: Text('Locate Me', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _setCurrentLocation,
              icon: Icon(Icons.check_circle_outline, size: 24, color: Colors.white),
              label: Text(
                'Set as Current Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
