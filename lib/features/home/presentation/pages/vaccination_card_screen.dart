import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/layout/app_header.dart';
import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/vaccination_group_detail_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/vaccination_send_menu.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/domain/usecases/export_shared_file_analysis_pdf_usecase.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VaccinationCardScreen extends StatefulWidget {
  final AnimalModel animal;
  final VaccinationGroupViewData? selectedGroup;

  const VaccinationCardScreen({
    super.key,
    required this.animal,
    this.selectedGroup,
  });

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  bool _exporting = false;

  bool get _isCertificate => widget.selectedGroup != null;
  String get _title =>
      _isCertificate ? 'Certificado de vacunación' : 'Carné de vacunación';

  @override
  Widget build(BuildContext context) {
    final user = _currentUser(context);
    return Scaffold(
      backgroundColor: AppColors.bgOxford,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              AppIcons.vaccinationCardBackground,
              key: const Key('vaccination-card-background'),
              width: double.infinity,
              height: 562,
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppHeader(
                      onBack: () => Navigator.pop(context),
                      customCenter: _VaccinationCardHeaderTitle(title: _title),
                      customTrailing: VaccinationSendMenu(
                        menuKey: Key(
                          _isCertificate
                              ? 'vaccination-certificate-menu'
                              : 'vaccination-card-menu',
                        ),
                        onSend: _exporting ? () {} : () => _export(user),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          key: const Key('vaccination-card-content-background'),
                          clipBehavior: Clip.antiAlias,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.m,
                            AppSpacing.m,
                            AppSpacing.m,
                            AppSpacing.xl,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgHielo,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AnimalPhoto(animal: widget.animal),
                              const SizedBox(height: 20),
                              _AppProfileInformation(
                                animal: widget.animal,
                                user: user,
                              ),
                              const SizedBox(height: 20),
                              _VaccinationCardDocuments(
                                animalId: widget.animal.id,
                                selectedGroup: widget.selectedGroup,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _VaccinationCardFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  UserEntity? _currentUser(BuildContext context) {
    try {
      final state = context.read<AuthBloc>().state;
      return state is AuthSuccess ? state.user : null;
    } catch (_) {
      return null;
    }
  }

  List<VaccinationGroupViewData> _groups() {
    if (widget.selectedGroup case final selected?) return [selected];
    final state = context.read<AnimalMedicalDocumentsCubit>().state;
    return state is AnimalMedicalDocumentsLoaded
        ? sortVaccinationGroupsByLatest(groupVaccinations(state.documents))
        : const [];
  }

  Future<void> _export(UserEntity? user) async {
    final groups = _groups();
    if (groups.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final getDownloadUri = di.sl<GetMedicalDocumentDownloadUriUseCase>();
      final originalUrls = <String, String>{};
      for (final group in groups) {
        for (final application in group.applications) {
          originalUrls[application.document.id] = (await getDownloadUri(
            application.document.id,
          )).toString();
        }
      }
      final analysis = vaccinationGroupsToPdfAnalysis(
        groups,
        documentType: _title,
        patient: _patient(widget.animal),
        tutor: _tutor(user, widget.animal),
        originalUrls: originalUrls,
      );
      await di.sl<ExportSharedFileAnalysisPdfUseCase>()(analysis);
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _VaccinationCardHeaderTitle extends StatelessWidget {
  final String title;

  const _VaccinationCardHeaderTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          key: Key('vaccination-card-logo-top-spacing'),
          height: AppSpacing.xxl,
        ),
        Image.asset(
          'assets/Logo/Imagotipo_blanco.png',
          key: const Key('vaccination-card-logo'),
          width: 34,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(
          key: Key('vaccination-card-title-spacing'),
          height: AppSpacing.m,
        ),
        Text(
          title,
          key: const Key('vaccination-card-title'),
          style: AppTypography.heading1.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}

class _AnimalPhoto extends StatelessWidget {
  final AnimalModel animal;

  const _AnimalPhoto({required this.animal});

  @override
  Widget build(BuildContext context) {
    final imageUrl = animal.imageUrl?.trim() ?? '';
    return ClipRRect(
      key: const Key('vaccination-card-animal-photo-card'),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: imageUrl.isEmpty
            ? _fallback()
            : CachedNetworkImage(
                key: const Key('vaccination-card-animal-photo'),
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, _) => _fallback(),
                errorWidget: (_, _, _) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      key: const Key('vaccination-card-animal-photo-fallback'),
      color: AppColors.bgHielo,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        _familyIcon(animal.family),
        width: 72,
        height: 72,
        colorFilter: const ColorFilter.mode(
          AppColors.primaryFrances,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _AppProfileInformation extends StatelessWidget {
  final AnimalModel animal;
  final UserEntity? user;

  const _AppProfileInformation({required this.animal, required this.user});

  @override
  Widget build(BuildContext context) {
    final ownerName = _firstNotEmpty([user?.name, animal.ownerName]);
    final ownerDetails = <(String, String)>[
      (
        'Identificación',
        _joinValues([user?.identificationType, user?.identificationNumber]),
      ),
      ('Número celular', user?.cellPhone.trim() ?? ''),
      ('Correo electrónico', user?.email.trim() ?? ''),
    ].where((detail) => detail.$2.isNotEmpty).toList(growable: false);
    final animalDetails = <(String, String)>[
      ('Animal Record ID', animal.code.trim()),
      ('Familia', animal.family.trim()),
      ('Raza', animal.breed?.trim() ?? ''),
      ('Sexo', animal.sexDisplay.trim()),
      ('Edad', animal.ageDisplay.trim()),
      ('Peso', _weight(animal.weight)),
    ].where((detail) => detail.$2.isNotEmpty).toList(growable: false);

    return Container(
      key: const Key('vaccination-card-app-information'),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.medium(),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InformationSection(
            label: 'Paciente',
            name: animal.name,
            details: animalDetails,
          ),
          if (ownerName.isNotEmpty || ownerDetails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            const Divider(height: 1, color: AppColors.greyDelineante),
            const SizedBox(height: AppSpacing.l),
            _InformationSection(
              label: 'Propietario',
              name: ownerName,
              details: ownerDetails,
            ),
          ],
        ],
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  final String label;
  final String name;
  final List<(String, String)> details;

  const _InformationSection({
    required this.label,
    required this.name,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.body4.copyWith(
              color: AppColors.greyTextos,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: '$label '),
              if (name.isNotEmpty)
                TextSpan(
                  text: name,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.primaryAzulClaro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        if (details.isNotEmpty) const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(
                  details[index].$1,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  details[index].$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VaccinationCardDocuments extends StatelessWidget {
  final String animalId;
  final VaccinationGroupViewData? selectedGroup;

  const _VaccinationCardDocuments({required this.animalId, this.selectedGroup});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AnimalMedicalDocumentsCubit,
      AnimalMedicalDocumentsState
    >(
      builder: (context, state) {
        if (state is AnimalMedicalDocumentsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          );
        }
        if (state is AnimalMedicalDocumentsError) {
          return Center(
            child: TextButton(
              onPressed: () => context.read<AnimalMedicalDocumentsCubit>().load(
                animalId,
                category: MedicalDocumentCategory.vaccinationCard,
              ),
              child: const Text('Reintentar'),
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded) {
          return const SizedBox.shrink();
        }
        final groups = selectedGroup == null
            ? sortVaccinationGroupsByLatest(groupVaccinations(state.documents))
            : [selectedGroup!];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < groups.length; index++) ...[
              VaccinationRecordList(
                detail: vaccinationDetailViewData(groups[index]),
                onViewOriginal: (document) => _showOriginal(context, document),
                recordSpacing: 20,
                groupDoses: true,
              ),
              if (index < groups.length - 1) const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showOriginal(
    BuildContext context,
    MedicalDocumentEntity document,
  ) async {
    final preview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: di.sl<GetMedicalDocumentDownloadUriUseCase>(),
      saveOriginalUseCase: di.sl<SaveMedicalDocumentOriginalUseCase>(),
    );
    try {
      await preview.show(
        context,
        acceptedDocumentId: document.id,
        fileName: document.originalFileName,
        mimeType: document.mimeType,
      );
    } catch (error) {
      if (context.mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}

class _VaccinationCardFooter extends StatelessWidget {
  const _VaccinationCardFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('vaccination-card-footer-logo'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/Logo/Imagotipo_blanco.png',
          width: AppSpacing.xl,
          height: 22,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'ANIMAL RECORD',
          style: AppTypography.body6.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

SharedFilePatientAnalysisEntity _patient(AnimalModel animal) {
  return SharedFilePatientAnalysisEntity(
    name: animal.name,
    recordId: animal.code,
    species: animal.family,
    breed: animal.breed?.trim() ?? '',
    sex: animal.sexDisplay,
    age: animal.ageDisplay,
    weight: _weight(animal.weight),
  );
}

SharedFileTutorAnalysisEntity _tutor(UserEntity? user, AnimalModel animal) {
  return SharedFileTutorAnalysisEntity(
    name: _firstNotEmpty([user?.name, animal.ownerName]),
    identification: _joinValues([
      user?.identificationType,
      user?.identificationNumber,
    ]),
    phoneNumber: user?.cellPhone.trim() ?? '',
    additionalDetails: [
      if (user?.email.trim().isNotEmpty ?? false)
        SharedFileAnalysisDetailEntity(
          label: 'Correo electrónico',
          value: user!.email.trim(),
        ),
    ],
  );
}

String _familyIcon(String family) {
  final normalized = family.toLowerCase();
  if (normalized.contains('felino') || normalized.contains('gato')) {
    return 'assets/illustrations/cat_icon.svg';
  }
  if (normalized.contains('bovino') || normalized.contains('vaca')) {
    return 'assets/illustrations/bovino_icon.svg';
  }
  if (normalized.contains('equino') || normalized.contains('caballo')) {
    return 'assets/illustrations/equino_icon.svg';
  }
  return 'assets/illustrations/dog_icon.svg';
}

String _weight(double? value) {
  if (value == null) return '';
  final formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  return '$formatted kg';
}

String _firstNotEmpty(List<String?> values) {
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
  }
  return '';
}

String _joinValues(List<String?> values) => values
    .map((value) => value?.trim() ?? '')
    .where((value) => value.isNotEmpty)
    .join(' ');
