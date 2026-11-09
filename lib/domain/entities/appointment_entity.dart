class AppointmentEntity {
  final int? id;
  final String clienteNombre;
  final String clienteTelefono;
  final String fecha; // Formato YYYY-MM-DD
  final String hora;  // Formato HH:mm
  final int servicioId;
  final String estado; // 'Pendiente', 'Completada', 'Cancelada'

  // Datos relacionales opcionales para visualización
  final String? servicioNombre;
  final double? servicioPrecio;

  const AppointmentEntity({
    this.id,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.fecha,
    required this.hora,
    required this.servicioId,
    required this.estado,
    this.servicioNombre,
    this.servicioPrecio,
  });

  AppointmentEntity copyWith({
    int? id,
    String? clienteNombre,
    String? clienteTelefono,
    String? fecha,
    String? hora,
    int? servicioId,
    String? estado,
    String? servicioNombre,
    double? servicioPrecio,
  }) {
    return AppointmentEntity(
      id: id ?? this.id,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      servicioId: servicioId ?? this.servicioId,
      estado: estado ?? this.estado,
      servicioNombre: servicioNombre ?? this.servicioNombre,
      servicioPrecio: servicioPrecio ?? this.servicioPrecio,
    );
  }
}
