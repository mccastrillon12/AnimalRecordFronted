import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';

class MedicalFieldCatalogModel extends MedicalFieldCatalog {
  const MedicalFieldCatalogModel({
    required super.catalogVersion,
    required super.locale,
    required super.category,
    required super.categoryLabel,
    required super.sections,
    required super.fields,
    required super.hiddenTechnicalKeys,
  });

  factory MedicalFieldCatalogModel.fromJson(Map<String, dynamic> json) {
    String requiredText(String key) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw FormatException('El catálogo médico no contiene "$key".');
      }
      return value;
    }

    final sections = _maps(json['sections'])
        .map(
          (item) => MedicalFieldSection(
            key: _requiredText(item, 'key'),
            label: _requiredText(item, 'label'),
            order: _integer(item['order']),
          ),
        )
        .toList(growable: false);
    final sectionKeys = sections.map((section) => section.key).toSet();
    final fields = _maps(json['fields'])
        .map((item) {
          final sectionKey = _requiredText(item, 'sectionKey');
          if (!sectionKeys.contains(sectionKey)) {
            throw FormatException(
              'El campo ${item['path']} referencia una sección inexistente.',
            );
          }
          return MedicalFieldDefinition(
            path: _requiredText(item, 'path'),
            label: _requiredText(item, 'label'),
            sectionKey: sectionKey,
            order: _integer(item['order']),
            kind: MedicalFieldKind.parse(item['kind']),
            editable: item['editable'] == true,
            hideWhenEmpty: item['hideWhenEmpty'] != false,
            fallbackLabel: _nullableText(item['fallbackLabel']),
            columns: _maps(item['columns'])
                .map(
                  (column) => MedicalTableColumn(
                    key: _requiredText(column, 'key'),
                    label: _requiredText(column, 'label'),
                    order: _integer(column['order']),
                    kind: MedicalFieldKind.parse(column['kind']),
                    editable: column['editable'] == true,
                    hideWhenEmpty: column['hideWhenEmpty'] != false,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);

    return MedicalFieldCatalogModel(
      catalogVersion: requiredText('catalogVersion'),
      locale: requiredText('locale'),
      category: requiredText('category'),
      categoryLabel: requiredText('categoryLabel'),
      sections: List.unmodifiable(sections),
      fields: List.unmodifiable(fields),
      hiddenTechnicalKeys: Set.unmodifiable(
        _list(json['hiddenTechnicalKeys'])
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty),
      ),
    );
  }
}

List<Object?> _list(Object? value) => value is List ? value : const [];

Iterable<Map<String, dynamic>> _maps(Object? value) => _list(value).map((item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Elemento inválido en el catálogo médico.');
});

String _requiredText(Map<String, dynamic> values, String key) {
  final value = values[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw FormatException('El catálogo médico no contiene "$key".');
  }
  return value;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
