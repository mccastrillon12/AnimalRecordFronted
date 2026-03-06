import 'package:equatable/equatable.dart';

class VerifyCodeParams extends Equatable {
  final String identifier;
  final String code;

  const VerifyCodeParams({required this.identifier, required this.code});

  @override
  List<Object?> get props => [identifier, code];
}
