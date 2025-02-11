import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfaware_app/pages/location_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPhotoAndDetailsForm extends ConsumerStatefulWidget {
  final Function(String) onPhotoAdded;
  final Function(String, String) onDetailsAdded;

  AddPhotoAndDetailsForm(
      {required this.onPhotoAdded, required this.onDetailsAdded, required Null Function(Map<String, String> formData) onFormSubmitted});

  @override
  _AddPhotoAndDetailsFormState createState() => _AddPhotoAndDetailsFormState();
}

class _AddPhotoAndDetailsFormState
    extends ConsumerState<AddPhotoAndDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _pickupTimesController = TextEditingController();
  final _pickupInstructionsController = TextEditingController();
  String? _imageUrl;
  GoogleMapController? mapController;
  bool _isPhotoMissing = false;

  @override
  void initState() {
    super.initState();
    _getUserLocationFromFirestore();
  }

  Future<void> _getUserLocationFromFirestore() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      GeoPoint geoPoint = userDoc['location'];
      ref
          .read(locationProvider.notifier)
          .updateLocation(LatLng(geoPoint.latitude, geoPoint.longitude));
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
      String? url =
          await DonationService().uploadDonationImage(File(image.path));
      setState(() {
        _imageUrl = url;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(locationProvider);

    ref.listen<LatLng?>(locationProvider, (previous, next) {
      if (next != null && mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(next));
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        // Wrap your entire widget tree in SingleChildScrollView
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    _imageUrl == null
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
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
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
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup instructions';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (selectedLocation != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pickup Location',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
                          target: selectedLocation!,
                          zoom: 15,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          mapController = controller;
                          // Ensure the map is updated when the location changes
                          ref.listen<LatLng?>(locationProvider,
                              (previous, next) {
                            if (next != null) {
                              mapController
                                  ?.animateCamera(CameraUpdate.newLatLng(next));
                            }
                          });
                        },
                        markers: {
                          Marker(
                            markerId: MarkerId('selected-location'),
                            position: selectedLocation!,
                          ),
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_imageUrl != null) {
                      widget.onDetailsAdded(
                        _pickupTimesController.text,
                        _pickupInstructionsController.text,
                      );
                      Navigator.of(context).pop(true);
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
