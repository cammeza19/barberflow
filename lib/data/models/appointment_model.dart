import '../../domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    super.id,
    required super.clienteNombre,
    required super.clienteTelefono,
    required super.fecha,
    required super.hora,
    required super.servicioId,
    required super.estado,
    super.servicioNombre,
    super.servicioPrecio,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as int?,
      clienteNombre: map['clienteNombre'] as String,
      clienteTelefono: map['clienteTelefono'] as String,
      fecha: map['fecha'] as String,
      hora: map['hora'] as String,
      servicioId: (map['servicioId'] as num).toInt(),
      estado: map['estado'] as String,
      servicioNombre: map['servicioNombre'] as String?,
      servicioPrecio: map['servicioPrecio'] != null
          ? (map['servicioPrecio'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'clienteNombre': clienteNombre,
      'clienteTelefono': clienteTelefono,
      'fecha': fecha,
      'hora': hora,
      'servicioId': servicioId,
      'estado': estado,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AppointmentModel.fromEntity(AppointmentEntity entity) {
    return AppointmentModel(
      id: entity.id,
      clienteNombre: entity.clienteNombre,
      clienteTelefono: entity.clienteTelefono,
      fecha: entity.fecha,
      hora: entity.hora,
      servicioId: entity.servicioId,
      estado: entity.estado,
      servicioNombre: entity.servicioNombre,
      servicioPrecio: entity.servicioPrecio,
    );
  }
}
