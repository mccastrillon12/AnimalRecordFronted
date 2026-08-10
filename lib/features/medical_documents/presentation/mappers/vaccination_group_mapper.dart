import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:equatable/equatable.dart';

class VaccinationApplicationViewData extends Equatable {
  final MedicalDocumentEntity document;
  final MedicalDocumentItemEntity vaccination;
  final String sourceName;
  final String applicationDate;
  final String nextDoseDate;
  final DateTime sortDate;

  const VaccinationApplicationViewData({
    required this.document,
    required this.vaccination,
    required this.sourceName,
    required this.applicationDate,
    required this.nextDoseDate,
    required this.sortDate,
  });

  @override
  List<Object?> get props => [
    document,
    vaccination,
    sourceName,
    applicationDate,
    nextDoseDate,
    sortDate,
  ];
}

class VaccinationGroupViewData extends Equatable {
  final String key;
  final String title;
  final List<VaccinationApplicationViewData> applications;

  const VaccinationGroupViewData({
    required this.key,
    required this.title,
    required this.applications,
  });

  VaccinationApplicationViewData get latest => applications.first;
  int get count => applications.length;

  String get searchText => [
    title,
    for (final application in applications) ...[
      application.sourceName,
      application.document.originalFileName,
      ...application.vaccination.fields.values.map(_valueText),
    ],
  ].join(' ').toLowerCase();

  @override
  List<Object?> get props => [key, title, applications];
}

class VaccinationDoseViewData extends Equatable {
  final String title;
  final MedicalDocumentEntity document;
  final String nextDoseDate;
  final List<SharedFileAnalysisDetailEntity> details;
  final SharedFileVeterinarianAnalysisEntity? veterinarian;
  final SharedFileTutorAnalysisEntity tutor;
  final SharedFilePatientAnalysisEntity patient;

  const VaccinationDoseViewData({
    required this.title,
    required this.document,
    required this.nextDoseDate,
    required this.details,
    this.veterinarian,
    required this.tutor,
    required this.patient,
  });

  @override
  List<Object?> get props => [
    title,
    document,
    nextDoseDate,
    details,
    veterinarian,
    tutor,
    patient,
  ];
}

class VaccinationDetailViewData extends Equatable {
  final String vaccineName;
  final List<VaccinationDoseViewData> doses;

  const VaccinationDetailViewData({
    required this.vaccineName,
    required this.doses,
  });

  @override
  List<Object?> get props => [vaccineName, doses];
}

VaccinationDetailViewData vaccinationDetailViewData(
  VaccinationGroupViewData group,
) {
  final doses = <VaccinationDoseViewData>[];
  for (var index = 0; index < group.applications.length; index++) {
    final application = group.applications[index];
    final analysis = medicalDocumentToPdfAnalysis(
      document: application.document,
    );
    doses.add(
      VaccinationDoseViewData(
        title: 'Dosis ${index + 1}',
        document: application.document,
        nextDoseDate: application.nextDoseDate,
        details: _doseDetails(application.vaccination.fields),
        veterinarian: analysis.veterinarian,
        tutor: analysis.tutor,
        patient: analysis.patient,
      ),
    );
  }
  return VaccinationDetailViewData(vaccineName: group.title, doses: doses);
}

SharedFileAnalysisEntity vaccinationGroupToPdfAnalysis(
  VaccinationGroupViewData group, {
  Map<String, String> originalUrls = const {},
}) {
  final detail = vaccinationDetailViewData(group);
  return SharedFileAnalysisEntity(
    documentType: 'Carné de vacunación',
    documentNumber: '',
    date: null,
    originalFileName: '',
    patient: const SharedFilePatientAnalysisEntity(
      name: '',
      recordId: '',
      species: '',
      breed: '',
      age: '',
      weight: '',
    ),
    tutor: const SharedFileTutorAnalysisEntity(
      name: '',
      identification: '',
      phoneNumber: '',
    ),
    itemsTitle: 'Vacuna ${detail.vaccineName}',
    medications: [
      for (var index = 0; index < detail.doses.length; index++)
        SharedFileMedicationAnalysisEntity(
          name: detail.doses[index].title,
          instructions: '',
          details: [
            if (detail.doses[index].nextDoseDate.isNotEmpty)
              SharedFileAnalysisDetailEntity(
                label: 'Próxima dosis',
                value: detail.doses[index].nextDoseDate,
              ),
            ..._tutorDetails(detail.doses[index].tutor),
            ..._patientDetails(detail.doses[index].patient),
            ...detail.doses[index].details,
            if (detail.doses[index].veterinarian case final veterinarian?) ...[
              if (veterinarian.name.trim().isNotEmpty)
                SharedFileAnalysisDetailEntity(
                  label: 'Veterinario',
                  value: veterinarian.name,
                ),
              if (veterinarian.clinic.trim().isNotEmpty)
                SharedFileAnalysisDetailEntity(
                  label: 'Veterinario - Clínica',
                  value: veterinarian.clinic,
                ),
              if (veterinarian.professionalId.trim().isNotEmpty)
                SharedFileAnalysisDetailEntity(
                  label: 'Veterinario - Registro profesional',
                  value: veterinarian.professionalId,
                ),
              for (final detail in veterinarian.additionalDetails)
                if (detail.hasData)
                  SharedFileAnalysisDetailEntity(
                    label: 'Veterinario - ${detail.label}',
                    value: detail.value,
                  ),
            ],
          ],
          originalUrl: originalUrls[detail.doses[index].document.id],
        ),
    ],
  );
}

SharedFileAnalysisEntity vaccinationGroupsToPdfAnalysis(
  List<VaccinationGroupViewData> groups, {
  required String documentType,
  required SharedFilePatientAnalysisEntity patient,
  required SharedFileTutorAnalysisEntity tutor,
  Map<String, String> originalUrls = const {},
}) {
  final orderedGroups = sortVaccinationGroupsByLatest(groups);
  return SharedFileAnalysisEntity(
    documentType: documentType,
    documentNumber: '',
    date: null,
    originalFileName: '',
    patient: patient,
    tutor: tutor,
    medications: [
      for (final group in orderedGroups)
        for (final dose in vaccinationDetailViewData(group).doses)
          SharedFileMedicationAnalysisEntity(
            name: dose.title,
            groupTitle: 'Vacuna ${group.title}',
            instructions: '',
            details: [
              if (dose.nextDoseDate.isNotEmpty)
                SharedFileAnalysisDetailEntity(
                  label: 'Próxima dosis',
                  value: dose.nextDoseDate,
                ),
              ...dose.details,
              if (dose.veterinarian case final veterinarian?) ...[
                if (veterinarian.name.trim().isNotEmpty)
                  SharedFileAnalysisDetailEntity(
                    label: 'Veterinario',
                    value: veterinarian.name,
                  ),
                if (veterinarian.clinic.trim().isNotEmpty)
                  SharedFileAnalysisDetailEntity(
                    label: 'Veterinario - Clínica',
                    value: veterinarian.clinic,
                  ),
                if (veterinarian.professionalId.trim().isNotEmpty)
                  SharedFileAnalysisDetailEntity(
                    label: 'Veterinario - Registro profesional',
                    value: veterinarian.professionalId,
                  ),
                for (final detail in veterinarian.additionalDetails)
                  if (detail.hasData)
                    SharedFileAnalysisDetailEntity(
                      label: 'Veterinario - ${detail.label}',
                      value: detail.value,
                    ),
              ],
            ],
            originalUrl: originalUrls[dose.document.id],
          ),
    ],
  );
}

List<VaccinationGroupViewData> sortVaccinationGroupsByLatest(
  Iterable<VaccinationGroupViewData> groups,
) {
  final ordered = groups.toList(growable: false);
  ordered.sort((left, right) {
    final dateComparison = right.latest.sortDate.compareTo(
      left.latest.sortDate,
    );
    return dateComparison != 0
        ? dateComparison
        : left.title.compareTo(right.title);
  });
  return ordered;
}

List<SharedFileAnalysisDetailEntity> _tutorDetails(
  SharedFileTutorAnalysisEntity tutor,
) => [
  if (tutor.name.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(label: 'Tutor', value: tutor.name),
  if (tutor.identification.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Tutor - Identificación',
      value: tutor.identification,
    ),
  if (tutor.phoneNumber.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Tutor - Número celular',
      value: tutor.phoneNumber,
    ),
  for (final detail in tutor.additionalDetails)
    if (detail.hasData)
      SharedFileAnalysisDetailEntity(
        label: 'Tutor - ${detail.label}',
        value: detail.value,
      ),
];

List<SharedFileAnalysisDetailEntity> _patientDetails(
  SharedFilePatientAnalysisEntity patient,
) => [
  if (patient.name.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(label: 'Paciente', value: patient.name),
  if (patient.recordId.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Animal Record ID',
      value: patient.recordId,
    ),
  if (patient.species.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Especie',
      value: patient.species,
    ),
  if (patient.breed.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Raza',
      value: patient.breed,
    ),
  if (patient.sex.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Sexo',
      value: patient.sex,
    ),
  if (patient.color.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Color',
      value: patient.color,
    ),
  if (patient.age.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Edad',
      value: patient.age,
    ),
  if (patient.weight.trim().isNotEmpty)
    SharedFileAnalysisDetailEntity(
      label: 'Paciente - Peso',
      value: patient.weight,
    ),
  for (final detail in patient.additionalDetails)
    if (detail.hasData)
      SharedFileAnalysisDetailEntity(
        label: 'Paciente - ${detail.label}',
        value: detail.value,
      ),
];

List<VaccinationGroupViewData> groupVaccinations(
  List<MedicalDocumentEntity> documents,
) {
  final grouped = <String, List<VaccinationApplicationViewData>>{};
  final titles = <String, String>{};

  for (final document in documents) {
    final extraction = document.validatedExtraction;
    if (extraction == null) continue;
    for (final vaccination in extraction.vaccinations) {
      final sourceName = _vaccinationName(vaccination.fields);
      final identity = _vaccinationIdentity(sourceName, vaccination.fields);
      final applicationDate = _fieldValue(
        vaccination.fields,
        _applicationDateKeys,
      );
      final nextDoseDate = _fieldValue(vaccination.fields, _nextDoseDateKeys);
      final parsedApplicationDate = _parseFlexibleDate(applicationDate);
      final documentDate =
          document.updatedAt ??
          document.reviewedAt ??
          document.createdAt ??
          parseMedicalDocumentDate(extraction.documentDate) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      grouped
          .putIfAbsent(identity.key, () => [])
          .add(
            VaccinationApplicationViewData(
              document: document,
              vaccination: vaccination,
              sourceName: sourceName,
              applicationDate: _displayDate(applicationDate),
              nextDoseDate: _displayDate(nextDoseDate),
              sortDate: parsedApplicationDate ?? documentDate,
            ),
          );
      titles[identity.key] = identity.title;
    }
  }

  final result = grouped.entries
      .map((entry) {
        final applications = [...entry.value]
          ..sort((left, right) => right.sortDate.compareTo(left.sortDate));
        return VaccinationGroupViewData(
          key: entry.key,
          title: titles[entry.key]!,
          applications: applications,
        );
      })
      .toList(growable: false);
  result.sort((left, right) => left.title.compareTo(right.title));
  return result;
}

List<SharedFileAnalysisDetailEntity> _doseDetails(Map<String, dynamic> fields) {
  final details = <SharedFileAnalysisDetailEntity>[];
  final usedKeys = <String>{};
  for (final definition in _doseFieldDefinitions) {
    for (final entry in fields.entries) {
      final key = _normalizeKey(entry.key);
      if (usedKeys.contains(key) || !definition.keys.contains(key)) continue;
      final rawValue = _valueText(entry.value);
      if (rawValue.isEmpty) continue;
      details.add(
        SharedFileAnalysisDetailEntity(
          label: definition.label,
          value: definition.isDate ? _displayDate(rawValue) : rawValue,
        ),
      );
      usedKeys.add(key);
      break;
    }
  }

  for (final entry in fields.entries) {
    final key = _normalizeKey(entry.key);
    if (usedKeys.contains(key) ||
        _doseIgnoredKeys.contains(key) ||
        _nextDoseDateKeys.contains(key)) {
      continue;
    }
    final value = _valueText(entry.value);
    if (value.isEmpty) continue;
    details.add(
      SharedFileAnalysisDetailEntity(
        label: _displayFieldKey(entry.key),
        value: value,
      ),
    );
  }
  return details;
}

String _displayFieldKey(String value) {
  final separated = value
      .replaceAllMapped(
        RegExp(r'([a-záéíóúñ])([A-ZÁÉÍÓÚÑ])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (separated.isEmpty) return '';
  return '${separated[0].toUpperCase()}${separated.substring(1)}';
}

({String key, String title}) _vaccinationIdentity(
  String sourceName,
  Map<String, dynamic> fields,
) {
  final fromName = _knownVaccination(sourceName);
  if (fromName != null) return fromName;

  final coveredDiseases = _coveredDiseases(fields);
  final identities = coveredDiseases
      .map(_knownVaccination)
      .whereType<({String key, String title})>()
      .toSet();
  if (identities.length == 1) return identities.single;
  if (identities.length > 1) {
    return (key: 'multiple_canine', title: 'Vacuna múltiple canina');
  }

  final fallback = sourceName.trim().isNotEmpty ? sourceName.trim() : 'Vacuna';
  return (key: _normalize(fallback), title: fallback);
}

({String key, String title})? _knownVaccination(String value) {
  final normalized = _normalize(value);
  if (normalized.isEmpty) return null;
  if (_containsAny(normalized, const ['rabies', 'rabia'])) {
    return (key: 'rabies', title: 'Rabia');
  }
  if (_containsAny(normalized, const ['distemper', 'moquillo'])) {
    return (key: 'distemper', title: 'Moquillo canino');
  }
  if (_containsAny(normalized, const ['parvovirus', 'parvo', 'parvovirosis'])) {
    return (key: 'parvovirus', title: 'Parvovirus');
  }
  if (_containsAny(normalized, const ['leptospirosis', 'lepto'])) {
    return (key: 'leptospirosis', title: 'Leptospirosis');
  }
  if (_containsAny(normalized, const [
    'bordetella',
    'kennel cough',
    'tos de las perreras',
  ])) {
    return (key: 'bordetella', title: 'Bordetella');
  }
  if (_containsAny(normalized, const [
    'canine hepatitis',
    'hepatitis canina',
    'adenovirus',
  ])) {
    return (key: 'canine_hepatitis', title: 'Hepatitis canina');
  }
  if (_containsAny(normalized, const ['parainfluenza'])) {
    return (key: 'parainfluenza', title: 'Parainfluenza');
  }
  if (_containsAny(normalized, const ['feline leukemia', 'leucemia felina']) ||
      normalized == 'felv') {
    return (key: 'feline_leukemia', title: 'Leucemia felina');
  }
  if (_containsAny(normalized, const ['panleukopenia', 'panleucopenia'])) {
    return (key: 'panleukopenia', title: 'Panleucopenia felina');
  }
  if (_containsAny(normalized, const ['calicivirus'])) {
    return (key: 'calicivirus', title: 'Calicivirus felino');
  }
  if (_containsAny(normalized, const [
    'rhinotracheitis',
    'rinotraqueitis',
    'herpesvirus',
  ])) {
    return (key: 'rhinotracheitis', title: 'Rinotraqueítis felina');
  }
  if (_containsAny(normalized, const [
    'fvrcp',
    'triple feline',
    'triple felina',
  ])) {
    return (key: 'feline_core', title: 'Triple felina');
  }
  if (_containsAny(normalized, const [
    'dhpp',
    'dapp',
    'da2pp',
    'multiple canine',
    'multiple canina',
  ])) {
    return (key: 'multiple_canine', title: 'Vacuna múltiple canina');
  }
  return null;
}

String _vaccinationName(Map<String, dynamic> fields) {
  return _fieldValue(fields, const {
    'name',
    'vaccinename',
    'vaccine',
    'nombre',
    'nombrevacuna',
  });
}

List<String> _coveredDiseases(Map<String, dynamic> fields) {
  for (final entry in fields.entries) {
    if (!_coveredDiseaseKeys.contains(_normalizeKey(entry.key))) continue;
    final value = entry.value;
    if (value is Iterable) {
      return value.map(_valueText).where((item) => item.isNotEmpty).toList();
    }
    final text = _valueText(value);
    if (text.isEmpty) return const [];
    return text.split(RegExp(r'[,;/]')).map((item) => item.trim()).toList();
  }
  return const [];
}

String _fieldValue(Map<String, dynamic> fields, Set<String> acceptedKeys) {
  for (final entry in fields.entries) {
    if (!acceptedKeys.contains(_normalizeKey(entry.key))) continue;
    final value = _valueText(entry.value).trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _displayDate(String value) {
  final parsed = _parseFlexibleDate(value);
  return parsed == null ? value.trim() : formatMedicalDocumentDate(parsed);
}

DateTime? _parseFlexibleDate(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed;

  final normalized = _normalize(raw);
  final namedMonth = RegExp(
    r'^(?:[a-z]+,?\s+)?([a-z]+)\s+(\d{1,2}),?\s+(\d{4})$',
  ).firstMatch(normalized);
  if (namedMonth != null) {
    final month = _englishMonths[namedMonth.group(1)];
    if (month != null) {
      return DateTime(
        int.parse(namedMonth.group(3)!),
        month,
        int.parse(namedMonth.group(2)!),
      );
    }
  }

  final numeric = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2}|\d{4})$',
  ).firstMatch(normalized);
  if (numeric != null) {
    final first = int.parse(numeric.group(1)!);
    final second = int.parse(numeric.group(2)!);
    final year = _fourDigitYear(numeric.group(3)!);
    final month = first > 12 ? second : first;
    final day = first > 12 ? first : second;
    if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      return DateTime(year, month, day);
    }
  }
  return parseMedicalDocumentDate(raw);
}

int _fourDigitYear(String value) {
  final parsed = int.parse(value);
  if (value.length == 4) return parsed;
  return parsed >= 70 ? 1900 + parsed : 2000 + parsed;
}

String _valueText(Object? value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value.map(_valueText).where((item) => item.isNotEmpty).join(', ');
  }
  if (value is Map) {
    return value.values
        .map(_valueText)
        .where((item) => item.isNotEmpty)
        .join(', ');
  }
  return value.toString().trim();
}

bool _containsAny(String value, List<String> aliases) =>
    aliases.any((alias) => value.contains(alias));

String _normalizeKey(String value) =>
    _normalize(value).replaceAll(RegExp(r'[^a-z0-9]'), '');

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const _applicationDateKeys = {
  'applicationdate',
  'dateofapplication',
  'administrationdate',
  'dateadministered',
  'administereddate',
  'vaccinationdate',
  'lastapplication',
  'lastapplicationdate',
  'fechaaplicacion',
  'fechadeaplicacion',
  'ultimaaplicacion',
  'fechavacunacion',
};

const _nextDoseDateKeys = {
  'nextdose',
  'nextdosedate',
  'nextvaccinationdate',
  'duedate',
  'boosterdue',
  'boosterduedate',
  'proximadosis',
  'fechaproximadosis',
  'fechasiguientedosis',
};

const _coveredDiseaseKeys = {
  'diseasescovered',
  'diseasecovered',
  'enfermedadescubiertas',
  'enfermedadprevenida',
  'prevents',
  'prevention',
};

const _doseIgnoredKeys = {
  'name',
  'vaccinename',
  'vaccine',
  'nombre',
  'nombrevacuna',
};

const _doseFieldDefinitions = <({String label, Set<String> keys, bool isDate})>[
  (label: 'Fecha', keys: _applicationDateKeys, isDate: true),
  (label: 'Marca', keys: {'brand', 'marca'}, isDate: false),
  (label: 'Fabricante', keys: {'manufacturer', 'fabricante'}, isDate: false),
  (
    label: '# Lote',
    keys: {'lot', 'lotnumber', 'batch', 'batchnumber', 'lote', 'numerolote'},
    isDate: false,
  ),
  (
    label: 'Pto. aplicación',
    keys: {
      'applicationsite',
      'administrationsite',
      'injectionsite',
      'sitioaplicacion',
      'puntoaplicacion',
    },
    isDate: false,
  ),
  (
    label: 'F. de vencimiento',
    keys: {
      'expirationdate',
      'expirydate',
      'lotexpirationdate',
      'fechavencimiento',
      'fechadeexpiracion',
    },
    isDate: true,
  ),
  (
    label: 'Etiqueta',
    keys: {'label', 'labelurl', 'etiqueta', 'etiquetaurl'},
    isDate: false,
  ),
  (
    label: 'Observaciones',
    keys: {'observations', 'observation', 'notes', 'observaciones', 'notas'},
    isDate: false,
  ),
];

const _englishMonths = {
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
};
