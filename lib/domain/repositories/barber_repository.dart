import '../entities/service_entity.dart';
import '../entities/appointment_entity.dart';

abstract class BarberRepository {
  // Operaciones de Servicios
  Future<List<ServiceEntity>> getServices();
  Future<ServiceEntity?> getServiceById(int id);
  Future<int> createService(ServiceEntity service);
  Future<int> updateService(ServiceEntity service);
  Future<int> deleteService(int id);

  // Operaciones de Citas
  Future<List<AppointmentEntity>> getAppointments({String? filterEstado});
  Future<List<AppointmentEntity>> getAppointmentsByDate(String fecha);
  Future<int> createAppointment(AppointmentEntity appointment);
  Future<int> updateAppointmentStatus(int id, String newStatus);
  Future<int> deleteAppointment(int id);

  // Reglas de Negocio / Validaciones
  Future<bool> hasPendingAppointmentCollision({
    required String fecha,
    required String hora,
    int? excludeId,
  });

  // Métricas financieras y de productividad diaria
  Future<Map<String, dynamic>> getDailyMetrics(String fecha);
}
