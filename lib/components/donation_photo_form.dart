import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfaware_app/pages/location_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/location_service.dart';


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfaware_app/pages/location_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/location_service.dart';

class AddPhotoAndDetailsForm extends ConsumerStatefulWidget {
  final Function(String) onPhotoAdded;
  final Function(String, String) onDetailsAdded;
  final Function(Map<String, String>) onFormSubmitted;

  AddPhotoAndDetailsForm({
    required this.onPhotoAdded,
    required this.onDetailsAdded,
    required this.onFormSubmitted,
  });

  @override
  _AddPhotoAndDetailsFormState createState() => _AddPhotoAndDetailsFormState();
}

class _AddPhotoAndDetailsFormState extends ConsumerState<AddPhotoAndDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _pickupTimesController = TextEditingController();
  final _pickupInstructionsController = TextEditingController();
  String? _imageUrl;
  GoogleMapController? mapController;
  bool _isPhotoMissing = false;
  bool _isFetchingLocation = true;
  bool _isUploadingPhoto = false; // Add this variable
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    LatLng? newLocation;

    final userData = userDoc.data() as Map<String, dynamic>?;
    final hasLocation = userData?.containsKey('location') ?? false;
    if (userDoc.exists && userData != null && hasLocation) {
      GeoPoint geoPoint = userDoc['location'];
      newLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
    } else {
      try {
        Position position = await LocationService().getCurrentLocation();
        newLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        print('Error getting current location: $e');
      }
    }

    if (newLocation != null) {
      ref.read(locationProvider.notifier).updateLocation(newLocation);
      setState(() {
        _currentLocation = newLocation;
        _isFetchingLocation = false;
        _markers = {
          Marker(
            markerId: MarkerId('selected-location'),
            position: newLocation!,
          ),
        };
      });

      // Ensure the map updates with the new location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newLocation != null) {
          mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
        }
      });
    } else {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image != null) {
      setState(() {
        _isUploadingPhoto = true; // Set loading state to true
      });

      String? url = await DonationService().uploadDonationImage(File(image.path));

      setState(() {
        _imageUrl = url;
        _isUploadingPhoto = false; // Set loading state to false
      });

      widget.onPhotoAdded(url!);
    }
  }

  Future<void> _navigateToLocationPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPage()),
    );

    if (result != null && result is LatLng) {
      ref.read(locationProvider.notifier).updateLocation(result);
      mapController?.animateCamera(CameraUpdate.newLatLng(result));
      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId('selected-location'),
            position: result,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(locationProvider);

    ref.listen<LatLng?>(locationProvider, (previous, next) {
      if (next != null && mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(next));
        setState(() {
          _markers = {
            Marker(
              markerId: MarkerId('selected-location'),
              position: next,
            ),
          };
        });
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    _isUploadingPhoto // Show loading indicator while uploading
                        ? CircularProgressIndicator()
                        : _imageUrl == null
                            ? Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey, width: 1),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/camera.png', // Your image path here
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey, width: 1),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                    SizedBox(height: 8),
                    Text(
                      'Take Photo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    if (_isPhotoMissing)
                      Text(
                        'You must add an image',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pickupTimesController,
                decoration: InputDecoration(
                  labelText: 'Pickup Times',
                  hintText: 'Enter pickup times here',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup times';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pickupInstructionsController,
                decoration: InputDecoration(
                  labelText: 'Pickup Instructions',
                  hintText: 'Enter pickup instructions here',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup instructions';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_isFetchingLocation)
                CircularProgressIndicator()
              else if (_currentLocation != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pickup Location',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: _navigateToLocationPage,
                        ),
                      ],
                    ),
                    Container(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 15,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                          // Ensure the map is updated when the location changes
                          ref.listen<LatLng?>(locationProvider, (previous, next) {
                            if (next != null) {
                              mapController?.animateCamera(CameraUpdate.newLatLng(next));
                            }
                          });
                        },
                        markers: _markers,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                )
              else
                Text('Unable to fetch location.'),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_imageUrl != null) {
                      Map<String, String> formData = {
                        'imageUrl': _imageUrl!,
                        'pickupTimes': _pickupTimesController.text,
                        'pickupInstructions': _pickupInstructionsController.text,
                      };
                      widget.onFormSubmitted(formData);
                      Navigator.of(context).pop(formData); // Ensure modal closes only once
                    } else {
                      setState(() {
                        _isPhotoMissing = true;
                      });
                    }
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}