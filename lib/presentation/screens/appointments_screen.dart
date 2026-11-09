import 'package:flutter/material.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/barber_repository.dart';
import 'new_appointment_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  final BarberRepository repository;

  const AppointmentsScreen({
    super.key,
    required this.repository,
  });

  @override
  State<AppointmentsScreen> createState() => AppointmentsScreenState();
}

class AppointmentsScreenState extends State<AppointmentsScreen> {
  String _selectedFilter = 'Todas';
  final List<String> _filters = ['Todas', 'Pendientes', 'Completadas', 'Canceladas'];
  List<AppointmentEntity> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      String? filterParam;
      if (_selectedFilter == 'Pendientes') {
        filterParam = 'Pendiente';
      } else if (_selectedFilter == 'Completadas') {
        filterParam = 'Completada';
      } else if (_selectedFilter == 'Canceladas') {
        filterParam = 'Cancelada';
      }

      final list = await widget.repository.getAppointments(filterEstado: filterParam);
      if (mounted) {
        setState(() {
          _appointments = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la agenda de citas: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openNewAppointmentDialog() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewAppointmentDialog(repository: widget.repository),
    );

    if (created == true) {
      loadAppointments();
    }
  }

  Future<void> _updateStatus(int appointmentId, String newStatus) async {
    try {
      await widget.repository.updateAppointmentStatus(appointmentId, newStatus);
      await loadAppointments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "$newStatus".'),
          backgroundColor: newStatus == 'Completada' ? Colors.green : Colors.grey[800],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteAppointment(AppointmentEntity appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente la cita de ${appointment.clienteNombre} (${appointment.fecha} a las ${appointment.hora})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && appointment.id != null) {
      try {
        await widget.repository.deleteAppointment(appointment.id!);
        await loadAppointments();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita eliminada correctamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cita: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: loadAppointments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewAppointmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agendar Cita'),
      ),
      body: Column(
        children: [
          // Filtros tipo chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          loadAppointments();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Listado de Citas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: theme.disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron citas ($_selectedFilter).',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pulsa el botón "+" para programar un nuevo turno.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadAppointments,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _appointments[index];
                            return _buildAppointmentCard(appointment, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentEntity appointment, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    switch (appointment.estado) {
      case 'Completada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Cancelada':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.timelapse;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la Cita: Fecha, Hora y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            appointment.fecha,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            appointment.hora,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Chip(
                  avatar: Icon(statusIcon, size: 16, color: statusColor),
                  label: Text(
                    appointment.estado,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nombre del Cliente y Teléfono
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    appointment.clienteNombre.isNotEmpty
                        ? appointment.clienteNombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clienteNombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            appointment.clienteTelefono,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Precio del Servicio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${(appointment.servicioPrecio ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      appointment.servicioNombre ?? 'Servicio',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Botones de Acción sobre la cita
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.estado == 'Pendiente') ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      if (appointment.id != null) {
                        _updateStatus(appointment.id!, 'Completada');
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Completar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      if (appointment.id != null) {
                        _updateStatus(appointment.id!, 'Cancelada');
                      }
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Eliminar Cita',
                  onPressed: () => _deleteAppointment(appointment),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
