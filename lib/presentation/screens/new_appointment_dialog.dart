import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/barber_repository.dart';

class NewAppointmentDialog extends StatefulWidget {
  final BarberRepository repository;

  const NewAppointmentDialog({
    super.key,
    required this.repository,
  });

  @override
  State<NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<NewAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<ServiceEntity> _services = [];
  int? _selectedServiceId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services = await widget.repository.getServices();
      if (mounted) {
        setState(() {
          _services = services;
          if (_services.isNotEmpty) {
            _selectedServiceId = _services.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECCIONE LA FECHA DE LA CITA',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'SELECCIONE LA HORA DE LA CITA',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un servicio del catálogo.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _formatTimeOfDay(_selectedTime);

    try {
      // 1. Control de colisión estricto
      final hasCollision = await widget.repository.hasPendingAppointmentCollision(
        fecha: dateStr,
        hora: timeStr,
      );

      if (hasCollision) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            title: const Text('Horario Ocupado'),
            content: Text(
              'Ya existe un turno en estado "Pendiente" programado para el día $dateStr a las $timeStr.\n\nPor favor, selecciona un horario diferente para evitar solapamientos.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        return;
      }

      // 2. Creación y persistencia de la cita
      final appointment = AppointmentEntity(
        clienteNombre: _nameController.text.trim(),
        clienteTelefono: _phoneController.text.trim(),
        fecha: dateStr,
        hora: timeStr,
        servicioId: _selectedServiceId!,
        estado: 'Pendiente',
      );

      await widget.repository.createAppointment(appointment);

      if (!mounted) return;
      Navigator.of(context).pop(true); // Retorna true para indicar que se creó exitosamente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cita agendada con éxito para ${_nameController.text.trim()}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agendar la cita: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final formattedTime = _formatTimeOfDay(_selectedTime);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const Center(
              heightFactor: 6,
              child: CircularProgressIndicator(),
            )
          : _services.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay servicios registrados en el catálogo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Debes registrar al menos un servicio antes de poder agendar citas.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.content_cut, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Agendar Nuevo Turno',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Nombre del cliente
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Cliente',
                            hintText: 'Ej. Juan Pérez',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre del cliente es obligatorio';
                            }
                            if (value.trim().length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Teléfono del cliente
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono de Contacto',
                            hintText: 'Ej. +57 300 123 4567',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El teléfono de contacto es obligatorio';
                            }
                            if (value.trim().replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
                              return 'Ingrese un número válido con al menos 7 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Dropdown de Servicios
                        DropdownButtonFormField<int>(
                          value: _selectedServiceId,
                          decoration: const InputDecoration(
                            labelText: 'Servicio a Realizar',
                            prefixIcon: Icon(Icons.design_services),
                            border: OutlineInputBorder(),
                          ),
                          items: _services.map((service) {
                            return DropdownMenuItem<int>(
                              value: service.id,
                              child: Text(
                                '${service.nombre} - \$${service.precio.toStringAsFixed(2)} (${service.duracionMin} min)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            setState(() {
                              _selectedServiceId = newVal;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione un servicio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Selección de Fecha y Hora
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.dividerColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Fecha',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                            ),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _selectTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.dividerColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hora',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                            ),
                                            Text(
                                              formattedTime,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _submitAppointment,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isSaving ? 'Validando y Guardando...' : 'Confirmar y Agendar Turno',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
