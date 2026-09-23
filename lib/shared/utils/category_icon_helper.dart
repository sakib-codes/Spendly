import 'package:flutter/material.dart';

class CategoryIconHelper {
  static const Map<String, IconData> _iconMap = {
    // Default Expenses
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'entertainment': Icons.movie_rounded,
    'health': Icons.health_and_safety_rounded,
    'education': Icons.school_rounded,

    // Default Incomes
    'salary': Icons.account_balance_wallet_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'business': Icons.storefront_rounded,
    'investment': Icons.trending_up_rounded,
    'gift': Icons.card_giftcard_rounded,

    // Additional general icons
    'other': Icons.category_rounded,
    'home': Icons.home_rounded,
    'pets': Icons.pets_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'fitness': Icons.fitness_center_rounded,
    'child': Icons.child_care_rounded,
    'clothing': Icons.checkroom_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'electronics': Icons.computer_rounded,
    'utilities': Icons.power_rounded,
    'savings': Icons.savings_rounded,
    'cash': Icons.payments_rounded,
  };

  static const Map<String, Color> _colorMap = {
    // Default Expenses
    'food': Colors.orange,
    'transport': Colors.blue,
    'shopping': Colors.pink,
    'bills': Colors.red,
    'entertainment': Colors.purple,
    'health': Colors.teal,
    'education': Colors.indigo,

    // Default Incomes
    'salary': Colors.green,
    'freelance': Colors.cyan,
    'business': Colors.amber,
    'investment': Colors.deepPurple,
    'gift': Colors.lightGreen,

    // Additional general icons
    'other': Colors.grey,
    'home': Colors.brown,
    'pets': Colors.deepOrange,
    'travel': Colors.lightBlue,
    'fitness': Colors.lime,
    'child': Colors.yellow,
    'clothing': Colors.pinkAccent,
    'groceries': Colors.greenAccent,
    'electronics': Colors.blueGrey,
    'utilities': Colors.redAccent,
    'savings': Colors.lightGreenAccent,
    'cash': Colors.tealAccent,
  };

  static const Map<String, String> _assetMap = {
    'food': 'assets/icons/category_food.png',
    'transport': 'assets/icons/category_transport.png',
    'shopping': 'assets/icons/category_shopping.png',
    'bills': 'assets/icons/category_bills.png',
    'entertainment': 'assets/icons/category_entertrainment.png',
    'health': 'assets/icons/category_health.png',
    'education': 'assets/icons/category_education.png',
    'home': 'assets/icons/category_home.png',
    'child': 'assets/icons/category_child.png',
    'fitness': 'assets/icons/category_sports.png',
    'salary': 'assets/icons/category_salary.png',
    'investment': 'assets/icons/category_investment.png',
    'business': 'assets/icons/category_business.png',
    'freelance': 'assets/icons/category_freelance.png',
    'savings': 'assets/icons/icon_coin.png',
    'cash': 'assets/icons/icon_wallet.png',
    'groceries': 'assets/icons/category_groceries.png',
    'travel': 'assets/icons/category_travel.png',
    'pets': 'assets/icons/category_pets.png',
    'personal_care': 'assets/icons/category_personalcare.png',
    'subscriptions': 'assets/icons/category_subscriptions.png',
    'donations': 'assets/icons/category_gifts.png',
    'gift': 'assets/icons/category_gifts.png',
    'bonus': 'assets/icons/category_bonus.png',
    'refunds': 'assets/icons/category_refunds.png',
    'other': 'assets/icons/category_others.png',
  };

  /// Returns a widget that is either an Image (if a custom icon exists) or a Material Icon.
  static Widget getIconWidget(
    String iconKey, {
    double size = 24,
    Color? color,
  }) {
    if (_assetMap.containsKey(iconKey)) {
      return Transform.scale(
        scale: 1.4, // Scale up the PNGs visually without changing layout bounds
        child: Image.asset(
          _assetMap[iconKey]!,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }
    return Icon(
      getIcon(iconKey),
      size: size,
      color: color ?? getColor(iconKey),
    );
  }

  /// Returns the matching IconData, or a default fallback if not found.
  static IconData getIcon(String iconKey) {
    return _iconMap[iconKey] ?? Icons.category_rounded;
  }

  /// Returns a vibrant color for the icon, or a default fallback if not found.
  static Color getColor(String iconKey) {
    return _colorMap[iconKey] ?? Colors.blueAccent;
  }

  /// Returns all available icon keys and their corresponding IconData.
  static Map<String, IconData> getAllIcons() {
    return _iconMap;
  }
}
