import 'package:equatable/equatable.dart';

class VerifyCodeParams extends Equatable {
  final String email;
  final String code;

  const VerifyCodeParams({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}
