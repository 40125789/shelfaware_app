import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/models/place.dart';

void main() {
  group('Place', () {
    test('should create a Place instance from JSON', () {
      final json = {
        'name': 'Test Place',
        'vicinity': '123 Test St',
        'place_id': 'test_place_id',
        'geometry': {
          'location': {
            'lat': 37.422,
            'lng': -122.084,
          },
        },
      };

      final place = Place.fromJson(json);

      expect(place.name, 'Test Place');
      expect(place.address, '123 Test St');
      expect(place.placeId, 'test_place_id');
      expect(place.location, LatLng(37.422, -122.084));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'name': 'Test Place',
        'geometry': {
          'location': {
            'lat': 37.422,
            'lng': -122.084,
          },
        },
      };

      final place = Place.fromJson(json);

      expect(place.name, 'Test Place');
      expect(place.address, '');
      expect(place.placeId, '');
      expect(place.location, LatLng(37.422, -122.084));
    });

    test('should create a Place instance with opening hours', () {
      final place = Place(
        name: 'Test Place',
        address: '123 Test St',
        placeId: 'test_place_id',
        location: LatLng(37.422, -122.084),
        openingHours: ['9:00 AM - 5:00 PM'],
      );

      expect(place.name, 'Test Place');
      expect(place.address, '123 Test St');
      expect(place.placeId, 'test_place_id');
      expect(place.location, LatLng(37.422, -122.084));
      expect(place.openingHours, ['9:00 AM - 5:00 PM']);
    });
  });
}