String transferStatusLabel(String status) => switch (status) {
  'PENDING' => 'Pendiente',
  'PROCESSING' => 'Traspaso en curso',
  'ACCEPTED' => 'Aceptado',
  'PARTIALLY_ACCEPTED' => 'Aceptado parcialmente',
  'REJECTED' => 'Rechazado',
  _ => status,
};
