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

  const AddPhotoAndDetailsForm({
    required this.onPhotoAdded,
    required this.onDetailsAdded,
    required this.onFormSubmitted,
    Key? key,
  }) : super(key: key);

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
  bool _isFetchingLocation = true;
  bool _isUploadingPhoto = false;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _pickupTimesController.dispose();
    _pickupInstructionsController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    LatLng? newLocation;

    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userDoc.exists &&
        userData != null &&
        userData.containsKey('location')) {
      GeoPoint geoPoint = userData['location'];
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
            markerId: const MarkerId('selected-location'),
            position: newLocation!,
          ),
        };
      });

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
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _isUploadingPhoto = true;
        _isPhotoMissing = false;
      });

      String? url =
          await DonationService().uploadDonationImage(File(image.path));

      setState(() {
        _imageUrl = url;
        _isUploadingPhoto = false;
      });

      if (url != null) {
        widget.onPhotoAdded(url);
      }
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
            markerId: const MarkerId('selected-location'),
            position: result,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(locationProvider);
    final theme = Theme.of(context);

    ref.listen<LatLng?>(locationProvider, (previous, next) {
      if (next != null && mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(next));
        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('selected-location'),
              position: next,
            ),
          };
        });
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
            decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).colorScheme.surface 
              : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle for better UX
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                       
                          const SizedBox(height: 20),

                          // Photo Upload Section
                          GestureDetector(
                            onTap: _pickImage,
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 140,
                                  width: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _isPhotoMissing
                                            ? Colors.red
                                            : Colors.grey.shade300,
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _isUploadingPhoto
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                theme.primaryColor,
                                              ),
                                            ),
                                          )
                                        : _imageUrl == null
                                            ? Container(
                                                color: Colors.grey.shade100,
                                                child: Icon(
                                                  Icons.camera_alt_rounded,
                                                  size: 50,
                                                  color: Colors.grey.shade600,
                                                ),
                                              )
                                            : Image.network(
                                                _imageUrl!,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        theme.primaryColor,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 18,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Take Photo',
                                      style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                        ? Theme.of(context).colorScheme.primary 
                                        : theme.primaryColor,
                                      ),
                                    ),
                                    ],
                                  ),
                                if (_isPhotoMissing)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Please add a photo of your donation',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form Fields
                          TextFormField(
                            controller: _pickupTimesController,
                            decoration: InputDecoration(
                              labelText: 'Pickup Times',
                              hintText:
                                  'e.g., Weekdays 5-8pm, Weekends 9am-6pm',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: theme.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter available pickup times';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _pickupInstructionsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Pickup Instructions',
                              hintText:
                                  'e.g., Leave at the front door, call me when you arrive',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 64),
                                child: Icon(Icons.info_outline),
                              ),
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: theme.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16.0),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter pickup instructions';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Location Section
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: theme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pickup Location',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(
                                            Icons.edit_location_alt,
                                            size: 18),
                                        label: const Text('Change'),
                                        onPressed: _navigateToLocationPage,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: theme.primaryColor,
                                          backgroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: BorderSide(
                                                color: theme.primaryColor),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isFetchingLocation)
                                  Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  theme.primaryColor),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Fetching your location...'),
                                      ],
                                    ),
                                  )
                                else if (_currentLocation != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    child: SizedBox(
                                      height: 200,
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: _currentLocation!,
                                          zoom: 15,
                                        ),
                                        onMapCreated:
                                            (GoogleMapController controller) {
                                          mapController = controller;
                                        },
                                        markers: _markers,
                                        mapType: MapType.normal,
                                        myLocationEnabled: true,
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
                                        compassEnabled: false,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_off,
                                            size: 50,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Unable to fetch location',
                                          style: TextStyle(
                                              color: Colors.grey.shade600),
                                        ),
                                        TextButton(
                                          onPressed: _getUserLocation,
                                          child: const Text('Try Again'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: () {
                              if (_imageUrl == null) {
                                setState(() {
                                  _isPhotoMissing = true;
                                });
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
                                Map<String, String> formData = {
                                  'imageUrl': _imageUrl!,
                                  'pickupTimes': _pickupTimesController.text,
                                  'pickupInstructions':
                                      _pickupInstructionsController.text,
                                };
                                widget.onFormSubmitted(formData);
                                Navigator.of(context).pop(formData);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Submit Donation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
