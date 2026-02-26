import 'package:equatable/equatable.dart';

class LoginParams extends Equatable {
  final String identifier;
  final String password;

  const LoginParams({required this.identifier, required this.password});

  @override
  List<Object?> get props => [identifier, password];

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'password': password,
  };
}
