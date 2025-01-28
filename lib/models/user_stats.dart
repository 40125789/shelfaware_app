class UserStats {
  final int consumed;
  final int discarded;
  final int donated;
  final String mostWastedFoodItem;
  final String mostCommonCategory;
  final double avgShelfLife;

  UserStats({
    required this.consumed,
    required this.discarded,
    required this.donated,
    required this.mostWastedFoodItem,
    required this.mostCommonCategory,
    required this.avgShelfLife,
  });
}
