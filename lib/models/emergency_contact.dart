class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    this.isPrimary = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      relationship: json['relationship'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
