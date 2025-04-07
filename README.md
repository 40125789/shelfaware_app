# ShelfAware

ShelfAware is a Flutter-based mobile app designed to help users manage their food inventory, track expiration dates, donate surplus food to local communities, and reduce food waste. It provides an intuitive user interface for users to view food expiry dates, track donations, and receive push notifications when items are about to expire.

## Features

- **Track Food Expiry:** Keep track of the expiry dates of food items and receive notifications before they expire.
- **Donate Surplus Food:** Easily donate surplus food to people in your local area.
- **Donation Map:** View donation locations on a map for easy collection.
- **Push Notifications:** Get notified when items are about to expire.
- **Monthly Food Stats:** The app helps users monitor their food waste reduction progress through visual statistics and actionable insights.

## Tech Stack

- **Flutter:** For building the cross-platform mobile app.
- **Firebase:** For real-time database and push notifications.
- **Google Maps API:** For displaying maps and donation markers.
- **Mapbox API:** For searching and geocoding addresses
- **Spoonacular API:** Used for retrieving recipes based on the user's ingredients and providing cooking instructions.
- **Open Food Facts API:** Used for retrieving food details from barcodes.

## Installation

### Clone the repository:
```bash
git clone https://github.com/40125789/shelfaware_app.git
```

## Run Locally

1. Go to the project directory
```bash
cd your_project
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## App Manual

For detailed instructions on how to use ShelfAware, please refer to the [User Manual](file:///C:/Users/Smyth/OneDrive/Documents/Dissertation/ShelfAware%20User%20Manual%20(PDF).pdf).


## Environment Variables

Create a `.env` file in the root directory and add:

```bash
SPOONACULAR_API_KEY=your_api_key_here
GOOGLE_MAPS_API_KEY=your_other_api_key_here
```

> **Note:** Do not commit your .env file. Add it to .gitignore.

## Contributing

Thank you for your interest in contributing to **ShelfAware**! 🎉

### How You Can Contribute

- 🐛 Report bugs
- 💡 Suggest new features
- 🧪 Write tests
- 🛠️ Fix bugs
- 🧹 Refactor code
- 📝 Improve documentation

### Getting Started

1. Fork the repository
2. Clone your fork:
```bash
git clone https://github.com/your-username/shelfaware_app.git
cd shelfaware_app
```

## Acknowledgements 🙏

This project uses these open-source Flutter packages:

### Firebase
- firebase_core
- firebase_auth
- cloud_firestore
- firebase_storage
- firebase_messaging
- cloud_functions
- firebase_app_check

### UI & Design
- flutter_slidable
- flutter_swipe_action_cell
- lottie
- cupertino_icons
- google_nav_bar
- flutter_launcher_icons
- badges
- fancy_bottom_navigation
- curved_navigation_bar

### Location & Maps
- google_maps_flutter
- google_maps_webservice
- geolocator
- location
- geocoding
- latlong2

### Other Components
- flutter_dotenv
- provider
- hive
- intl
- barcode_scan2
- camera
- google_ml_kit

Special thanks to my supervisor Leo Galway for guidance throughout this project.
