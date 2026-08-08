import 'dart:typed_data';

import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SharedFilePdfBuilder {
  static const _cardWidth = 342.0;
  static const _tableFontSize = 14.0;
  static const _gradientPadding = 10.0;
  static const _contentPadding = 24.0;
  static const _valueLabelWidth = 118.0;
  static const _valueColumnGap = 8.0;
  static const _fileNameValueWidth =
      _cardWidth -
      (_gradientPadding * 2) -
      (_contentPadding * 2) -
      _valueLabelWidth -
      _valueColumnGap;

  static final _gradientStart = PdfColor.fromHex('#E7E0FD');
  static final _gradientEnd = PdfColor.fromHex('#D9EAFF');
  static final _textColor = PdfColor.fromHex('#2E3949');
  static final _secondaryColor = PdfColor.fromHex('#A8AFBD');
  static final _blue = PdfColor.fromHex('#67C1FF');
  static final _linkBlue = PdfColor.fromHex('#0072BB');
  static final _divider = PdfColor.fromHex('#E8E9EC');

  Future<Uint8List> build({
    required SharedFileAnalysisEntity analysis,
    required String clipboardSvg,
  }) async {
    final document = pw.Document(
      title: analysis.documentType,
      author: 'Animal Record',
      subject: 'Documento médico veterinario',
    );
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
    final visibleFileName = _ellipsizeFileName(
      analysis.originalFileName,
      PdfFont.helvetica(document.document),
    );
    final measurementContext = pw.Context(
      document: document.document,
    ).inheritFrom(theme);
    final cardSize = pw.Widget.measure(
      _documentCard(analysis, clipboardSvg, visibleFileName),
      context: measurementContext,
      constraints: const pw.BoxConstraints.tightFor(width: _cardWidth),
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_cardWidth, cardSize.y),
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (_) => _documentCard(analysis, clipboardSvg, visibleFileName),
      ),
    );

    return document.save();
  }

  pw.Widget _documentCard(
    SharedFileAnalysisEntity analysis,
    String clipboardSvg,
    String visibleFileName,
  ) {
    return _gradientCard(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _documentHeader(analysis, clipboardSvg),
          if (analysis.date != null || visibleFileName.isNotEmpty) ...[
            pw.SizedBox(height: 28),
            if (analysis.date != null ||
                (analysis.sourceDateText?.trim().isNotEmpty ?? false))
              _valueRow(
                'Fecha',
                analysis.date != null
                    ? _formatDate(analysis.date!)
                    : analysis.sourceDateText!.trim(),
              ),
            if (analysis.date != null && visibleFileName.isNotEmpty)
              pw.SizedBox(height: 8),
            if (visibleFileName.isNotEmpty)
              _valueRow(
                'Archivo original',
                visibleFileName,
                valueColor: _linkBlue,
              ),
          ],
          if (analysis.patient.hasData) ...[
            _dividerWidget(),
            if (analysis.patient.name.isNotEmpty)
              _personTitle('Paciente', analysis.patient.name),
            ..._optionalRows([
              ('Animal Record ID', analysis.patient.recordId),
              ('Especie', analysis.patient.species),
              ('Raza', analysis.patient.breed),
              ('Sexo', analysis.patient.sex),
              ('Color', analysis.patient.color),
              ('Edad', analysis.patient.age),
              ('Peso', analysis.patient.weight),
              for (final detail in analysis.patient.additionalDetails)
                (detail.label, detail.value),
            ], hasTitle: analysis.patient.name.isNotEmpty),
          ],
          if (analysis.veterinarian?.hasData ?? false) ...[
            _dividerWidget(),
            if (analysis.veterinarian!.name.isNotEmpty)
              _personTitle('Veterinario', analysis.veterinarian!.name),
            ..._optionalRows([
              ('Clínica', analysis.veterinarian!.clinic),
              ('Registro profesional', analysis.veterinarian!.professionalId),
              for (final detail in analysis.veterinarian!.additionalDetails)
                (detail.label, detail.value),
            ], hasTitle: analysis.veterinarian!.name.isNotEmpty),
          ],
          if (analysis.tutor.hasData) ...[
            _dividerWidget(),
            if (analysis.tutor.name.isNotEmpty)
              _personTitle('Tutor', analysis.tutor.name),
            ..._optionalRows([
              ('Identificación', analysis.tutor.identification),
              ('Número celular', analysis.tutor.phoneNumber),
              for (final detail in analysis.tutor.additionalDetails)
                (detail.label, detail.value),
            ], hasTitle: analysis.tutor.name.isNotEmpty),
          ],
          if (analysis.medications.isNotEmpty ||
              (analysis.observations?.trim().isNotEmpty ?? false))
            _dividerWidget(),
          if (analysis.medications.isNotEmpty &&
              (analysis.itemsTitle?.trim().isNotEmpty ?? false)) ...[
            pw.Text(
              analysis.itemsTitle!,
              style: pw.TextStyle(
                fontSize: _tableFontSize,
                fontWeight: pw.FontWeight.bold,
                color: _textColor,
              ),
            ),
            pw.SizedBox(height: 16),
          ],
          for (var index = 0; index < analysis.medications.length; index++) ...[
            _medication(analysis.medications[index]),
            if (index < analysis.medications.length - 1)
              pw.SizedBox(height: 24),
          ],
          if (analysis.observations?.trim().isNotEmpty ?? false) ...[
            if (analysis.medications.isNotEmpty) pw.SizedBox(height: 28),
            _observations(analysis.observations!),
          ],
        ],
      ),
    );
  }

  pw.Widget _gradientCard({required pw.Widget child}) {
    return pw.Inseparable(
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(_gradientPadding),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Container(
          padding: const pw.EdgeInsets.all(_contentPadding),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }

  List<pw.Widget> _optionalRows(
    List<(String, String)> rows, {
    required bool hasTitle,
  }) {
    final visibleRows = rows
        .where((row) => row.$2.trim().isNotEmpty)
        .toList(growable: false);
    return [
      if (hasTitle && visibleRows.isNotEmpty) pw.SizedBox(height: 12),
      for (var index = 0; index < visibleRows.length; index++) ...[
        if (index > 0) pw.SizedBox(height: 8),
        _valueRow(visibleRows[index].$1, visibleRows[index].$2),
      ],
    ];
  }

  pw.Widget _documentHeader(
    SharedFileAnalysisEntity analysis,
    String clipboardSvg,
  ) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.SvgImage(svg: clipboardSvg, width: 24, height: 24),
          pw.SizedBox(height: 8),
          pw.Text(
            analysis.documentType,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          if (analysis.documentNumber.trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              analysis.documentNumber,
              style: pw.TextStyle(fontSize: 12, color: _secondaryColor),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _valueRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: _valueLabelWidth,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: _tableFontSize,
              color: _secondaryColor,
            ),
          ),
        ),
        pw.SizedBox(width: _valueColumnGap),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: _tableFontSize,
              color: valueColor ?? _textColor,
            ),
          ),
        ),
      ],
    );
  }

  String _ellipsizeFileName(String value, PdfFont font) {
    double widthOf(String text) =>
        font.stringMetrics(text).width * _tableFontSize;

    if (widthOf(value) <= _fileNameValueWidth) return value;

    const suffix = '...';
    var low = 0;
    var high = value.length;

    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      final candidate = '${value.substring(0, middle)}$suffix';
      if (widthOf(candidate) <= _fileNameValueWidth) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }

    return '${value.substring(0, low).trimRight()}$suffix';
  }

  pw.Widget _personTitle(String label, String name) {
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          fontSize: _tableFontSize,
          fontWeight: pw.FontWeight.bold,
          color: _textColor,
        ),
        children: [
          pw.TextSpan(text: '$label '),
          pw.TextSpan(
            text: name,
            style: pw.TextStyle(color: _blue, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _dividerWidget() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 22),
      child: pw.Divider(color: _divider, height: 1),
    );
  }

  pw.Widget _medication(SharedFileMedicationAnalysisEntity medication) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (medication.name.trim().isNotEmpty || medication.quantity != null)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '>',
                style: pw.TextStyle(fontSize: _tableFontSize, color: _blue),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: medication.name.trim().isEmpty
                    ? pw.SizedBox()
                    : pw.Text(
                        medication.name,
                        style: pw.TextStyle(
                          fontSize: _tableFontSize,
                          color: _textColor,
                        ),
                      ),
              ),
              if (medication.quantity != null)
                pw.Text(
                  'x ${medication.quantity}',
                  style: pw.TextStyle(
                    fontSize: _tableFontSize,
                    color: _textColor,
                  ),
                ),
            ],
          ),
        if (medication.instructions.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, top: 8),
            child: pw.Text(
              medication.instructions,
              style: pw.TextStyle(
                fontSize: _tableFontSize,
                lineSpacing: 7,
                color: _textColor,
              ),
            ),
          ),
        if (_isWebUrl(medication.originalUrl))
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.UrlLink(
                destination: medication.originalUrl!.trim(),
                child: pw.Text(
                  'Ver original',
                  style: pw.TextStyle(
                    fontSize: _tableFontSize,
                    color: _linkBlue,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isWebUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  pw.Widget _observations(String observations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Observaciones',
          style: pw.TextStyle(fontSize: _tableFontSize, color: _secondaryColor),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          observations,
          style: pw.TextStyle(
            fontSize: _tableFontSize,
            lineSpacing: 7,
            color: _textColor,
          ),
        ),
      ],
    );
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
