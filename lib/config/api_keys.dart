import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Keys Configuration
/// Keys are loaded from .env file
class ApiKeys {
  // Google Maps Platform
  static String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Google Custom Search (for privacy scanner)
  static String get googleCustomSearchApiKey => 
      dotenv.env['GOOGLE_CUSTOM_SEARCH_API_KEY'] ?? '';
  static String get googleCustomSearchEngineId => 
      dotenv.env['GOOGLE_CUSTOM_SEARCH_ENGINE_ID'] ?? '';
  
  // Crime Data API (Optional - UK Police API doesn't need key)
  static String get crimeometerApiKey => 
      dotenv.env['CRIMEOMETER_API_KEY'] ?? '';
  
  // Have I Been Pwned (Optional - free tier doesn't need key)
  static String get haveibeenpwnedApiKey => 
      dotenv.env['HIBP_API_KEY'] ?? '';
  
  // OpenWeatherMap (Optional)
  static String get openWeatherApiKey => 
      dotenv.env['OPENWEATHER_API_KEY'] ?? '';
}

/// API Endpoints
class ApiEndpoints {
  // UK Police Crime Data (No key needed)
  static const String ukPoliceCrimeBase = 'https://data.police.uk/api';
  
  // Crimeometer (USA)
  static const String crimeometerBase = 'https://api.crimeometer.com/v1';
  
  // Have I Been Pwned
  static const String hibpBase = 'https://haveibeenpwned.com/api/v3';
  
  // Google APIs
  static const String googleMapsDirections = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String googlePlaces = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const String googleCustomSearch = 'https://www.googleapis.com/customsearch/v1';
  
  // OpenWeatherMap
  static const String openWeatherBase = 'https://api.openweathermap.org/data/2.5';
}
