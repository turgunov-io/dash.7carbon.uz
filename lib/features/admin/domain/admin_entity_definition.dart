import 'package:flutter/material.dart';

enum AdminFieldType { text, multiline, number, boolean, array, json, dateTime }

class AdminFieldDefinition {
  const AdminFieldDefinition({
    required this.key,
    required this.label,
    this.required = false,
    this.nullable = true,
    this.type = AdminFieldType.text,
    this.showInList = true,
    this.editable = true,
    this.width = 220,
  });

  final String key;
  final String label;
  final bool required;
  final bool nullable;
  final AdminFieldType type;
  final bool showInList;
  final bool editable;
  final double width;
}

class AdminEntityDefinition {
  const AdminEntityDefinition({
    required this.key,
    required this.title,
    required this.endpoint,
    required this.icon,
    required this.fields,
    this.searchFields = const <String>[],
    this.listFieldKeys = const <String>[],
  });

  final String key;
  final String title;
  final String endpoint;
  final IconData icon;
  final List<AdminFieldDefinition> fields;
  final List<String> searchFields;
  final List<String> listFieldKeys;

  List<AdminFieldDefinition> get listFields {
    if (listFieldKeys.isNotEmpty) {
      final map = {for (final field in fields) field.key: field};
      return listFieldKeys
          .map((key) => map[key])
          .whereType<AdminFieldDefinition>()
          .toList(growable: false);
    }
    return fields.where((field) => field.showInList).toList(growable: false);
  }

  List<AdminFieldDefinition> get formFields {
    return fields
        .where(
          (field) =>
              field.editable &&
              field.key != 'id' &&
              !(key == 'about_metrics' && field.key == 'metric_key'),
        )
        .toList(growable: false);
  }
}
