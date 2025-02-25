import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/utils/date_formatter.dart';

void main() {
  test('formatExpiryDate formats Timestamp correctly', () {
    // Arrange
    Timestamp testTimestamp = Timestamp.fromDate(DateTime(2023, 10, 5));
    
    // Act
    String formattedDate = formatExpiryDate(testTimestamp);
    
    // Assert
    expect(formattedDate, '5/10/2023');
  });

  test('formatExpiryDate handles single digit day and month correctly', () {
    // Arrange
    Timestamp testTimestamp = Timestamp.fromDate(DateTime(2023, 1, 9));
    
    // Act
    String formattedDate = formatExpiryDate(testTimestamp);
    
    // Assert
    expect(formattedDate, '9/1/2023');
  });
}