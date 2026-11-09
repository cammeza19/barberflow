import '../../domain/entities/service_entity.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/barber_repository.dart';
import '../database/database_helper.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';

class BarberRepositoryImpl implements BarberRepository {
  final DatabaseHelper databaseHelper;

  BarberRepositoryImpl({required this.databaseHelper});

  @override
  Future<List<ServiceEntity>> getServices() async {
    final list = await databaseHelper.getAllServices();
    return list.map((map) => ServiceModel.fromMap(map)).toList();
  }

  @override
  Future<ServiceEntity?> getServiceById(int id) async {
    final map = await databaseHelper.getServiceById(id);
    if (map != null) {
      return ServiceModel.fromMap(map);
    }
    return null;
  }

  @override
  Future<int> createService(ServiceEntity service) async {
    final model = ServiceModel.fromEntity(service);
    return await databaseHelper.insertService(model.toMap());
  }

  @override
  Future<int> updateService(ServiceEntity service) async {
    final model = ServiceModel.fromEntity(service);
    return await databaseHelper.updateService(model.toMap());
  }

  @override
  Future<int> deleteService(int id) async {
    return await databaseHelper.deleteService(id);
  }

  @override
  Future<List<AppointmentEntity>> getAppointments({String? filterEstado}) async {
    final list = await databaseHelper.getAllAppointments(filterEstado: filterEstado);
    return list.map((map) => AppointmentModel.fromMap(map)).toList();
  }

  @override
  Future<List<AppointmentEntity>> getAppointmentsByDate(String fecha) async {
    final list = await databaseHelper.getAppointmentsByDate(fecha);
    return list.map((map) => AppointmentModel.fromMap(map)).toList();
  }

  @override
  Future<int> createAppointment(AppointmentEntity appointment) async {
    // Validación estricta de colisión a nivel de repositorio
    final hasCollision = await hasPendingAppointmentCollision(
      fecha: appointment.fecha,
      hora: appointment.hora,
    );

    if (hasCollision) {
      throw Exception('Conflicto de horario: Ya existe un turno pendiente para el día ${appointment.fecha} a las ${appointment.hora}.');
    }

    final model = AppointmentModel.fromEntity(appointment);
    return await databaseHelper.insertAppointment(model.toMap());
  }

  @override
  Future<int> updateAppointmentStatus(int id, String newStatus) async {
    return await databaseHelper.updateAppointmentStatus(id, newStatus);
  }

  @override
  Future<int> deleteAppointment(int id) async {
    return await databaseHelper.deleteAppointment(id);
  }

  @override
  Future<bool> hasPendingAppointmentCollision({
    required String fecha,
    required String hora,
    int? excludeId,
  }) async {
    return await databaseHelper.hasPendingAppointmentCollision(
      fecha: fecha,
      hora: hora,
      excludeId: excludeId,
    );
  }

  @override
  Future<Map<String, dynamic>> getDailyMetrics(String fecha) async {
    return await databaseHelper.getDailyMetrics(fecha);
  }
}
