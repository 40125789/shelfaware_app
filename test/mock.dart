import 'package:mockito/annotations.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';
import 'package:shelfaware_app/services/auth_services.dart';
import 'package:shelfaware_app/services/food_item_service.dart';


import 'package:shelfaware_app/components/review_card.dart';

@GenerateMocks([
  FoodItemService,
  FavouritesRepository,
  AuthService,
  ReviewCard, // Add ReviewCard here
])
void main() {}
