import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses dates for sorting but preserves the backend text', () {
    final date = parseMedicalDocumentDate(
      'miércoles, 14 de mayo de 2025, 7:21 p.m.',
    );

    expect(date, DateTime(2025, 5, 14, 19, 21));
    expect(
      displayMedicalDocumentDate('miércoles, 14 de mayo de 2025, 7:21 p.m.'),
      'miércoles, 14 de mayo de 2025, 7:21 p.m.',
    );
  });

  test('preserves an unknown backend date instead of hiding it', () {
    expect(displayMedicalDocumentDate('Fecha manuscrita'), 'Fecha manuscrita');
  });
}
