# Transferencia de animales: contexto para integrar el backend

El flujo actual implementa UI y estado local. Los dos accesos comparten la ruta
`AppRoutes.animalTransfer`. No consulta destinatarios ni modifica la propiedad
de los animales mediante servicios.

## Elementos temporales que se deben retirar o sustituir

| Elemento | Ubicación | Cambio al integrar el backend |
| --- | --- | --- |
| Destinatario ficticio Bárbara James | `lib/features/home/presentation/fixtures/animal_transfer_preview_data.dart`: `animalTransferPreviewRecipients` | Sustituir por resultados reales y eliminar el dato ficticio. El ID `preview-recipient` no debe enviarse a un servicio real. |
| Motivos Venta, Adopción y Otro | Mismo archivo: `animalTransferPreviewReasons` | Sustituir por las opciones e identificadores acordados con el backend. Son opciones provisionales para recorrer la UI. |
| Contacto ficticio para verificar | Mismo archivo: `animalTransferPreviewVerificationIdentifier` (`marc_doe@hotmail.com`) | Sustituir por el destino de verificación que defina el servicio. No se envía ningún mensaje a este contacto. |
| Inyección de datos de demostración | `lib/features/home/presentation/navigation/animal_transfer_navigation.dart`: `buildAnimalTransferRoute` | Retirar la importación y la inyección de las dos listas y del contacto temporal. Después, eliminar el archivo de fixtures. |
| Búsqueda local en la lista inyectada | `lib/features/home/presentation/cubit/animal_transfer_cubit.dart`: `search` | Conectar la búsqueda con el caso de uso correspondiente y gestionar carga, errores y búsquedas obsoletas según el contrato definido. |
| Indicador de demostración | `lib/features/home/presentation/models/animal_transfer_recipient.dart`: `isDemo`, y etiqueta en `animal_transfer_screen.dart` | Eliminar el indicador y la etiqueta cuando solo existan datos reales. |
| Finalización visual al completar el OTP | `lib/features/home/presentation/cubit/animal_transfer_cubit.dart`: `completePreview` | Sustituir por la verificación real y la operación de transferencia. Actualmente, cinco caracteres alfanuméricos permiten mostrar la pantalla final de demostración; no autentican, transfieren ni eliminan animales. |
| Reenvío simulado y espera de tres minutos | `lib/features/home/presentation/pages/animal_transfer_verification_screen.dart`: `_resend` | Conectar el envío real y usar los tiempos y límites devueltos por el servicio. Actualmente solo se limpia el campo y reinicia el temporizador de `VerificationStep`. |

## Identificación y validaciones pendientes

- `AnimalTransferRecipient.identificationType` permite presentar el tipo del
  destinatario, deshabilitado en el formulario. Su valor predeterminado `C.C.`
  es provisional: mapearlo al dato real al definir el contrato.
- La identificación enmascarada que aparece en los resultados es solo una
  etiqueta de presentación; no permite verificar la identidad del destinatario.
- `AnimalTransferState.canTransfer` comprueba únicamente que se haya seleccionado
  un destinatario, se haya escrito una identificación alfanumérica de 1 a 50
  caracteres y se haya elegido un motivo de la lista disponible. El formato
  coincide con el campo `IdSelector` existente; no representa una validación
  de identidad ni una regla definitiva del servicio.
- Si se elige `Otro`, se muestra el campo `¿Cuál?`, obligatorio y con un máximo
  visual de 80 caracteres, siguiendo el patrón de otros campos de detalle del
  proyecto. Al cambiar de motivo se limpia la descripción. Acordar su nombre
  y restricciones definitivas en el contrato; no asumir que existe este campo en la API.
- Para avanzar al OTP también debe existir un contacto de verificación. El
  contacto actual viene del fixture, no de un servicio ni del usuario destinatario.
- La coincidencia de la identificación, permisos, elegibilidad de animales y
  cambio de propietario quedan pendientes del contrato y validación del backend.
- Los datos del formulario se conservan al volver al primer paso y se limpian
  cuando cambia la búsqueda o el destinatario, para no reutilizarlos con otra persona.
- Al pulsar `Transferir` se muestra la pantalla OTP. Volver desde allí conserva
  identificación, motivo y descripción. El código se descarta al salir de la
  pantalla de verificación; no se guarda ni se registra en logs.

## Pantalla de verificación

`animal_transfer_verification_screen.dart` reutiliza `VerificationStep`, con sus
cinco casillas alfanuméricas y su temporizador. `Verificar` se habilita al completar
las cinco posiciones; la autenticidad, expiración e intentos del código quedan
pendientes de validación del backend. No existe un código fijo de prueba. La
pantalla de éxito posterior representa únicamente la vista previa del flujo.

El autocompletado SMS está deshabilitado en esta demostración para no iniciar
escuchas de plataforma sin un flujo real. Las opciones nuevas `enableSmsAutofill`
y `autofocus` conservan el comportamiento anterior por defecto en las pantallas
de autenticación. El envío y verificación de transferencias deben usar sus
propios contratos; no se disparan eventos de registro/login de `AuthBloc`.

## Pantalla final y navegación

`animal_transfer_success_screen.dart` utiliza la ilustración existente
`assets/illustrations/add-friend-on-social-media.svg`, el degradado de la app,
`FixedBottomActionLayout` y `CustomButton`. Muestra el nombre del destinatario
seleccionado y únicamente la acción `Finalizar`.

La ilustración está registrada explícitamente en `pubspec.yaml`. Se reserva
su altura durante la carga y su tamaño se adapta al ancho de la pantalla,
tomando como referencia 283 px en un diseño de 375 px. Al añadir este recurso
se debe reconstruir el paquete de assets; un APK anterior no lo contiene.
El degradado y los anchos máximos de texto de esta pantalla se ajustan a la
referencia sin modificar el tema global.

Desde ambos accesos, `Finalizar` abre `AppRoutes.home` con
`homeInitialSectionArgument: homeMyAnimalsSection` y elimina la pila anterior.
Así se muestra Mis animales y no se vuelve al detalle o al OTP con Atrás.

Los textos de aceptación, rechazo, estado pendiente y acceso a historias son
solo la copia del diseño: no existe todavía una implementación de esos estados.
El plazo `X días` se conserva como marcador pendiente de definición; debe
reemplazarse con el plazo acordado o devuelto por el servicio. La pantalla final
solo deberá mostrarse tras la confirmación real del backend al integrar la API.

## Componentes y pruebas que se conservan

Conservar la ruta compartida, el resumen de animales, los estilos B3/B5/B6,
`AnimalSelectionModal`, `IdSelector`, `AppDropdown`, `CustomTextField`,
`VerificationStep` y la navegación entre pasos.
No es necesario duplicar pantallas para ninguno de los dos accesos.

Las pruebas de transferencia están en
`test/features/home/presentation/{cubit,pages,navigation}/`. Al retirar los
fixtures de la aplicación, mover los datos ficticios necesarios a los fixtures
de pruebas y ajustar las pruebas a los estados y contratos reales.
