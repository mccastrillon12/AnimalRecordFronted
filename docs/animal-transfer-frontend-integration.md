# Integración Flutter de transferencias

La referencia contractual es `frontend-animal-transfer-foundations.md`, sección
«Contenido de la entrega final para Flutter». Los datos ficticios de transferencia
ya no se inyectan en la app. Por instrucción posterior del usuario, el OTP de
transferencia tiene cinco dígitos numéricos como texto y un componente propio;
el OTP de registro no cambió. La guía adjunta describe el contrato anterior de
seis dígitos. El usuario indicó que el backend de cinco dígitos ya está
desplegado en integración; la verificación con un código recién emitido aún no
se ha realizado desde esta app.

## Disponibilidad

- `.env.physical` es la configuración de producción del frontend y la usa la
  compilación predeterminada. Por instrucción explícita posterior del usuario,
  permite crear y consultar solicitudes reales, leer avisos y rechazar todos
  los animales. Esta habilitación del flujo básico en producción prevalece
  sobre la recomendación de la guía de dejar apagadas las funciones nuevas
  frente al despliegue actual; no acredita que el backend esté preparado.
- `--dart-define=TRANSFER_INTEGRATION=true` usa `.env.development` para probar
  el mismo flujo contra el backend de integración.
- La aceptación parcial requiere además
  `--dart-define=TRANSFER_ACCEPTANCE=true`.
- El histórico requiere además `--dart-define=TRANSFER_HISTORY=true`.
  Ambos indicadores dependen de `TRANSFER_INTEGRATION`, por lo que la app
  de producción (`.env.physical`) mantiene aceptación e histórico apagados.

## Contratos y recuperación

El buscador usa `GET /animals/search?isActive=true`,
`GET /animal-transfers/recipients` y el catálogo de motivos del backend. Compara
la identificación como texto y no la muestra como pista. El OTP usa los tres
endpoints de `otp-challenges`; la creación envía el `proof` y una clave UUID de
idempotencia. Ante red o 503, el botón de reintento conserva cuerpo y clave de
la creación. La verificación con resultado incierto exige solicitar un desafío
nuevo de manera explícita.

Cuando la autorización verificada vence durante una creación incierta, la
pantalla permite solicitar explícitamente un nuevo OTP. Tras verificarlo,
reemplaza solo `authorization` y conserva la misma `Idempotency-Key`,
`recipientId`, `reasonCode` y `animalIds` mientras el flujo siga abierto.
Si se cierra la pantalla o el proceso, esa intención en memoria ya no puede
retomarse con su clave original: primero debe consultarse **Enviadas**.

El campo de transferencia admite cinco dígitos y usa `CodeAutoFill` con patrón
de cinco dígitos cuando el backend devuelve `channel: PHONE`, además de la
sugerencia `oneTimeCode` del sistema. No
lee SMS para correo ni acepta automáticamente un código anterior de seis
dígitos. Si existe uno pendiente, el usuario debe pulsar **Reenviar** cuando
`resendAvailableAt` del servidor lo permita y usar el código recién emitido.

La bandeja lee entrantes y salientes. El detalle pagina ítems, recarga desde
la primera página ante cursor obsoleto y muestra `PROCESSING` como traspaso en
curso. Rechazo total envía `acceptedAnimalIds: []` tras confirmación. La
aceptación parcial conserva selección, versión y clave originales ante un
resultado incierto. El histórico es de solo lectura; las descargas usan los
identificadores y `publicationHash` publicados por el backend. Los bytes se
guardan únicamente cuando la descarga termina completa.

## Validación pendiente

El análisis estático del código modificado pasó. No se ejecutaron pruebas
unitarias, por solicitud del usuario. No se ha llamado a un backend de
integración ni verificado su versión o respuestas HTTP. El ensayo con AWS real
sigue pendiente.

En producción del frontend (`.env.physical`) se observó en la pantalla OTP de
transferencia un `POST /animal-transfers` con HTTP 503 y mensaje
`Transfer request outcome could not be confirmed; retry with the same
Idempotency-Key`. El OTP había sido verificado, pero el 503 no confirma si la
solicitud se guardó. La captura posterior mostraba la bandeja **Recibidas**
vacía, lo que no determina el estado de **Enviadas**. La versión del backend y
la causa operativa del 503 no se han comprobado. Este dato no es una prueba del
backend de integración ni de AWS.

Nueva comprobación en `.env.physical` el 16 de noviembre de 2026: **Enviadas**
mostró «No hay solicitudes» antes y después de pulsar «Reintentar la misma
solicitud» en un flujo aún abierto. El registro del `verify` original mostró
HTTP 200 a las 17:45:23 UTC−05:00; no hubo un `verify` nuevo en el reintento.
El `POST /animal-transfers` del reintento recibió HTTP 503 a las
18:09:59.820 UTC−05:00. El estado de persistencia sigue incierto. Se omitieron
identificadores, OTP, proof, tokens y cuerpo de la petición.

Tras solicitar un OTP nuevo para la misma intención aún abierta, la prueba en
`.env.physical` observó `POST /animal-transfers/otp-challenges` **201** a las
18:18:20.920 UTC−05:00, `POST /animal-transfers/otp-challenges/{id}/verify`
**200** a las 18:18:52.905 UTC−05:00 y `POST /animal-transfers` **503** a las
18:18:53.866 UTC−05:00. `GET /animal-transfers?direction=OUTGOING` devolvió
**200** a las 18:19:39.260 UTC−05:00 y la bandeja mostró «No hay solicitudes». No se
observó un `201` ni un replay `200` de creación. El 503 sigue sin causa
verificada en el frontend; revisar la versión y los logs del backend que sirve
a `.env.physical`. No se registraron OTP, proof, tokens ni cuerpo completo.
El logger compartido se desactiva en compilaciones de integración porque el
interceptor de autenticación existente registra fragmentos de tokens; no se
modificó el código de registro ni de usuario.
Los ajustes de foto, diario y documentos médicos quedan fuera de esta pasada
por la instrucción posterior de modificar solo transferencias.

Antes de probar en integración, confirmar que las rutas de decisión e histórico
estén montadas en la misma versión, preparar las colecciones e índices con
backend y usar cuentas/archivos ficticios. Si difiere del contrato, registrar
versión de app y backend, pantalla, pasos, etapa, estado y mensaje HTTP, sin
identidades reales, tokens ni URLs firmadas.
