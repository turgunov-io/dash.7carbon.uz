class ContactModel {
  const ContactModel({
    this.id,
    this.phoneNumber,
    this.address,
    this.description,
    this.email,
    this.workSchedule,
  });

  final int? id;
  final String? phoneNumber;
  final String? address;
  final String? description;
  final String? email;
  final String? workSchedule;

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: _asInt(json['id']),
      phoneNumber: _normalizeText(json['phone_number']),
      address: _normalizeText(json['address']),
      description: _normalizeText(json['description']),
      email: _normalizeText(json['email']),
      workSchedule: _normalizeText(json['work_schedule']),
    );
  }

  ContactModel copyWith({
    int? id,
    String? phoneNumber,
    String? address,
    String? description,
    String? email,
    String? workSchedule,
  }) {
    return ContactModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      description: description ?? this.description,
      email: email ?? this.email,
      workSchedule: workSchedule ?? this.workSchedule,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'phone_number': _normalizeText(phoneNumber),
      'address': _normalizeText(address),
      'description': _normalizeText(description),
      'email': _normalizeText(email),
      'work_schedule': _normalizeText(workSchedule),
    };
  }

  Map<String, dynamic> toRequestBody({bool includeNullFields = true}) {
    final fields = <String, String?>{
      'phone_number': _normalizeText(phoneNumber),
      'address': _normalizeText(address),
      'description': _normalizeText(description),
      'email': _normalizeText(email),
      'work_schedule': _normalizeText(workSchedule),
    };

    if (includeNullFields) {
      return Map<String, dynamic>.from(fields);
    }

    return <String, dynamic>{
      for (final entry in fields.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }

  static String? _normalizeText(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString().trim());
  }
}
