import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnimalCubit extends Mock implements AnimalCubit {}

void main() {
  testWidgets(
    'reports the final saved category when it differs from the upload tab',
    (tester) async {
      final animalCubit = _MockAnimalCubit();
      when(() => animalCubit.state).thenReturn(AnimalInitial());
      when(() => animalCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => animalCubit.animals).thenReturn(const [_animal]);
      MedicalDocumentCategory? uploadedCategory;
      var uploaded = false;
      RouteSettings? uploadSettings;

      await tester.pumpWidget(
        BlocProvider<AnimalCubit>.value(
          value: animalCubit,
          child: MaterialApp(
            onGenerateRoute: (settings) {
              if (settings.name != AppRoutes.sharedFileUpload) return null;
              uploadSettings = settings;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const SharedFileUploadResult(
                        animals: [_animal],
                        category: MedicalDocumentCategory.referral,
                      ),
                    ),
                    child: const Text('Completar carga'),
                  ),
                ),
              );
            },
            home: Scaffold(
              body: AnimalDocumentUploadMenu(
                animalId: _animal.id,
                requestedCategory: MedicalDocumentCategory.prescription,
                onUploaded: () => uploaded = true,
                onUploadedToCategory: (category) => uploadedCategory = category,
              ),
            ),
          ),
        ),
      );

      final menu = tester.widget<PopupMenuButton<String>>(
        find.byKey(const Key('animal-document-upload-menu')),
      );
      menu.onSelected?.call('subir_documento');
      await tester.pump(const Duration(milliseconds: 321));
      await tester.pumpAndSettle();

      final arguments = uploadSettings?.arguments as Map<String, dynamic>;
      expect(arguments[sharedFileReturnUploadResultArgument], isTrue);
      expect(
        arguments['requestedCategory'],
        MedicalDocumentCategory.prescription,
      );

      await tester.tap(find.text('Completar carga'));
      await tester.pumpAndSettle();

      expect(uploaded, isTrue);
      expect(uploadedCategory, MedicalDocumentCategory.referral);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );
}

const _animal = AnimalEntity(
  id: 'animal-1',
  name: 'Umi',
  code: 'AR-F025',
  species: 'CAT',
  breed: 'Criollo',
  sex: 'FEMALE',
  reproductiveStatus: 'SPAYED',
  hasChip: false,
  isAssociationMember: false,
  temperament: [],
  diagnosis: [],
  ownerId: 'owner-1',
);
