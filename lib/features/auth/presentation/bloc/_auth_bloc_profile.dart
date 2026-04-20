part of 'auth_bloc.dart';

/// Update profile, upload/delete profile picture handlers.

Future<void> _onUpdateProfileRequested(
  AuthBloc bloc,
  UpdateProfileRequested event,
  Emitter<AuthState> emit,
) async {
  final currentState = bloc.state;
  UserEntity? currentUser;

  if (currentState is AuthSuccess) {
    currentUser = currentState.user;
    emit(
      AuthSuccess(
        currentUser,
        isUpdating: true,
        isBiometricEnabled: currentState.isBiometricEnabled,
      ),
    );
  } else {
    emit(AuthLoading());
  }

  final result = await bloc.updateProfileUseCase(
    id: event.userId,
    data: event.data,
  );

  await result.fold(
    (failure) async {
      if (currentUser != null && currentState is AuthSuccess) {
        emit(
          AuthSuccess(
            currentUser,
            isUpdating: false,
            updateError: failure.message,
            isBiometricEnabled: currentState.isBiometricEnabled,
          ),
        );
      } else {
        emit(AuthError(failure.message));
      }
    },
    (user) async {
      // El backend podría no devolver profilePicture en el endpoint de actualizar perfil.
      // Si el usuario resultante no tiene profilePicture, pero nosotros sí lo teníamos, lo preservamos.
      UserEntity finalUser = user;
      if (user.profilePicture == null &&
          currentUser != null &&
          currentUser.profilePicture != null) {
        finalUser = user.copyWith(profilePicture: currentUser.profilePicture);
      }

      await _saveUserToCacheImpl(bloc, finalUser);
      emit(
        AuthSuccess(
          finalUser,
          isUpdating: false,
          isBiometricEnabled: currentState is AuthSuccess
              ? currentState.isBiometricEnabled
              : false,
        ),
      );
    },
  );
}

Future<void> _onUpdateProfilePicture(
  AuthBloc bloc,
  UpdateProfilePictureRequested event,
  Emitter<AuthState> emit,
) async {
  final currentState = bloc.state;
  if (currentState is! AuthSuccess) return;

  emit(
    currentState.copyWith(
      isUploadingPicture: true,
      profilePictureError: null,
    ),
  );

  try {
    // Paso 1: Comprimir imagen en el celular (sin gastar datos aún)
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      event.imagePath,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null) {
      emit(
        currentState.copyWith(
          isUploadingPicture: false,
          profilePictureError: 'No se pudo comprimir la imagen',
        ),
      );
      return;
    }

    const mimeType = 'image/jpeg';
    final fileSize = compressedBytes.length;

    // Paso 2: Obtener URL pre-firmada del backend
    final urlResult = await bloc.getProfilePictureUploadUrlUseCase(
      mimeType: mimeType,
      fileSize: fileSize,
    );

    await urlResult.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            isUploadingPicture: false,
            profilePictureError: failure.message,
          ),
        );
      },
      (urlData) async {
        final uploadUrl = urlData['uploadUrl'] as String?;
        final finalUrl = urlData['finalUrl'] as String?;

        if (uploadUrl == null || finalUrl == null) {
          emit(
            currentState.copyWith(
              isUploadingPicture: false,
              profilePictureError: 'Respuesta inválida del servidor',
            ),
          );
          return;
        }

        // Paso 3: Subir directo a S3 (sin JWT, sin pasar por Lightsail)
        await bloc.s3UploadService.uploadFileToS3(
          presignedUrl: uploadUrl,
          bytes: compressedBytes,
          mimeType: mimeType,
        );

        // Paso 4: Confirmar al backend con la URL pública final
        final confirmResult = await bloc.confirmProfilePictureUseCase(finalUrl);

        await confirmResult.fold(
          (failure) async {
            emit(
              currentState.copyWith(
                isUploadingPicture: false,
                profilePictureError: failure.message,
              ),
            );
          },
          (_) async {
            // El backend a veces devuelve una respuesta parcial en el PATCH.
            // Para no perder los datos del usuario, clonamos el usuario actual
            // y le inyectamos la nueva URL de la foto:
            final accurateUser = currentState.user.copyWith(
              profilePicture: finalUrl,
            );

            await _saveUserToCacheImpl(bloc, accurateUser);
            emit(
              AuthSuccess(
                accurateUser,
                isUploadingPicture: false,
                isBiometricEnabled: currentState.isBiometricEnabled,
              ),
            );
          },
        );
      },
    );
  } catch (e) {
    emit(
      currentState.copyWith(
        isUploadingPicture: false,
        profilePictureError: 'Error inesperado: ${e.toString()}',
      ),
    );
  }
}

Future<void> _onDeleteProfilePicture(
  AuthBloc bloc,
  DeleteProfilePictureRequested event,
  Emitter<AuthState> emit,
) async {
  final currentState = bloc.state;
  if (currentState is! AuthSuccess) return;

  emit(
    currentState.copyWith(
      isUploadingPicture: true,
      profilePictureError: null,
    ),
  );

  try {
    // Enviamos cadena vacía para "limpiar" la foto en el backend
    final result = await bloc.confirmProfilePictureUseCase('');

    await result.fold(
      (failure) async {
        emit(
          currentState.copyWith(
            isUploadingPicture: false,
            profilePictureError: failure.message,
          ),
        );
      },
      (_) async {
        final updatedUser = currentState.user.copyWith(
          profilePicture: '',
        );

        await _saveUserToCacheImpl(bloc, updatedUser);
        emit(
          AuthSuccess(
            updatedUser,
            isUploadingPicture: false,
            isBiometricEnabled: currentState.isBiometricEnabled,
          ),
        );
      },
    );
  } catch (e) {
    emit(
      currentState.copyWith(
        isUploadingPicture: false,
        profilePictureError: 'Error inesperado: ${e.toString()}',
      ),
    );
  }
}
