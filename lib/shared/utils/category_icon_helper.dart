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

    // Transport
    'bike': Icons.pedal_bike_rounded,
    'bus': Icons.directions_bus_rounded,
    'metro': Icons.train_rounded,
    'courier': Icons.local_shipping_rounded,

    // Utilities / Bills
    'electricity': Icons.bolt_rounded,
    'gas': Icons.local_fire_department_rounded,
    'wifi': Icons.wifi_rounded,
    'domain': Icons.language_rounded,
    'hosting': Icons.dns_rounded,
    'antivirus': Icons.security_rounded,

    // Payment
    'credit_debit_card': Icons.credit_card_rounded,
    'bank': Icons.account_balance_rounded,
    'banking': Icons.account_balance_rounded,

    // Subscription services
    'netflix': Icons.smart_display_rounded,
    'spotify': Icons.music_note_rounded,
    'youtube': Icons.play_circle_rounded,
    'chatgpt': Icons.auto_awesome_rounded,
    'ai': Icons.auto_awesome_rounded,
    'discord_nitro': Icons.headset_mic_rounded,
    'crunchyroll': Icons.animation_rounded,
    'xbox': Icons.sports_esports_rounded,
    'slack': Icons.chat_rounded,
    'zoom': Icons.videocam_rounded,
    'github': Icons.code_rounded,
    'office_ms365': Icons.description_rounded,
    'google': Icons.search_rounded,
    'meta': Icons.public_rounded,

    // Other
    'passport': Icons.badge_rounded,
    'trash': Icons.delete_rounded,
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

    // Transport
    'bike': Colors.teal,
    'bus': Colors.blueAccent,
    'metro': Colors.indigoAccent,
    'courier': Colors.brown,

    // Utilities / Bills
    'electricity': Colors.amber,
    'gas': Colors.deepOrange,
    'wifi': Colors.cyan,
    'domain': Colors.indigo,
    'hosting': Colors.blueGrey,
    'antivirus': Colors.green,

    // Payment
    'credit_debit_card': Colors.deepPurple,
    'bank': Colors.blue,
    'banking': Colors.blue,

    // Subscription services
    'netflix': Color(0xFFE50914),
    'spotify': Color(0xFF1DB954),
    'youtube': Color(0xFFFF0000),
    'chatgpt': Color(0xFF10A37F),
    'ai': Color(0xFF7C4DFF),
    'discord_nitro': Color(0xFF5865F2),
    'crunchyroll': Color(0xFFF47521),
    'xbox': Color(0xFF107C10),
    'slack': Color(0xFF4A154B),
    'zoom': Color(0xFF2D8CFF),
    'github': Color(0xFF333333),
    'office_ms365': Color(0xFFD83B01),
    'google': Color(0xFF4285F4),
    'meta': Color(0xFF0668E1),

    // Other
    'passport': Colors.blueGrey,
    'trash': Colors.grey,
  };

  static const Map<String, String> _assetMap = {
    // Original categories
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

    // Transport
    'bike': 'assets/icons/bike_icon.png',
    'bus': 'assets/icons/bus_icon.png',
    'metro': 'assets/icons/metro_icon.png',
    'courier': 'assets/icons/courier_icon.png',

    // Utilities / Bills
    'electricity': 'assets/icons/electricity_icon.png',
    'gas': 'assets/icons/gas_icon.png',
    'wifi': 'assets/icons/wifi_icon.png',
    'domain': 'assets/icons/domain_icon.png',
    'hosting': 'assets/icons/hosting_icon.png',
    'antivirus': 'assets/icons/antivirus_icon.png',

    // Payment
    'credit_debit_card': 'assets/icons/credit_debit_card.png',
    'bank': 'assets/icons/icon_bank.png',
    'banking': 'assets/icons/icon_banking.png',

    // Subscription services
    'netflix': 'assets/icons/netflix_icon.png',
    'spotify': 'assets/icons/spotify_icon.png',
    'youtube': 'assets/icons/youtube_icon.png',
    'chatgpt': 'assets/icons/chatgpt_icon.png',
    'ai': 'assets/icons/ai_icon.png',
    'discord_nitro': 'assets/icons/discord_nitro_icon.png',
    'crunchyroll': 'assets/icons/crunchyrol_icon.png',
    'xbox': 'assets/icons/xbox_icon.png',
    'slack': 'assets/icons/slack_icon.png',
    'zoom': 'assets/icons/zoom_icon.png',
    'github': 'assets/icons/github_icon.png',
    'office_ms365': 'assets/icons/office_ms365_icon.png',
    'google': 'assets/icons/google.png',
    'meta': 'assets/icons/meta_icon.png',

    // Other
    'passport': 'assets/icons/passport_icon.png',
    'trash': 'assets/icons/trash_icon.png',
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

  /// Returns all available asset icon keys.
  static Map<String, String> getAllAssets() {
    return _assetMap;
  }
}
