import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_display_formatter.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:equatable/equatable.dart';

String vaccinationDisplayName(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return normalized;
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

class VaccinationApplicationViewData extends Equatable {
  final MedicalDocumentEntity document;
  final MedicalDocumentItemEntity vaccination;
  final String sourceName;
  final String applicationDate;
  final String applicationDateLabel;
  final String nextDoseDate;
  final String nextDoseDateLabel;
  final DateTime sortDate;

  const VaccinationApplicationViewData({
    required this.document,
    required this.vaccination,
    required this.sourceName,
    required this.applicationDate,
    required this.applicationDateLabel,
    required this.nextDoseDate,
    required this.nextDoseDateLabel,
    required this.sortDate,
  });

  @override
  List<Object?> get props => [
    document,
    vaccination,
    sourceName,
    applicationDate,
    applicationDateLabel,
    nextDoseDate,
    nextDoseDateLabel,
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
  final String nextDoseDateLabel;
  final List<SharedFileAnalysisDetailEntity> details;
  final SharedFileVeterinarianAnalysisEntity? veterinarian;
  final SharedFileTutorAnalysisEntity tutor;
  final SharedFilePatientAnalysisEntity patient;

  const VaccinationDoseViewData({
    required this.title,
    required this.document,
    required this.nextDoseDate,
    required this.nextDoseDateLabel,
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
    nextDoseDateLabel,
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
  MedicalFieldCatalog catalog,
) {
  final doses = <VaccinationDoseViewData>[];
  for (var index = 0; index < group.applications.length; index++) {
    final application = group.applications[index];
    final extraction = application.document.validatedExtraction;
    doses.add(
      VaccinationDoseViewData(
        title: 'Dosis ${index + 1}',
        document: application.document,
        nextDoseDate: application.nextDoseDate,
        nextDoseDateLabel: application.nextDoseDateLabel,
        details: _doseDetails(application.vaccination.fields, catalog),
        veterinarian: _vaccinationVeterinarian(extraction?.issuer),
        tutor: _vaccinationTutor(extraction?.owner),
        patient: _vaccinationPatient(extraction?.patient),
      ),
    );
  }
  return VaccinationDetailViewData(vaccineName: group.title, doses: doses);
}

SharedFileAnalysisEntity vaccinationGroupToPdfAnalysis(
  VaccinationGroupViewData group,
  MedicalFieldCatalog catalog, {
  Map<String, String> originalUrls = const {},
}) {
  final detail = vaccinationDetailViewData(group, catalog);
  return SharedFileAnalysisEntity(
    documentType: MedicalDocumentCategory.vaccinationCard.label,
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
                label: detail.doses[index].nextDoseDateLabel,
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
  required MedicalFieldCatalog catalog,
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
        for (final dose in vaccinationDetailViewData(group, catalog).doses)
          SharedFileMedicationAnalysisEntity(
            name: dose.title,
            groupTitle: 'Vacuna ${group.title}',
            instructions: '',
            details: [
              if (dose.nextDoseDate.isNotEmpty)
                SharedFileAnalysisDetailEntity(
                  label: dose.nextDoseDateLabel,
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
  MedicalFieldCatalog catalog,
) {
  final grouped = <String, List<VaccinationApplicationViewData>>{};

  for (final document in documents) {
    final extraction = document.validatedExtraction;
    if (extraction == null) continue;
    for (final vaccination in extraction.vaccinations) {
      final sourceName = _vaccinationName(vaccination.fields);
      final identity = _vaccinationIdentity(sourceName, vaccination.fields);
      final applicationDate = _fieldEntry(
        vaccination.fields,
        _applicationDateKeys,
      );
      final nextDoseDate = _fieldEntry(vaccination.fields, _nextDoseDateKeys);
      final parsedApplicationDate = _parseFlexibleDate(applicationDate.value);
      final documentDate =
          document.updatedAt ??
          document.reviewedAt ??
          document.createdAt ??
          parseMedicalDocumentDate(extraction.documentDate) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      grouped
          .putIfAbsent(identity, () => [])
          .add(
            VaccinationApplicationViewData(
              document: document,
              vaccination: vaccination,
              sourceName: sourceName,
              applicationDate: applicationDate.value,
              applicationDateLabel: _vaccinationColumnLabel(
                catalog,
                applicationDate.key,
              ),
              nextDoseDate: nextDoseDate.value,
              nextDoseDateLabel: _vaccinationColumnLabel(
                catalog,
                nextDoseDate.key,
              ),
              sortDate: parsedApplicationDate ?? documentDate,
            ),
          );
    }
  }

  final result = grouped.entries
      .map((entry) {
        final applications = [...entry.value]
          ..sort((left, right) => right.sortDate.compareTo(left.sortDate));
        return VaccinationGroupViewData(
          key: entry.key,
          title: applications.first.sourceName,
          applications: applications,
        );
      })
      .toList(growable: false);
  result.sort((left, right) => left.title.compareTo(right.title));
  return result;
}

List<SharedFileAnalysisDetailEntity> _doseDetails(
  Map<String, dynamic> fields,
  MedicalFieldCatalog catalog,
) {
  final details = <SharedFileAnalysisDetailEntity>[];
  final columns = [...?catalog.fieldAt('vaccinations')?.columns]
    ..sort((left, right) => left.order.compareTo(right.order));
  for (final column in columns) {
    final key = _normalizeKey(column.key);
    if (isMedicalDocumentTechnicalKey(
          column.key,
          catalog.hiddenTechnicalKeys,
        ) ||
        _doseIgnoredKeys.contains(key) ||
        _nextDoseDateKeys.contains(key)) {
      continue;
    }
    final value = medicalDocumentDisplayValue(
      fields[column.key],
      hiddenTechnicalKeys: catalog.hiddenTechnicalKeys,
    );
    if (value.isEmpty) continue;
    details.add(
      SharedFileAnalysisDetailEntity(label: column.label, value: value),
    );
  }
  return details;
}

String _vaccinationColumnLabel(MedicalFieldCatalog catalog, String key) {
  if (key.isEmpty ||
      isMedicalDocumentTechnicalKey(key, catalog.hiddenTechnicalKeys)) {
    return '';
  }
  final field = catalog.fieldAt('vaccinations');
  for (final column in field?.columns ?? const <MedicalTableColumn>[]) {
    if (column.key == key) return column.label;
  }
  return '';
}

const _emptyPatient = SharedFilePatientAnalysisEntity(
  name: '',
  recordId: '',
  species: '',
  breed: '',
  age: '',
  weight: '',
);

const _emptyTutor = SharedFileTutorAnalysisEntity(
  name: '',
  identification: '',
  phoneNumber: '',
);

SharedFilePatientAnalysisEntity _vaccinationPatient(
  MedicalDocumentPatientEntity? patient,
) {
  if (patient == null) return _emptyPatient;
  String field(String key, String? fallback) =>
      patient.fields[key]?.trim() ?? fallback?.trim() ?? '';
  return SharedFilePatientAnalysisEntity(
    name: field('name', patient.name),
    recordId: field('identifier', patient.identifier),
    species: field('species', patient.species),
    breed: field('breed', patient.breed),
    sex: field('sex', patient.sex),
    color: field('color', patient.color),
    age: field('age', patient.age),
    weight: field('weight', patient.weight),
  );
}

SharedFileTutorAnalysisEntity _vaccinationTutor(
  MedicalDocumentOwnerEntity? owner,
) {
  if (owner == null) return _emptyTutor;
  return SharedFileTutorAnalysisEntity(
    name: owner.name?.trim() ?? '',
    identification: owner.identification?.trim() ?? '',
    phoneNumber: owner.phone?.trim() ?? '',
    additionalDetails: [
      if (owner.email?.trim().isNotEmpty == true)
        SharedFileAnalysisDetailEntity(
          label: 'Correo electrónico',
          value: owner.email!.trim(),
        ),
      if (owner.address?.trim().isNotEmpty == true)
        SharedFileAnalysisDetailEntity(
          label: 'Dirección',
          value: owner.address!.trim(),
        ),
    ],
  );
}

SharedFileVeterinarianAnalysisEntity? _vaccinationVeterinarian(
  Map<String, dynamic>? issuer,
) {
  if (issuer == null || issuer.isEmpty) return null;
  String value(String key) => issuer[key]?.toString().trim() ?? '';
  final result = SharedFileVeterinarianAnalysisEntity(
    name: value('name'),
    clinic: value('clinic'),
    professionalId: value('professionalId'),
  );
  return result.hasData ? result : null;
}

String _vaccinationIdentity(String sourceName, Map<String, dynamic> fields) {
  final fromName = _knownVaccination(sourceName);
  if (fromName != null) return fromName;

  final coveredDiseases = _coveredDiseases(fields);
  final identities = coveredDiseases
      .map(_knownVaccination)
      .whereType<String>()
      .toSet();
  if (identities.length == 1) return identities.single;
  if (identities.length > 1) return 'multiple_canine';

  return _normalize(sourceName);
}

String? _knownVaccination(String value) {
  final normalized = _normalize(value);
  if (normalized.isEmpty) return null;
  if (_containsAny(normalized, const ['rabies', 'rabia'])) {
    return 'rabies';
  }
  if (_containsAny(normalized, const ['distemper', 'moquillo'])) {
    return 'distemper';
  }
  if (_containsAny(normalized, const ['parvovirus', 'parvo', 'parvovirosis'])) {
    return 'parvovirus';
  }
  if (_containsAny(normalized, const ['leptospirosis', 'lepto'])) {
    return 'leptospirosis';
  }
  if (_containsAny(normalized, const [
    'bordetella',
    'kennel cough',
    'tos de las perreras',
  ])) {
    return 'bordetella';
  }
  if (_containsAny(normalized, const [
    'canine hepatitis',
    'hepatitis canina',
    'adenovirus',
  ])) {
    return 'canine_hepatitis';
  }
  if (_containsAny(normalized, const ['parainfluenza'])) {
    return 'parainfluenza';
  }
  if (_containsAny(normalized, const ['feline leukemia', 'leucemia felina']) ||
      normalized == 'felv') {
    return 'feline_leukemia';
  }
  if (_containsAny(normalized, const ['panleukopenia', 'panleucopenia'])) {
    return 'panleukopenia';
  }
  if (_containsAny(normalized, const ['calicivirus'])) {
    return 'calicivirus';
  }
  if (_containsAny(normalized, const [
    'rhinotracheitis',
    'rinotraqueitis',
    'herpesvirus',
  ])) {
    return 'rhinotracheitis';
  }
  if (_containsAny(normalized, const [
    'fvrcp',
    'triple feline',
    'triple felina',
  ])) {
    return 'feline_core';
  }
  if (_containsAny(normalized, const [
    'dhpp',
    'dapp',
    'da2pp',
    'multiple canine',
    'multiple canina',
  ])) {
    return 'multiple_canine';
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

({String key, String value}) _fieldEntry(
  Map<String, dynamic> fields,
  Set<String> acceptedKeys,
) {
  for (final entry in fields.entries) {
    if (!acceptedKeys.contains(_normalizeKey(entry.key))) continue;
    final value = _valueText(entry.value).trim();
    if (value.isNotEmpty) return (key: entry.key, value: value);
  }
  return (key: '', value: '');
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
