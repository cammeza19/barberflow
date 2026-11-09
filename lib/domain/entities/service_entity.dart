class ServiceEntity {
  final int? id;
  final String nombre;
  final double precio;
  final int duracionMin;

  const ServiceEntity({
    this.id,
    required this.nombre,
    required this.precio,
    required this.duracionMin,
  });

  ServiceEntity copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? duracionMin,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      duracionMin: duracionMin ?? this.duracionMin,
    );
  }
}
