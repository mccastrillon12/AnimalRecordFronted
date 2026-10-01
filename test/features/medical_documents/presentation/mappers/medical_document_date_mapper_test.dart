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

  test('parses English month names used by clinical history documents', () {
    expect(parseMedicalDocumentDate('December 1, 2026'), DateTime(2026, 12, 1));
    expect(parseMedicalDocumentDate('January 25, 2026'), DateTime(2026, 1, 25));
  });

  test('displays recognized dates in day/month/year format', () {
    expect(displayMedicalDocumentShortDate('01-12-2026'), '01/12/2026');
    expect(displayMedicalDocumentShortDate('2026-09-24'), '24/09/2026');
    expect(displayMedicalDocumentShortDate('25/09/2025'), '25/09/2025');
    expect(displayMedicalDocumentShortDate('December 1, 2026'), '01/12/2026');
    expect(
      displayMedicalDocumentShortDate('Fecha manuscrita'),
      'Fecha manuscrita',
    );
  });
}
