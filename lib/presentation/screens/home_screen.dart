import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/barber_repository.dart';
import 'new_appointment_dialog.dart';

class HomeScreen extends StatefulWidget {
  final BarberRepository repository;
  final VoidCallback onNavigateToAppointments;
  final VoidCallback onNavigateToServices;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.onNavigateToAppointments,
    required this.onNavigateToServices,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {
    'totalScheduled': 0,
    'totalPending': 0,
    'totalCompleted': 0,
    'totalCancelled': 0,
    'totalEarnings': 0.0,
  };
  List<AppointmentEntity> _todayAppointments = [];
  late String _currentDateStr;

  @override
  void initState() {
    super.initState();
    _currentDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await widget.repository.getDailyMetrics(_currentDateStr);
      final appointments = await widget.repository.getAppointmentsByDate(_currentDateStr);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _todayAppointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del Dashboard: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openNewAppointmentDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewAppointmentDialog(repository: widget.repository),
    );

    if (result == true) {
      loadData();
    }
  }

  Future<void> _updateStatus(int appointmentId, String newStatus) async {
    try {
      await widget.repository.updateAppointmentStatus(appointmentId, newStatus);
      await loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cita marcada como $newStatus.'),
          backgroundColor: newStatus == 'Completada' ? Colors.green : Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el estado: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDateReadable = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.content_cut, size: 24),
            SizedBox(width: 8),
            Text('BarberFlow Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Saludo y Fecha de Hoy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen Financiero y Operativo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDateReadable[0].toUpperCase() +
                              formattedDateReadable.substring(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta Principal de Balance Diario (Caja Recaudada)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.green.withOpacity(0.15),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Colors.green,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recaudación Hoy (Completadas)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${(_metrics['totalEarnings'] as double).toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fila de Métricas: Total, Pendientes, Completadas
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Citas Hoy',
                          value: '${_metrics['totalScheduled']}',
                          icon: Icons.calendar_today,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Pendientes',
                          value: '${_metrics['totalPending']}',
                          icon: Icons.access_time_filled,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Completadas',
                          value: '${_metrics['totalCompleted']}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Accesos Rápidos
                  Text(
                    'Acciones Rápidas',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openNewAppointmentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Nueva Cita'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onNavigateToServices,
                          icon: const Icon(Icons.design_services),
                          label: const Text('Servicios'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sección: Turnos de Hoy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Turnos Programados Para Hoy',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToAppointments,
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_todayAppointments.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_available, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No hay citas agendadas para el día de hoy.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._todayAppointments.map((cita) => _buildTodayAppointmentItem(cita, theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAppointmentItem(AppointmentEntity cita, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    switch (cita.estado) {
      case 'Completada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Cancelada':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.timelapse;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cita.hora,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          cita.clienteNombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${cita.servicioNombre ?? "Servicio"} • \$${(cita.servicioPrecio ?? 0.0).toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              avatar: Icon(statusIcon, size: 16, color: statusColor),
              label: Text(
                cita.estado,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              backgroundColor: statusColor.withOpacity(0.1),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            if (cita.estado == 'Pendiente')
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  if (cita.id != null) {
                    _updateStatus(cita.id!, action);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'Completada',
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marcar Completada'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Cancelada',
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Marcar Cancelada'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
