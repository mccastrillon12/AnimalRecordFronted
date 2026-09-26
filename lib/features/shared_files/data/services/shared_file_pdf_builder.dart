import 'dart:typed_data';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SharedFilePdfBuilder {
  static const _bodySize = 10.5;
  static const _smallSize = 9.5;
  static const _headingSize = 13.0;
  static const _titleSize = 17.0;
  static const _sectionGap = 18.0;

  static final _navy = PdfColor.fromHex('#203B66');
  static final _text = PdfColor.fromHex('#2E3949');
  static final _secondary = PdfColor.fromHex('#A8AFBD');
  static final _blue = PdfColor.fromHex('#67C1FF');
  static final _divider = PdfColor.fromHex('#E8E9EC');

  Future<Uint8List> build({
    required SharedFileAnalysisEntity analysis,
    Uint8List? logoBytes,
  }) => buildMany(analyses: [analysis], logoBytes: logoBytes);

  Future<Uint8List> buildMany({
    required List<SharedFileAnalysisEntity> analyses,
    Uint8List? logoBytes,
  }) async {
    final document = pw.Document(
      title: analyses.length == 1
          ? analyses.single.documentType
          : 'Historias clínicas',
      author: 'Animal Record',
      subject: 'Documento médico veterinario',
    );
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
    final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);

    for (final analysis in analyses) {
      final firstPageIndex = document.document.pdfPageList.pages.length;
      var analysisPagesCount = 0;
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(56, 50, 56, 42),
          theme: theme,
          header: (_) => _pageHeader(analysis, logo),
          footer: (context) => _pageFooter(
            pageNumber: context.pageNumber - firstPageIndex,
            pagesCount: analysisPagesCount == 0 ? 1 : analysisPagesCount,
          ),
          build: (_) => _documentContent(analysis),
        ),
      );
      analysisPagesCount =
          document.document.pdfPageList.pages.length - firstPageIndex;
    }
    return document.save();
  }

  pw.Widget _pageHeader(
    SharedFileAnalysisEntity analysis,
    pw.MemoryImage? logo,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(
              width: 150,
              child: logo == null
                  ? pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AR',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        pw.Text(
                          'ANIMAL RECORD',
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ],
                    )
                  : pw.Image(
                      logo,
                      width: 145,
                      height: 55,
                      fit: pw.BoxFit.contain,
                      alignment: pw.Alignment.centerLeft,
                    ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    analysis.documentType,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: _titleSize,
                      fontWeight: pw.FontWeight.bold,
                      color: _text,
                    ),
                  ),
                  if (analysis.documentNumber.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      analysis.documentNumber,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: _smallSize,
                        color: _secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Divider(color: _divider, height: 1),
        pw.SizedBox(height: 12),
      ],
    );
  }

  List<pw.Widget> _documentContent(SharedFileAnalysisEntity analysis) {
    if (_isVaccinationCard(analysis)) {
      return _vaccinationDocumentContent(analysis);
    }
    final regularSections = analysis.sections
        .where((section) => !_isAdditionalInformation(section))
        .toList(growable: false);
    final additionalInformationSections = analysis.sections
        .where(_isAdditionalInformation)
        .toList(growable: false);
    final widgets = <pw.Widget>[
      if (analysis.date != null ||
          (analysis.sourceDateText?.trim().isNotEmpty ?? false))
        _singleDetail(
          _dateLabel(analysis.documentType),
          analysis.sourceDateText?.trim().isNotEmpty == true
              ? analysis.sourceDateText!.trim()
              : _formatDate(analysis.date!),
        ),
    ];

    final veterinarian = analysis.veterinarian;
    if (veterinarian?.hasData ?? false) {
      widgets.addAll([
        pw.SizedBox(height: 12),
        ..._personSection(
          label: 'Veterinario',
          name: veterinarian!.name,
          details: [
            ('Clínica', veterinarian.clinic),
            ('Tarjeta profesional', veterinarian.professionalId),
            for (final detail in veterinarian.additionalDetails)
              (detail.label, detail.value),
          ],
          columns: 2,
        ),
      ]);
    }
    if (analysis.tutor.hasData) {
      widgets.addAll([
        pw.SizedBox(height: 12),
        ..._personSection(
          label: 'Tutor',
          name: analysis.tutor.name,
          details: [
            ('Identificación', analysis.tutor.identification),
            ('Número celular', analysis.tutor.phoneNumber),
            for (final detail in analysis.tutor.additionalDetails)
              (detail.label, detail.value),
          ],
          columns: 2,
        ),
      ]);
    }
    if (analysis.patient.hasData) {
      widgets.addAll([
        pw.SizedBox(height: 12),
        ..._personSection(
          label: 'Paciente',
          name: analysis.patient.name,
          details: [
            ('AR ID', analysis.patient.recordId),
            ('Especie', analysis.patient.species),
            ('Raza', analysis.patient.breed),
            ('Sexo', analysis.patient.sex),
            ('Color', analysis.patient.color),
            ('Edad', analysis.patient.age),
            ('Peso', analysis.patient.weight),
            for (final detail in analysis.patient.additionalDetails)
              (detail.label, detail.value),
          ],
          columns: 2,
        ),
      ]);
    }

    if (widgets.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 14),
        pw.Divider(color: _divider, height: 1),
      ]);
    }

    for (final section in regularSections) {
      widgets.addAll(_analysisSection(section));
    }

    if (analysis.medications.isNotEmpty) {
      widgets.addAll([
        pw.NewPage(freeSpace: 110),
        pw.SizedBox(height: _sectionGap),
        _sectionTitle(analysis.itemsTitle ?? 'Información médica'),
        pw.SizedBox(height: 12),
      ]);
      for (var index = 0; index < analysis.medications.length; index++) {
        widgets.addAll(_medicalItem(analysis.medications[index]));
        if (index < analysis.medications.length - 1) {
          widgets.add(pw.SizedBox(height: 16));
        }
      }
    }

    if (analysis.observations?.trim().isNotEmpty ?? false) {
      widgets.addAll(
        _textSection('Observaciones', analysis.observations!.trim()),
      );
    }

    for (final section in additionalInformationSections) {
      widgets.addAll(_analysisSection(section));
    }
    return widgets;
  }

  List<pw.Widget> _vaccinationDocumentContent(
    SharedFileAnalysisEntity analysis,
  ) {
    final widgets = <pw.Widget>[];
    if (analysis.tutor.hasData) {
      widgets.addAll(
        _personSection(
          label: 'Tutor',
          name: analysis.tutor.name,
          details: [
            ('Identificación', analysis.tutor.identification),
            ('Número celular', analysis.tutor.phoneNumber),
            for (final detail in analysis.tutor.additionalDetails)
              (detail.label, detail.value),
          ],
          columns: 2,
        ),
      );
    }
    if (analysis.patient.hasData) {
      if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 14));
      widgets.addAll(
        _personSection(
          label: 'Paciente',
          name: analysis.patient.name,
          details: [
            ('AR ID', analysis.patient.recordId),
            ('Especie', analysis.patient.species),
            ('Raza', analysis.patient.breed),
            ('Sexo', analysis.patient.sex),
            ('Color', analysis.patient.color),
            ('Edad', analysis.patient.age),
            ('Peso', analysis.patient.weight),
            for (final detail in analysis.patient.additionalDetails)
              (detail.label, detail.value),
          ],
          columns: 2,
        ),
      );
    }
    if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 14));

    final nextDoseValues = analysis.sections
        .where((section) => _isVaccinationNextDoseLabel(section.title))
        .where((section) => section.body?.trim().isNotEmpty ?? false)
        .map(
          (section) => SharedFileAnalysisDetailEntity(
            label: section.title.trim(),
            value: section.body!.trim(),
          ),
        )
        .toList(growable: false);
    final fallbackNextDose = nextDoseValues.isEmpty
        ? null
        : nextDoseValues.first;

    String? previousVaccinationGroup;
    for (var index = 0; index < analysis.medications.length; index++) {
      final dose = analysis.medications[index];
      final vaccinationGroup = dose.groupTitle?.trim().isNotEmpty ?? false
          ? dose.groupTitle!.trim()
          : analysis.itemsTitle?.trim() ?? '';
      final startsVaccinationGroup =
          index == 0 || vaccinationGroup != previousVaccinationGroup;
      final doseTutorDetails = dose.details
          .where(_isVaccinationTutorDetail)
          .toList(growable: false);
      final dosePatientDetails = dose.details
          .where(_isVaccinationPatientDetail)
          .toList(growable: false);
      final tutorName = _vaccinationPartyName(doseTutorDetails, 'Tutor');
      final patientName = _vaccinationPartyName(dosePatientDetails, 'Paciente');
      final tutorValues = _vaccinationPartyValues(doseTutorDetails, 'Tutor');
      final patientValues = _vaccinationPartyValues(
        dosePatientDetails,
        'Paciente',
      );
      final doseNextValues = dose.details
          .where(
            (detail) =>
                detail.hasData && _isVaccinationNextDoseLabel(detail.label),
          )
          .toList(growable: false);
      final nextDose = startsVaccinationGroup
          ? doseNextValues.isNotEmpty
                ? doseNextValues.first
                : index == 0
                ? fallbackNextDose
                : null
          : null;
      final doseDetails = dose.details
          .where(
            (detail) =>
                detail.hasData &&
                !_isVaccinationVeterinarianDetail(detail) &&
                !_isVaccinationTutorDetail(detail) &&
                !_isVaccinationPatientDetail(detail) &&
                !_isVaccinationVisualDetail(detail) &&
                !_isVaccinationNextDoseLabel(detail.label),
          )
          .map((detail) => (detail.label, detail.value))
          .toList(growable: false);
      final veterinarianDetails = dose.details
          .where(_isVaccinationVeterinarianDetail)
          .toList(growable: false);
      final veterinarianNames = veterinarianDetails
          .where((detail) => detail.label == 'Veterinario')
          .map((detail) => detail.value)
          .toList(growable: false);
      final veterinarianName = veterinarianNames.isEmpty
          ? null
          : veterinarianNames.first;
      final veterinarianValues = veterinarianDetails
          .where((detail) => detail.label != 'Veterinario')
          .map(
            (detail) =>
                (detail.label.replaceFirst('Veterinario - ', ''), detail.value),
          )
          .toList(growable: false);
      widgets.addAll([
        // Keep vaccine/group headings with the first dose values.
        pw.NewPage(freeSpace: startsVaccinationGroup ? 170 : 110),
        if (index == 0)
          pw.SizedBox(height: 18)
        else ...[
          pw.SizedBox(height: startsVaccinationGroup ? 30 : 18),
          pw.Divider(color: _divider, height: 1),
          pw.SizedBox(height: startsVaccinationGroup ? 22 : 18),
        ],
        if (startsVaccinationGroup && vaccinationGroup.isNotEmpty) ...[
          _vaccinationGroupTitle(vaccinationGroup),
        ],
        if (nextDose != null) ...[
          pw.SizedBox(height: 10),
          _singleDetail(nextDose.label, nextDose.value),
        ],
        pw.SizedBox(height: 18),
        pw.Text(
          dose.name,
          style: pw.TextStyle(
            fontSize: _bodySize,
            fontWeight: pw.FontWeight.bold,
            color: _text,
          ),
        ),
        if (doseDetails.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          ..._vaccinationDetails(doseDetails),
        ],
        if (veterinarianName != null || veterinarianValues.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          ..._personSection(
            label: 'Veterinario',
            name: veterinarianName ?? '',
            details: veterinarianValues,
            columns: 2,
          ),
        ],
        if (tutorName != null || tutorValues.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          ..._personSection(
            label: 'Tutor',
            name: tutorName ?? '',
            details: tutorValues,
            columns: 2,
          ),
        ],
        if (patientName != null || patientValues.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          ..._personSection(
            label: 'Paciente',
            name: patientName ?? '',
            details: patientValues,
            columns: 2,
          ),
        ],
      ]);
      previousVaccinationGroup = vaccinationGroup;
    }
    return widgets;
  }

  pw.Widget _vaccinationDetailGrid(List<(String, String)> details) {
    final rows = <pw.TableRow>[];
    const columns = 3;
    for (var index = 0; index < details.length; index += columns) {
      rows.add(
        pw.TableRow(
          children: [
            for (var column = 0; column < columns; column++)
              index + column < details.length
                  ? pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 14, bottom: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            details[index + column].$1,
                            style: pw.TextStyle(
                              fontSize: _smallSize,
                              color: _secondary,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            pdfSentenceLineBreaks(details[index + column].$2),
                            style: pw.TextStyle(
                              fontSize: _smallSize,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    )
                  : pw.SizedBox(),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  List<pw.Widget> _vaccinationDetails(List<(String, String)> details) {
    final widgets = <pw.Widget>[];
    var compact = <(String, String)>[];
    void flushCompact() {
      if (compact.isEmpty) return;
      widgets.add(_vaccinationDetailGrid(compact));
      compact = [];
    }

    for (final detail in details) {
      if (_isLongDetail(detail)) {
        flushCompact();
        widgets.addAll([_flowingDetail(detail), pw.SizedBox(height: 12)]);
      } else {
        compact.add(detail);
      }
    }
    flushCompact();
    return widgets;
  }

  bool _isLongDetail((String, String) detail) =>
      pdfSentenceLineBreaks(detail.$2).contains('\n') || detail.$2.length > 140;

  bool _isVaccinationCard(SharedFileAnalysisEntity analysis) {
    return isVaccinationPdfDocumentType(analysis.documentType);
  }

  bool _isVaccinationVisualDetail(SharedFileAnalysisDetailEntity detail) {
    final label = detail.label.trim().toLowerCase();
    return label == 'etiqueta' ||
        label == 'label' ||
        label.contains('firma') ||
        label.contains('signature') ||
        label.contains('sello') ||
        label.contains('stamp') ||
        label.contains('seal');
  }

  bool _isVaccinationNextDoseLabel(String label) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return const {
      'nextdose',
      'nextdosedate',
      'nextvaccinationdate',
      'duedate',
      'boosterdue',
      'boosterduedate',
      'proximadosis',
      'fechaproximadosis',
      'fechasiguientedosis',
    }.contains(normalized);
  }

  bool _isVaccinationVeterinarianDetail(
    SharedFileAnalysisDetailEntity detail,
  ) =>
      detail.label == 'Veterinario' ||
      detail.label.startsWith('Veterinario - ');

  bool _isVaccinationTutorDetail(SharedFileAnalysisDetailEntity detail) =>
      detail.label == 'Tutor' || detail.label.startsWith('Tutor - ');

  bool _isVaccinationPatientDetail(SharedFileAnalysisDetailEntity detail) =>
      detail.label == 'Paciente' || detail.label.startsWith('Paciente - ');

  String? _vaccinationPartyName(
    List<SharedFileAnalysisDetailEntity> details,
    String label,
  ) {
    final names = details
        .where((detail) => detail.label == label && detail.hasData)
        .map((detail) => detail.value)
        .toList(growable: false);
    return names.isEmpty ? null : names.first;
  }

  List<(String, String)> _vaccinationPartyValues(
    List<SharedFileAnalysisDetailEntity> details,
    String label,
  ) => details
      .where((detail) => detail.label != label && detail.hasData)
      .map(
        (detail) => (detail.label.replaceFirst('$label - ', ''), detail.value),
      )
      .toList(growable: false);

  List<pw.Widget> _personSection({
    required String label,
    required String name,
    required List<(String, String)> details,
    required int columns,
  }) {
    final visible = details
        .where((detail) => detail.$2.trim().isNotEmpty)
        .toList(growable: false);
    return [
      pw.NewPage(freeSpace: 80),
      if (name.trim().isNotEmpty)
        pw.RichText(
          text: pw.TextSpan(
            style: pw.TextStyle(
              fontSize: _bodySize,
              fontWeight: pw.FontWeight.bold,
              color: _text,
            ),
            children: [
              pw.TextSpan(text: '$label '),
              pw.TextSpan(
                text: name,
                style: pw.TextStyle(color: _blue),
              ),
            ],
          ),
        ),
      if (name.trim().isNotEmpty && visible.isNotEmpty) pw.SizedBox(height: 10),
      ..._personDetails(visible, columns: columns),
    ];
  }

  List<pw.Widget> _personDetails(
    List<(String, String)> details, {
    required int columns,
  }) {
    final widgets = <pw.Widget>[];
    var compact = <(String, String)>[];
    void flushCompact() {
      if (compact.isEmpty) return;
      widgets.add(_detailGrid(compact, columns: columns));
      compact = [];
    }

    for (final detail in details) {
      if (_isLongDetail(detail)) {
        flushCompact();
        widgets.addAll([_flowingDetail(detail), pw.SizedBox(height: 8)]);
      } else {
        compact.add(detail);
      }
    }
    flushCompact();
    return widgets;
  }

  pw.Widget _detailGrid(
    List<(String, String)> details, {
    required int columns,
  }) {
    final rows = <pw.TableRow>[];
    for (var index = 0; index < details.length; index += columns) {
      rows.add(
        pw.TableRow(
          children: [
            for (var column = 0; column < columns; column++)
              index + column < details.length
                  ? _detailCell(details[index + column])
                  : pw.SizedBox(),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: {
        for (var index = 0; index < columns; index++)
          index: const pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.Widget _detailCell((String, String) detail) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 14, bottom: 8),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(fontSize: _smallSize, color: _text),
          children: [
            pw.TextSpan(
              text: '${detail.$1}  ',
              style: pw.TextStyle(color: _secondary),
            ),
            pw.TextSpan(text: pdfSentenceLineBreaks(detail.$2)),
          ],
        ),
      ),
    );
  }

  pw.Widget _singleDetail(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(fontSize: _bodySize, color: _text),
        children: [
          pw.TextSpan(
            text: '$label  ',
            style: pw.TextStyle(color: _secondary),
          ),
          pw.TextSpan(text: pdfSentenceLineBreaks(value)),
        ],
      ),
    );
  }

  List<pw.Widget> _analysisSection(SharedFileAnalysisSectionEntity section) {
    final details = section.details
        .where((detail) => detail.hasData)
        .map((detail) => (detail.label, detail.value))
        .toList(growable: false);
    final body = section.body?.trim() ?? '';
    return [
      // Reserve room for the heading and the first lines of its content.
      pw.NewPage(freeSpace: _sectionGap + _headingSize + 10 + 30),
      pw.SizedBox(height: _sectionGap),
      _sectionTitle(section.title),
      if (details.isNotEmpty || body.isNotEmpty) pw.SizedBox(height: 10),
      for (final detail in details) ...[
        // Direct MultiPage children can span pages; a table cell cannot split
        // a long narrative and would move it away from its heading.
        _flowingDetail(detail),
        pw.SizedBox(height: 8),
      ],
      if (details.isNotEmpty && body.isNotEmpty) pw.SizedBox(height: 6),
      if (body.isNotEmpty) _bodyText(body),
    ];
  }

  pw.Widget _flowingDetail((String, String) detail) {
    return pw.RichText(
      overflow: pw.TextOverflow.span,
      text: pw.TextSpan(
        style: pw.TextStyle(fontSize: _smallSize, color: _text),
        children: [
          pw.TextSpan(
            text: '${detail.$1}  ',
            style: pw.TextStyle(color: _secondary),
          ),
          pw.TextSpan(text: pdfSentenceLineBreaks(detail.$2)),
        ],
      ),
    );
  }

  List<pw.Widget> _medicalItem(SharedFileMedicationAnalysisEntity item) {
    return [
      pw.NewPage(freeSpace: 60),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('>', style: pw.TextStyle(color: _blue, fontSize: 12)),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              item.name,
              style: pw.TextStyle(
                fontSize: _bodySize,
                fontWeight: pw.FontWeight.bold,
                color: _text,
              ),
            ),
          ),
          if (item.quantity != null)
            pw.Text(
              'Dosis  x ${item.quantity}',
              style: pw.TextStyle(fontSize: _smallSize, color: _text),
            ),
        ],
      ),
      if (item.instructions.trim().isNotEmpty) ...[
        pw.SizedBox(height: 7),
        _bodyText(item.instructions.trim()),
      ],
      for (final detail in item.details.where((detail) => detail.hasData)) ...[
        pw.SizedBox(height: 8),
        _flowingDetail((detail.label, detail.value)),
      ],
    ];
  }

  List<pw.Widget> _textSection(String title, String value) {
    return [
      pw.NewPage(freeSpace: _sectionGap + _headingSize + 10 + 30),
      pw.SizedBox(height: _sectionGap),
      _sectionTitle(title),
      pw.SizedBox(height: 10),
      _bodyText(value),
    ];
  }

  pw.Widget _sectionTitle(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: _headingSize,
        fontWeight: pw.FontWeight.bold,
        color: _text,
      ),
    );
  }

  pw.Widget _vaccinationGroupTitle(String value) {
    const prefix = 'Vacuna ';
    final hasPrefix = value.toLowerCase().startsWith(prefix.toLowerCase());
    final vaccineName = hasPrefix ? value.substring(prefix.length).trim() : '';
    if (!hasPrefix || vaccineName.isEmpty) return _sectionTitle(value);
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          fontSize: _headingSize,
          fontWeight: pw.FontWeight.bold,
          color: _text,
        ),
        children: [
          const pw.TextSpan(text: prefix),
          pw.TextSpan(
            text: vaccineName,
            style: pw.TextStyle(color: _blue),
          ),
        ],
      ),
    );
  }

  pw.Widget _bodyText(String value) {
    return pw.Text(
      pdfSentenceLineBreaks(value),
      overflow: pw.TextOverflow.span,
      style: pw.TextStyle(fontSize: _bodySize, lineSpacing: 3, color: _text),
    );
  }

  pw.Widget _pageFooter({required int pageNumber, required int pagesCount}) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        '$pageNumber-$pagesCount',
        style: pw.TextStyle(fontSize: 8, color: _secondary),
      ),
    );
  }

  bool _isAdditionalInformation(SharedFileAnalysisSectionEntity section) {
    final title = section.title.trim().toLowerCase();
    return title == 'información adicional' || title == 'informacion adicional';
  }

  String _dateLabel(String documentType) {
    final normalized = documentType.toLowerCase();
    return normalized.contains('remisi') ? 'Fecha de emisión' : 'Fecha';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Adds display-only sentence breaks without splitting decimals or URLs.
String pdfSentenceLineBreaks(String value) =>
    value.replaceAll(RegExp(r'\.[ \t\u00A0]+(?=\S)'), '.\n');

bool isVaccinationPdfDocumentType(String documentType) {
  final normalized = documentType
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized == 'carne de vacunacion' ||
      normalized == 'carnet de vacunacion' ||
      normalized == 'certificado de vacunacion';
}
