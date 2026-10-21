enum MedicalDocumentAiFeedback {
  like('LIKE'),
  dislike('DISLIKE');

  final String wireValue;

  const MedicalDocumentAiFeedback(this.wireValue);
}
