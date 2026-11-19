import 'dart:async';

import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_home_notice_cubit.dart';
import 'package:animal_record/features/home/presentation/navigation/animal_transfer_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/features/home/domain/repositories/incoming_transfer_preview_repository.dart';

class TransferIncomingNotice extends StatefulWidget {
  final AnimalTransferRepository repository;
  final IncomingTransferPreviewRepository? previewCache;
  final String? accountId;

  const TransferIncomingNotice({
    super.key,
    required this.repository,
    this.previewCache,
    this.accountId,
  });

  @override
  State<TransferIncomingNotice> createState() => _TransferIncomingNoticeState();
}

class _TransferIncomingNoticeState extends State<TransferIncomingNotice>
    with WidgetsBindingObserver {
  late final TransferHomeNoticeCubit _cubit;
  Timer? _refreshTimer;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    if (widget.accountId case final id?) widget.previewCache?.useAccount(id);
    _cubit = TransferHomeNoticeCubit(
      widget.repository,
      previewCache: widget.previewCache,
    )..refresh();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_foreground) _cubit.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _cubit.refresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<TransferHomeNoticeCubit, TransferRequest?>(
      builder: (context, request) {
        if (request == null) return const SizedBox.shrink();
        final count = request.animalCount;
        final animals = count > 0 ? '[$count] animal(es)' : 'animal(es)';
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.m,
          ),
          child: Semantics(
            liveRegion: true,
            child: SizedBox(
              height: 114,
              child: Material(
                color: AppColors.primaryIndigo,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('transfer-incoming-notice'),
                  onTap: () async {
                    await openAnimalTransferRequests(
                      context,
                      focusPending: true,
                    );
                    if (mounted) await _cubit.refresh();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                      vertical: AppSpacing.m,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            AppIcons.notificationV2,
                            width: 27,
                            height: 23,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '¡Te acaban de transferir $animals!',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body3.copyWith(
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Flexible(
                                      child: Text(
                                        'Acéptalos y hazle seguimiento a su información.',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body6.copyWith(
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Transform.flip(
                                flipX: true,
                                child: SvgPicture.asset(
                                  AppIcons.arrowLeft,
                                  width: AppSpacing.iconSizeSmall,
                                  height: AppSpacing.iconSizeSmall,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.white,
                                    BlendMode.srcIn,
                                  ),
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
