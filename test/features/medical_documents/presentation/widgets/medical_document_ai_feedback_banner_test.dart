import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_ai_feedback_banner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the shared spacing for the AI feedback banner', () {
    const visibleGap = MedicalDocumentAiFeedbackTopGap(isBannerVisible: true);
    const hiddenGap = MedicalDocumentAiFeedbackTopGap(isBannerVisible: false);

    expect(visibleGap.height, AppSpacing.m);
    expect(hiddenGap.height, AppSpacing.l);
  });
}
