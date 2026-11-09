import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    super.id,
    required super.nombre,
    required super.precio,
    required super.duracionMin,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      duracionMin: (map['duracionMin'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'precio': precio,
      'duracionMin': duracionMin,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      id: entity.id,
      nombre: entity.nombre,
      precio: entity.precio,
      duracionMin: entity.duracionMin,
    );
  }
}
