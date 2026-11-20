import 'package:equatable/equatable.dart';

/// One ownership stage. An owner can occur in multiple distinct stages.
class OwnerHistoryPeriod extends Equatable {
  final String ownerId;
  final String? ownerName;
  final int ownershipVersion;
  final DateTime? startedAt;
  final DateTime? transferredAt;
  final DateTime? endedAt;
  final bool isCurrent;

  const OwnerHistoryPeriod({
    required this.ownerId,
    required this.ownershipVersion,
    this.ownerName,
    this.startedAt,
    this.transferredAt,
    this.endedAt,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [
    ownerId,
    ownerName,
    ownershipVersion,
    startedAt,
    transferredAt,
    endedAt,
    isCurrent,
  ];
}
