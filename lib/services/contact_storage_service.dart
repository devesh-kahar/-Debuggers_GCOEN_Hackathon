import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';

/// Manages saving/loading emergency contacts locally via SharedPreferences
class ContactStorageService {
  static final ContactStorageService _instance = ContactStorageService._internal();
  factory ContactStorageService() => _instance;
  ContactStorageService._internal();

  static const String _contactsKey = 'emergency_contacts';
  List<EmergencyContact> _contacts = [];
  bool _isLoaded = false;

  /// Load contacts from local storage
  Future<List<EmergencyContact>> loadContacts() async {
    if (_isLoaded) return _contacts;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_contactsKey);
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        _contacts = decoded.map((json) => EmergencyContact.fromJson(json)).toList();
      }
      _isLoaded = true;
    } catch (e) {
      print('Error loading contacts: $e');
    }
    return _contacts;
  }

  /// Save all contacts to local storage
  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_contacts.map((c) => c.toJson()).toList());
      await prefs.setString(_contactsKey, encoded);
    } catch (e) {
      print('Error saving contacts: $e');
    }
  }

  /// Add a new emergency contact
  Future<void> addContact(EmergencyContact contact) async {
    _contacts.add(contact);
    await _saveContacts();
  }

  /// Update an existing contact
  Future<void> updateContact(EmergencyContact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await _saveContacts();
    }
  }

  /// Delete a contact by id
  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await _saveContacts();
  }

  /// Set a contact as primary (and unset others)
  Future<void> setPrimaryContact(String id) async {
    _contacts = _contacts.map((c) {
      return c.copyWith(isPrimary: c.id == id);
    }).toList();
    await _saveContacts();
  }

  /// Get the primary contact (first one marked, or first contact)
  EmergencyContact? getPrimaryContact() {
    if (_contacts.isEmpty) return null;
    final primary = _contacts.where((c) => c.isPrimary).toList();
    return primary.isNotEmpty ? primary.first : _contacts.first;
  }

  /// Get all contacts
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  /// Check if any contacts are saved
  bool get hasContacts => _contacts.isNotEmpty;
}
