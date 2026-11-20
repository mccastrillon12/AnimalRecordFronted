# Integración Flutter de sincronización y transferencias

Referencia: `guia-flutter-sincronizacion-transferencias.md`, revisión del 18 de noviembre de 2026, backend de referencia `010d6ba`.

## Alcance

Integración móvil sobre la arquitectura existente. Se mantienen las pantallas, componentes, estilos y distribución. Los controles existentes reciben los catálogos y datos reales. Los comentarios existentes admiten hasta 500 caracteres y el botón de reintento conserva la operación original incluso después del vencimiento de la autorización.

No se modificaron configuraciones de ambiente, backend, infraestructura, almacenamiento ni permisos. La revisión del backend desplegado y su modo de aceptación deben confirmarse con su administrador.

## Cambios por capa

- **Dominio:** política compartida de comentarios; etapas `OwnerHistoryPeriod`; procedencia `MedicalDocumentUploader`; agrupación por ID del responsable; archivo histórico con nombre, MIME y bytes; contrato de motivos de rechazo.
- **Datos:** lectura y ordenación de catálogos por `sortOrder`, conservación de `requiresComment`, serialización de comentarios según código, campos de respuesta de motivos y comentarios, historial de propietarios y responsable médico. El POST de creación admite únicamente los campos del contrato móvil.
- **Presentación:** conexión de los dropdowns existentes, comentarios de transferencia/rechazo, historial de propietarios y grupos médicos. Selección global por UUID y validación de que se cargó el conjunto completo antes de decidir. Las etapas A → B → A permanecen separadas.
- **Composición:** invalidación dirigida de caché médico al confirmar un traspaso, mediante un callback configurado en el contenedor de dependencias. Solo se invalidan los animales de la decisión y una vez por versión confirmada; consultar transferencias ya resueltas no borra la caché.

## Llamadas y comportamiento

- `GET /animal-transfers/recipients`: conserva la detección existente de nombre o identificación, los ceros iniciales y el descarte de respuestas tardías. Valida búsquedas de 2 a 100 caracteres.
- `GET /catalogs/animal-transfer-reasons` y `GET /catalogs/animal-transfer-rejection-reasons`: carga de códigos, etiquetas, orden y necesidad de comentario, solicitando revalidación de caché.
- `POST /animal-transfers`: incluye `reasonComment` recortado para `OTHER`; omite el campo en los demás motivos.
- `POST /animal-transfers/{id}/decisions`: incluye motivo común de rechazo y comentario de `OTHER` en rechazo total o parcial. La aceptación total omite ambos campos.
- OTP: conserva cinco dígitos como texto y separa verificación de creación. Las respuestas 429 bloquean llamadas OTP hasta el plazo de `Retry-After`, tanto en segundos como en fecha HTTP.
- Reintentos: conserva clave, versión original, selección, motivo, comentario y autorización. Un resultado incierto no renueva la autorización ni crea otra intención. Las decisiones inciertas consultan el detalle sin repetir automáticamente el POST.
- `GET /animals`, `/animals/owner/{id}` y `/animals/{id}`: lee `ownerHistory` y lo conserva al convertir o actualizar los modelos locales.
- Documentos médicos: lee `uploadedBy` sin enviarlo en cargas ni revisiones. Agrupa por ID; los registros sin procedencia quedan bajo «Responsable no disponible». La última actualización usa únicamente `updatedAt`.
- Descargas históricas: mantiene bytes por API autenticada, valida longitud y rechaza respuestas parciales. La lectura del original médico usa `Content-Type` y el nombre de `Content-Disposition`, saneando caracteres de ruta.
- Foto histórica: reconoce también la referencia `/profilePictureUrl`.

## Seguridad y compatibilidad

Por instrucción posterior del usuario, `PENDING` también bloquea todas las escrituras del animal, igual que `PROCESSING`. Se conservan las tarjetas históricas de solo lectura y la devolución mediante una solicitud nueva con el mismo UUID. Un animal pendiente sigue consultando su ficha vigente: no se convierte en un expediente histórico.

El bloqueo incluye ficha básica y adicional, nombre, foto, inactivación, diario y adjuntos, cargas médicas, revisiones, reemplazos y eliminación de documentos. Los repositorios verifican el listado propio actualizado antes de escribir; si no pueden confirmar el permiso, no envían la mutación. Para documentos compartidos se comprueban todos los animales afectados. La lectura del detalle usa su propia petición y no depende de que responda otra consulta al listado completo. `AnimalCubit` conserva las restricciones ya conocidas del listado si el detalle las omite.

Las interfaces de verificación pertenecen al dominio y sus implementaciones remotas a datos; la inyección es obligatoria en los repositorios de animales, diario y documentos. La verificación previa a editar un documento pasa por `MedicalDocumentDetailCubit` y un caso de uso; el widget no resuelve el servicio remoto. `AnimalWritePolicy` comparte la resolución del permiso vigente entre diario, menús de carga y documentos médicos. Un snapshot pendiente no impide recuperar la edición tras el rechazo y la actualización del estado; los snapshots históricos siguen bloqueados. Se deshabilitan las acciones existentes sin rediseñar las pantallas. Los originales y las descargas continúan disponibles en lectura.

Las cargas de adjuntos del diario propagan los fallos de preparación y confirmación al cubit. Una URL incompleta o un permiso denegado ya no termina en una confirmación de carga exitosa.

Esta regla de `PENDING` es más restrictiva que la guía original, que permite escrituras en el backend durante ese estado. El bloqueo se implementa en Flutter; una garantía frente a otros clientes o cambios simultáneos exige la misma regla transaccional en el backend.

Los cambios de sesión mantienen la limpieza de caché y de las decisiones pendientes de reconciliar. Una respuesta médica anterior a una invalidación no puede repoblarlo ni devolverse como vigente. Las invalidaciones dirigidas reconsultan solo las cargas afectadas; las consultas de otros animales continúan. El cubit médico descarta respuestas de cargas superadas por una nueva consulta.

Los logs HTTP ocultan los cuerpos médicos y de transferencias. El logger médico específico ya no imprime respuestas completas, tampoco en debug. Los datos originales del error quedan en `ApiException`, con accesores `backendMessage` y `timestamp` para inspección deliberada. Los errores JSON de una descarga de bytes también se conservan como diagnóstico.

Por instrucción del usuario, los mensajes técnicos y del servidor no se muestran en las transferencias. El selector de motivos no presenta el error de catálogo vacío. Los errores de las bandejas, OTP, decisiones, avisos e histórico usan textos locales para el usuario, sin interpolar `ApiException.message` ni diagnósticos de infraestructura. La consola de debug registra exclusivamente categoría, estado HTTP válido y una etiqueta de operación de una lista local. No imprime mensajes libres, URLs, IDs, cuerpos, OTP ni secretos; no depende de regex para intentar sanearlos. Los mensajes de aceptación/rechazo y las validaciones locales se conservan.

Excepción de diagnóstico solicitada expresamente por el usuario: al fallar el `POST /animal-transfers/otp-challenges` iniciado al pulsar «Transferir», la consola de debug imprime el cuerpo completo de la respuesta de error, estado HTTP y ruta fija, entre `[Transfers][OTP response] BEGIN` y `END`. Los campos de credenciales se enmascaran recursivamente; no se vuelcan headers ni el cuerpo de la petición. `hasHttpResponse` permite distinguir una respuesta del backend de un fallo sin respuesta HTTP. Esta excepción no aplica a respuestas exitosas, verificación OTP, reenvío, creación de transferencias ni decisiones. La UI y las compilaciones release no muestran este diagnóstico.

Diagnóstico adicional solicitado para la aceptación: los fallos de `POST /animal-transfers/{id}/decisions`, incluidos sus reintentos, imprimen la respuesta completa entre `[Transfers][Decision response] BEGIN` y `END`. Los errores al cargar o seguir el detalle usan `[Transfers][Detail response]`. Ambos reutilizan el mismo formateador de JSON y enmascarado recursivo de credenciales del OTP, solo en debug y sin cambiar la UI. No registran el cuerpo de la decisión, proof, clave de idempotencia ni headers.

No se añadieron bloques visuales para mostrar nuevos comentarios de respuesta: permanecen disponibles en `TransferRequest`, respetando la restricción de no ampliar la UI.

## Validación

Corrección de la revisión de arquitectura: análisis estático de todos los archivos Dart pendientes, incluidas las adaptaciones de fakes a las nuevas interfaces, sin errores ni advertencias; permanecen siete avisos informativos previos. `flutter build apk --debug --no-pub` generó correctamente `build/app/outputs/flutter-apk/app-debug.apk`. Se revisaron las dependencias de capas y `git diff --check`. No se ejecutaron pruebas funcionales ni suites de pruebas; la validación de comportamiento queda a cargo del usuario.

Actualización de solo lectura en `PENDING`: análisis estático de 18 archivos Dart, incluidas las adaptaciones de constructores de pruebas existentes, sin errores ni advertencias. Permanecen siete avisos informativos previos de estilo/deprecación. La revisión de importaciones de `home`, `diary` y `medical_documents` mantuvo la separación de capas. No se ejecutaron pruebas funcionales ni suites de pruebas.

`dart analyze` sobre los 32 archivos Dart modificados o nuevos terminó sin hallazgos. `git diff --check` pasó. La revisión estática de importaciones no encontró dependencias de `data` desde dominio o presentación en las capas revisadas de `home` y `medical_documents`.

La ejecución inicial del análisis general de `lib` no encontró errores de compilación; reportó avisos previos en archivos fuera del alcance. Los hallazgos de estilo introducidos durante esta integración se corrigieron antes del análisis focalizado final.

Las pruebas funcionales y de integración no se ejecutaron por indicación del usuario. Tampoco se certificó el backend desplegado.

Pendientes para validación manual:

1. Búsqueda por cédula parcial con ceros iniciales, cambio rápido de consulta y paginación.
2. Catálogos reales; `OTHER` con texto, espacios y límite de longitud, tanto al transferir como al rechazar.
3. OTP de cinco dígitos, reenvío, vencimiento y 429.
4. Transferencia de un animal sin archivos y de otro con foto, diario y PDF aprobado.
5. Dos o más animales, selección entre páginas, aceptación parcial y rechazo total con motivo común.
6. Timeout/503 y replay de la misma operación, incluida autorización vencida, sin duplicados.
7. Seguimiento de `PROCESSING`, permisos del dueño anterior y apertura/descarga del histórico.
8. Devolución B → A: mismo UUID, una sola ficha vigente, datos actualizados e historial A → B → A.
9. Documentos subidos por dos IDs distintos, incluso si comparten nombre, y documentos antiguos sin responsable.
10. Cambio de cuenta sin datos privados de la sesión anterior y archivos históricos con nombre/MIME correctos.
11. Animal `PENDING`: recorrer ficha, información adicional, foto, diario, historias clínicas, vacunas y archivos; comprobar que no permite crear, editar, eliminar, inactivar ni cargar. La consulta y descarga deben funcionar.
12. Abrir un editor antes de generar la transferencia desde otra sesión: intentar guardar, reemplazar o eliminar después; debe bloquearse antes del envío de la escritura. Rechazar la transferencia y refrescar el listado debe recuperar los permisos normales del dueño.
13. Desde «Mis animales», combinar animales disponibles y pendientes: el selector de transferencia debe contrastar la búsqueda con `GET /animals` y excluir los pendientes. Al abrir la carga de archivos, se refresca la lista propia y se excluyen los pendientes de la selección, preselección y recuperación de cargas guardadas. Si solo queda un animal activo editable, se selecciona ese animal; si ninguno es editable o falla la consulta, no se habilita la carga. No se modifica el diseño de la UI.

La proyección histórica del backend de referencia puede omitir `uploadedBy`. Se muestra el responsable desconocido cuando falte; la exposición de ese campo en esa ruta requiere un ajuste del backend si se necesita.
