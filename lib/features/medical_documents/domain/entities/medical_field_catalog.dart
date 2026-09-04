import 'package:equatable/equatable.dart';

enum MedicalFieldKind {
  text('TEXT'),
  longText('LONG_TEXT'),
  date('DATE'),
  list('LIST'),
  table('TABLE'),
  dynamicObject('DYNAMIC_OBJECT');

  final String wireValue;

  const MedicalFieldKind(this.wireValue);

  static MedicalFieldKind parse(Object? value) {
    final wireValue = value?.toString().trim().toUpperCase();
    return values.firstWhere(
      (kind) => kind.wireValue == wireValue,
      orElse: () => throw FormatException(
        'Tipo de campo médico no soportado: ${value ?? 'vacío'}.',
      ),
    );
  }
}

class MedicalFieldCatalog extends Equatable {
  final String catalogVersion;
  final String locale;
  final String category;
  final String categoryLabel;
  final List<MedicalFieldSection> sections;
  final List<MedicalFieldDefinition> fields;
  final Set<String> hiddenTechnicalKeys;

  const MedicalFieldCatalog({
    required this.catalogVersion,
    required this.locale,
    required this.category,
    required this.categoryLabel,
    required this.sections,
    required this.fields,
    required this.hiddenTechnicalKeys,
  });

  MedicalFieldDefinition? fieldAt(String path) {
    for (final field in fields) {
      if (field.path == path) return field;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    catalogVersion,
    locale,
    category,
    categoryLabel,
    sections,
    fields,
    hiddenTechnicalKeys,
  ];
}

class MedicalFieldSection extends Equatable {
  final String key;
  final String label;
  final int order;

  const MedicalFieldSection({
    required this.key,
    required this.label,
    required this.order,
  });

  @override
  List<Object?> get props => [key, label, order];
}

class MedicalFieldDefinition extends Equatable {
  final String path;
  final String label;
  final String sectionKey;
  final int order;
  final MedicalFieldKind kind;
  final bool editable;
  final bool hideWhenEmpty;
  final List<MedicalTableColumn> columns;
  final String? fallbackLabel;

  const MedicalFieldDefinition({
    required this.path,
    required this.label,
    required this.sectionKey,
    required this.order,
    required this.kind,
    required this.editable,
    required this.hideWhenEmpty,
    this.columns = const [],
    this.fallbackLabel,
  });

  @override
  List<Object?> get props => [
    path,
    label,
    sectionKey,
    order,
    kind,
    editable,
    hideWhenEmpty,
    columns,
    fallbackLabel,
  ];
}

class MedicalTableColumn extends Equatable {
  final String key;
  final String label;
  final int order;
  final MedicalFieldKind kind;
  final bool editable;
  final bool hideWhenEmpty;

  const MedicalTableColumn({
    required this.key,
    required this.label,
    required this.order,
    required this.kind,
    required this.editable,
    required this.hideWhenEmpty,
  });

  @override
  List<Object?> get props => [key, label, order, kind, editable, hideWhenEmpty];
}
