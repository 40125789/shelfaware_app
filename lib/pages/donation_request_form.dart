import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/donation_request.dart';
import 'package:shelfaware_app/services/donation_request_service.dart';
import 'package:shelfaware_app/repositories/donation_request_repository.dart';

class DonationRequestForm extends StatefulWidget {
  final String productName;
  final String expiryDate;
  final String status;
  final String donorName;
  final String donatorId;
  final String donationId;
  final String imageUrl;
  final String donorImageUrl;

  DonationRequestForm({
    required this.productName,
    required this.expiryDate,
    required this.status,
    required this.donorName,
    required this.donatorId,
    required this.donationId,
    required this.donorImageUrl,
    required this.imageUrl,
  });

  @override
  _DonationRequestFormState createState() => _DonationRequestFormState();
}

class _DonationRequestFormState extends State<DonationRequestForm> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _pickupDateController = TextEditingController();
  DateTime _pickupDateTime = DateTime.now();
  bool _isPickupDateSelected = false;
  String? _pickupDateErrorMessage;

  final DonationRequestService _donationRequestService = DonationRequestService(DonationRequestRepository(firebaseFirestore: FirebaseFirestore.instance, firebaseAuth: FirebaseAuth.instance));

  Future<void> sendRequest() async {
    if (!_isPickupDateSelected) {
      setState(() {
        _pickupDateErrorMessage = 'Please select a pickup date and time';
      });
      return;
    }

    try {
      DonationRequest request = DonationRequest(
        productName: widget.productName,
        expiryDate: widget.expiryDate,
        status: "Pending",
        donorName: widget.donorName,
        donatorId: widget.donatorId,
        donationId: widget.donationId,
        imageUrl: widget.imageUrl,
        donorImageUrl: widget.donorImageUrl,
        pickupDateTime: _pickupDateTime,
        message: _messageController.text,
        requesterId: '', // This will be set in the service layer
        requestDate: Timestamp.now(),
        requesterProfileImageUrl: '', // This will be set in the service layer
      );

      await _donationRequestService.sendRequest(request);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Donation request sent successfully!'),
        backgroundColor: Colors.green,
      ));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _pickupDateTime) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_pickupDateTime),
      );
      if (time != null) {
        setState(() {
          _pickupDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          _pickupDateController.text = DateFormat('yyyy-MM-dd – HH:mm').format(_pickupDateTime);
          _isPickupDateSelected = true;
          _pickupDateErrorMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donation Request Form'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(widget.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(widget.donorImageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'From ${widget.donorName}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectDateTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _pickupDateController,
                    decoration: InputDecoration(
                      labelText: 'Pickup Date & Time (required)',
                      hintText: 'Select pickup date & time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              if (_pickupDateErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _pickupDateErrorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await sendRequest();
                },
                child: Text('Send Request', style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


