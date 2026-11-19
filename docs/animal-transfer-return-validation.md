# Validación de transferencias y devolución

Fecha de preparación: 2026-11-18, America/Bogota (UTC−05:00).
El usuario confirmó que el commit de backend `84652be` está desplegado.
No se realizaron operaciones reales con cuentas, OTP ni transferencias en esta
entrega. Las pruebas de cuentas quedan a cargo del usuario.

## Correcciones de la revisión de arquitectura y seguridad

- La presentación de animales, diario y documentos depende de contratos y casos
  de uso de dominio. Las conversiones de la publicación y las implementaciones
  de caché permanecen en `data`; los widgets no construyen modelos de datos desde
  JSON ni descargan archivos históricos mediante repositorios directamente.
- Ficha, diario y documentos usan una única instancia de `AnimalHistoryRepository`.
  Las consultas concurrentes del mismo período comparten la misma promesa. Los
  métodos de carga y actualización del diario reutilizan una sola lectura.
- Una decisión invalida también los listados pendientes que ya estaban en curso.
  Sus respuestas se vuelven a consultar antes de publicarse y no pueden volver a
  insertar una solicitud decidida como pendiente. Se mantiene el cuerpo, la clave
  y la versión de los reintentos de decisión.
- La caché de expedientes tiene un máximo de 64 entradas y 12 MiB estimados; la
  de detalles pendientes, 64 entradas y 4 MiB estimados. Ambas expulsan los datos
  menos usados. Las tarjetas guardan el resumen y los identificadores de la
  publicación, sin conservar copias completas que eludan esos límites.
- Las fotos tienen un presupuesto de 16 MiB y 32 entradas en memoria, además de
  128 MiB y 200 archivos en disco. Una foto o publicación mayor que el presupuesto
  sigue devolviéndose al solicitante, sin retenerse en la caché correspondiente.
- Las imágenes de producción requieren HTTPS. HTTP queda limitado a compilaciones
  de depuración; la URL firmada completa se conserva al efectuar la solicitud.
- Los interceptores HTTP comparten una política de redacción. Se eliminaron los
  fragmentos de tokens y los cuerpos de error del interceptor de autenticación;
  también se ocultan los cuerpos de autenticación, credenciales en cabeceras y
  parámetros firmados. La autorización y la renovación de sesión no cambian.

La regresión ampliada de esta corrección aprobó **190 pruebas**, incluyendo la
separación de capas, límites de memoria/disco, respuesta tardía tras decidir,
lectura histórica compartida, protección de logs, renovación de autenticación y
los flujos médicos y de navegación cubiertos por esa ejecución. No se modificó el
diseño ni se ejecutaron transferencias reales. Los fallos previos de los archivos
de navegación de creación y de los tres casos de vacunas documentados más abajo
no forman parte de esa ejecución y no se afirma que la suite completa esté verde.

## Comportamiento implementado

- La ficha, las tres pestañas de información, el diario y los documentos usan
  las pantallas habituales. El animal transferido conserva su información en
  lectura; no permite agregar, editar, eliminar ni subir archivos.
- La tarjeta histórica usa `transferStatus`, `readOnly` y `ownershipHistory`.
  El contenido y los archivos se obtienen del período y `publicationHash`
  publicados mediante `/animal-ownership-history`, sin consultar el animal del
  dueño actual. La instantánea se adapta a los modelos habituales, sin mostrar
  JSON, identificadores técnicos ni una ficha alternativa.
- `isActive` conserva su significado. Un animal transferido puede seguir
  activo; se agrupa en «Transferidos e inactivos» por su estado de transferencia.
- «Pendiente» y «Transferido» se muestran solo en lista, con las medidas de
  «Inactivo» y los colores de las referencias. En cuadros no hay etiquetas.
  Se mantiene la configuración previa del acceso global opcional al histórico;
  la lectura desde la tarjeta transferida no depende de ese indicador.
- Al recuperar el mismo animal, la lista prioriza la tarjeta vigente y elimina
  duplicados. La información nueva y los permisos llegan de la respuesta actual
  del backend; no se reutiliza la instantánea del antiguo período para editar.
- En solicitudes, la foto usa exclusivamente
  `items[].animalProfilePictureUrl`. Se valida esquema HTTP(S), host y ausencia
  de espacios. Se usa la cadena completa, con sus parámetros firmados intactos.
  Un fallo de imagen renueva el detalle de su página con reintentos limitados;
  sin foto válida se muestra el icono de equino, bovino, felino o canino.
- La foto publicada del antiguo dueño usa los identificadores del archivo
  histórico. Las URL firmadas y los cuerpos sensibles no se registran.
- Cada solicitud nueva genera otra `Idempotency-Key`. El reintento de una
  creación incierta conserva su clave y cuerpo; el de una decisión incierta
  conserva clave, versión y animales seleccionados.

## Estados: contrato y comprobación real

El frontend conserva los estados recibidos; no deriva `isActive` de ellos:

| Contexto | Estado | Presentación |
| --- | --- | --- |
| Solicitud o ítem | `PENDING` | Pendiente |
| Solicitud | `PROCESSING` | Traspaso en curso |
| Solicitud o ítem | `ACCEPTED` | Aceptado |
| Solicitud | `PARTIALLY_ACCEPTED` | Aceptado parcialmente |
| Solicitud o ítem | `REJECTED` | Rechazado |
| Tarjeta del antiguo dueño | `transferStatus: TRANSFERRED` | Transferido, lectura |

Esta tabla describe los valores que interpreta el código y las respuestas
simuladas de las pruebas. Para confirmar los valores enviados por el backend
desplegado, registrar por separado `status` de la solicitud, `items[].status`,
`transferStatus`, `readOnly` e `isActive` de las tarjetas durante el ensayo real.

## Validación local realizada

La regresión focalizada final pasó: **112 pruebas** de repositorio, permisos,
devolución del mismo ID, idempotencia, segunda página y renovación de foto,
iconos, etiquetas, ficha normal, diario, documentos y resolución de dependencias.
El análisis de los archivos Dart modificados terminó sin errores ni advertencias;
permanece una nota informativa previa sobre `WillPopScope` en la ficha.

También se ejecutó el archivo de pruebas de vacunas. Cinco casos pasaron y tres
fallaron: `shows editing controls only on doses inside the 48-hour window`,
`edits and deletes an eligible vaccination dose` y
`opens doses that share the same medical document id`. Se reprodujeron los mismos
tres fallos con las pantallas y el menú originales de `HEAD`, restaurando después
los archivos de esta tarea. Corresponden a expectativas de controles/contadores
y desbordamientos que ya presenta esa base; no se cambió el diseño de vacunas.
Ese archivo quedó fuera de la ejecución final de 112 pruebas. No se afirma que
la suite completa del repositorio esté aprobada.

## Ensayo con dos cuentas

Corrección posterior a las capturas de error del usuario:

- La consulta de una publicación y la descarga de sus archivos todavía exigían
  `TRANSFER_HISTORY` junto con `TRANSFER_INTEGRATION` en el datasource. Esa
  comprobación local impedía abrir las fichas transferidas en la compilación
  normal, antes de llamar al backend. Se eliminó de esas dos operaciones; el
  indicador sigue controlando solamente el acceso global opcional al histórico.
- Las fotos históricas se validan antes de guardarse en caché local, con clave
  por cuenta, período, publicación y archivo. La lista y la ficha comparten una
  descarga concurrente. La caché conserva hasta 32 fotos en memoria y 200 en
  disco; se puede reutilizar tras reiniciar la app. Los fallos o imágenes
  corruptas no se conservan como descargas válidas.
- Para fotos con URL firmada, cambiar únicamente la firma no invalida los bytes
  guardados. La solicitud de imagen mantiene el enlace firmado completo; la
  identidad de caché distingue el archivo y los parámetros de contenido.
- La validación focalizada de esta corrección pasó **28 pruebas**, incluyendo
  el datasource real sin indicadores de integración, lectura de ficha, archivos,
  caché en disco, concurrencia, cambio de cuenta, sesión e imágenes corruptas.
  El análisis estático de los archivos de la corrección no encontró problemas.
  No se ejecutó una prueba real con las cuentas del usuario.

Después de aplicar esta actualización, reiniciar por completo la app para que
se registre el servicio compartido de caché antes del ensayo.

Corrección de reapertura de fichas: al cargar la lista, se prepara el histórico
en segundo plano, con hasta tres consultas simultáneas. La publicación completa
se conserva durante la sesión y se incorpora a las tarjetas; las aperturas que
coinciden comparten la misma consulta. La ficha consulta primero esa información
de forma síncrona, evitando otra petición y el indicador de carga al reabrirla.
Una actualización del listado conserva el contenido de la misma publicación;
una publicación distinta se carga de nuevo. Cerrar sesión o cambiar de cuenta
limpia esta información, y una devolución usa la ficha vigente editable. La
primera consulta que todavía no haya terminado puede requerir esperar los datos.
Esta corrección pasó 35 pruebas focalizadas y el análisis estático sin problemas,
incluida la reapertura con contenido visible desde el primer frame.

La precarga de la lista también prepara la foto histórica. La ficha toma los
mismos bytes de memoria de forma síncrona, conservando la imagen ya decodificada
y evitando otra descarga. Pulsar una tarjeta del diario de un animal transferido
abre la nota completa en lectura, con su fecha y adjuntos; no muestra controles
de edición, eliminación o creación y no vuelve a consultar el diario al abrir
o cerrar la nota. Esta ampliación pasó 24 pruebas focalizadas y el análisis
estático sin problemas. La etiqueta «Transferido» también aparece en la cabecera
del detalle, como solicitó el usuario; las tarjetas en cuadros siguen sin etiquetas.

Las solicitudes recibidas pendientes se preparan desde Home: se consulta la lista
completa y se precargan sus detalles paginados y fotos en segundo plano. Los
detalles se preparan antes que las imágenes para que una foto lenta no bloquee
otras solicitudes. Abrir o reabrir una solicitud ya preparada muestra sus datos
en el primer frame, sin otra consulta de detalle. Si se abre mientras se prepara,
ambos accesos comparten la misma consulta. La revisión periódica del aviso de Home
se conserva; una versión nueva, una decisión o un cambio de cuenta descarta los
datos correspondientes. Renovar una imagen usa el cursor de su página original.
La selección y la intención de reintento no se guardan en esta caché de lectura.

Esta ampliación pasó 21 pruebas focalizadas de precarga, navegación del receptor,
segunda página, fotos, aceptación parcial, fallos de red e idempotencia. Se
detectaron además tres fallos en el antiguo archivo de navegación de creación
`animal_transfer_navigation_test.dart`: sus fixtures todavía presuponen datos de
demo y no registran `TransferPendingMedicalWork`. La función de creación que
ejercitan esos casos no se modificó en esta ampliación. Esos tres casos quedaron
fuera de la ejecución focalizada final; no se afirma que toda la suite pase.

1. Con el dueño 1, enviar un animal al dueño 2 y aceptarlo con el dueño 2.
2. Con el dueño 2, cambiar un dato y transferir ese mismo ID al dueño 1 como una
   solicitud nueva. La clave nueva no debe coincidir con la de la ida.
3. Con el dueño 1, aceptar la devolución. Confirmar mismo ID, cambios del dueño
   2, una sola tarjeta vigente y posibilidad de editar y subir un archivo.
4. Con el dueño 2, comprobar tarjeta `TRANSFERRED`, información habitual
   visible, acceso a su histórico/documentos y ausencia de acciones de cambio.
5. Comprobar los documentos de cada período desde la cuenta correspondiente y
   verificar que actividad/fallecimiento no cambian por la transferencia.

Además, usar una solicitud pendiente con varios animales y paginación:

1. Abrirla con el destinatario y comprobar fotos en primera y segunda página.
2. Comprobar un ítem sin foto y el icono de su especie. Con una URL vencida,
   comprobar otra consulta de detalle y la recuperación de la imagen.
3. Aceptar solo un animal. En el detalle con «Aceptar seleccionados», marcar
   solo ese animal. En la pantalla habitual con «Aceptar todo» y «Rechazar
   seleccionados», marcar el animal que no se recibirá y usar «Rechazar
   seleccionados»: el resto se acepta. Se conserva el comportamiento y el diseño
   de esos controles. Confirmar que el aceptado
   aparece con foto en la cuenta receptora y que el no seleccionado permanece
   con su dueño original. Registrar los estados devueltos para ambos ítems.
4. Ante un resultado incierto, reintentar la misma decisión sin cambiar versión,
   selección ni clave.

## Reporte de fallo

```text
Paso exacto:
Método y ruta HTTP (sin parámetros firmados):
Estado HTTP:
Mensaje literal del backend (redactar secretos si los contiene):
Fecha y hora: YYYY-MM-DD HH:mm:ss UTC−05:00 (America/Bogota)
ID de transferencia:
Versión del backend desplegada:
Versión/build del frontend:
status de solicitud / items[].status:
transferStatus / readOnly / isActive de las tarjetas:
```

No adjuntar OTP, tokens, proof, cookies ni URLs firmadas. Los registros HTTP
compartidos ocultan los cuerpos de transferencias y animales para evitar que
las fotos firmadas aparezcan en logs; obtener el mensaje del error concreto de
forma controlada, sin copiar la respuesta completa con datos sensibles.
