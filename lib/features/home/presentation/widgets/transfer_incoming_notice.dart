import 'dart:async';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_home_notice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferIncomingNotice extends StatefulWidget {
  final AnimalTransferRepository repository;

  const TransferIncomingNotice({super.key, required this.repository});

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
    _cubit = TransferHomeNoticeCubit(widget.repository)..refresh();
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
    child: BlocBuilder<TransferHomeNoticeCubit, bool>(
      builder: (context, hasPendingRequest) {
        if (!hasPendingRequest) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.m,
          ),
          child: Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyBordes),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primaryFrances,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'Tienes una solicitud de transferencia pendiente.',
                      style: AppTypography.body4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
