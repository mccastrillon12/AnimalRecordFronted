import 'dart:typed_data';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds the Animal Record summary page that precedes the original file.
class SharedFilePdfBuilder {
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
          : 'Documentos Animal Record',
      author: 'Animal Record',
      subject: 'Resumen de paciente y tutor',
    );
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
    final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);

    for (final analysis in analyses) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 42, 40, 42),
          theme: theme,
          build: (_) => _summary(analysis, logo),
        ),
      );
    }
    return document.save();
  }

  pw.Widget _summary(SharedFileAnalysisEntity analysis, pw.MemoryImage? logo) {
    final tutor = analysis.pdfTutor ?? analysis.tutor;
    final patient = analysis.pdfPatient ?? analysis.patient;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _header(analysis, logo),
        pw.SizedBox(height: 14),
        pw.Divider(color: _divider, height: 1),
        pw.SizedBox(height: 16),
        if (tutor.hasData) ...[
          _partyHeading('Tutor', tutor.name),
          pw.SizedBox(height: 10),
          _detailsGrid([
            ('Identificación', tutor.identification),
            ('Número celular', tutor.phoneNumber),
            ('Correo', tutor.email),
            for (final detail in tutor.additionalDetails)
              (detail.label, detail.value),
          ], columns: 2),
          pw.SizedBox(height: 16),
        ],
        if (patient.hasData) ...[
          _partyHeading('Paciente', patient.name),
          pw.SizedBox(height: 10),
          _detailsGrid([
            ('AR ID', patient.recordId),
            ('Especie', patient.species),
            ('Sexo', patient.sex),
            ('Raza', patient.breed),
            ('Edad', patient.age),
            ('Peso', patient.weight),
            for (final detail in patient.additionalDetails)
              (detail.label, detail.value),
          ], columns: 3),
        ],
        pw.SizedBox(height: 14),
        pw.Divider(color: _divider, height: 1),
      ],
    );
  }

  pw.Widget _header(SharedFileAnalysisEntity analysis, pw.MemoryImage? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 180,
          height: 44,
          child: logo == null
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'AR',
                      style: pw.TextStyle(
                        color: _navy,
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'ANIMAL RECORD',
                      style: pw.TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : pw.Image(
                  logo,
                  fit: pw.BoxFit.contain,
                  alignment: pw.Alignment.centerLeft,
                ),
        ),
        pw.Spacer(),
        pw.RichText(
          textAlign: pw.TextAlign.right,
          text: pw.TextSpan(
            style: pw.TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
            children: [
              pw.TextSpan(text: analysis.documentType),
              if (analysis.documentNumber.trim().isNotEmpty)
                pw.TextSpan(
                  text: '  ${analysis.documentNumber.trim()}',
                  style: pw.TextStyle(
                    color: _secondary,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _partyHeading(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(color: _text, fontSize: 10.5),
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (value.trim().isNotEmpty)
            pw.TextSpan(
              text: value.trim(),
              style: pw.TextStyle(color: _blue, fontWeight: pw.FontWeight.bold),
            ),
        ],
      ),
    );
  }

  pw.Widget _detailsGrid(
    List<(String, String)> details, {
    required int columns,
  }) {
    final visible = details
        .where((detail) => detail.$2.trim().isNotEmpty)
        .toList(growable: false);
    if (visible.isEmpty) return pw.SizedBox.shrink();
    final rows = <pw.Widget>[];
    for (var index = 0; index < visible.length; index += columns) {
      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) pw.SizedBox(width: 14),
              pw.Expanded(
                child: index + column < visible.length
                    ? _detail(
                        visible[index + column].$1,
                        visible[index + column].$2,
                      )
                    : pw.SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
      if (index + columns < visible.length) rows.add(pw.SizedBox(height: 9));
    }
    return pw.Column(children: rows);
  }

  pw.Widget _detail(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(color: _text, fontSize: 9.5),
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(color: _secondary),
          ),
          pw.TextSpan(text: value.trim()),
        ],
      ),
    );
  }
}

String pdfSentenceLineBreaks(String value) => value;

bool isVaccinationPdfDocumentType(String documentType) {
  final normalized = documentType.trim().toLowerCase();
  return normalized.contains('vacunación') || normalized.contains('vacunacion');
}
