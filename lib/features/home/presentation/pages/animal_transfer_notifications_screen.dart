import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_notifications_cubit.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimalTransferNotificationsScreen extends StatelessWidget {
  final AnimalTransferRepository repository;
  const AnimalTransferNotificationsScreen({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransferNotificationsCubit(repository)..refresh(),
    child: _NotificationsBody(repository: repository),
  );
}

class _NotificationsBody extends StatelessWidget {
  final AnimalTransferRepository repository;
  const _NotificationsBody({required this.repository});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avisos de transferencias')),
    body: BlocBuilder<TransferNotificationsCubit, TransferNotificationsState>(
      builder: (context, state) {
        final cubit = context.read<TransferNotificationsCubit>();
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView(
            children: [
              if (state.unreadCount != null)
                ListTile(title: Text('Sin leer: ${state.unreadCount}')),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              if (state.items.isEmpty && !state.loading)
                const ListTile(title: Text('No hay avisos')),
              for (final item in state.items)
                ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.text),
                  leading: Icon(
                    item.readAt == null
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                  ),
                  onTap: () async {
                    if (item.readAt == null) await cubit.markRead(item.id);
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AnimalTransferDetailScreen(
                          repository: repository,
                          transferId: item.transferId,
                          incoming: false,
                        ),
                      ),
                    );
                    if (context.mounted) cubit.refresh();
                  },
                ),
              if (state.cursor != null)
                TextButton(
                  onPressed: state.loading ? null : cubit.loadMore,
                  child: const Text('Cargar más avisos'),
                ),
              if (state.loading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    ),
  );
}
