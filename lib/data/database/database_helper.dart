import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('barberflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Creación de la tabla 'servicios'
    await db.execute('''
      CREATE TABLE servicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        duracionMin INTEGER NOT NULL
      )
    ''');

    // 2. Creación de la tabla 'citas' con clave foránea en cascada
    await db.execute('''
      CREATE TABLE citas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clienteNombre TEXT NOT NULL,
        clienteTelefono TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        servicioId INTEGER NOT NULL,
        estado TEXT NOT NULL,
        FOREIGN KEY (servicioId) REFERENCES servicios (id) ON DELETE CASCADE
      )
    ''');

    // 3. Semilla de datos iniciales (Dummy Data)
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Inserción de 3 servicios base
    final int servicio1Id = await db.insert('servicios', {
      'nombre': 'Corte Clásico',
      'precio': 15.0,
      'duracionMin': 30,
    });

    await db.insert('servicios', {
      'nombre': 'Arreglo de Barba',
      'precio': 10.0,
      'duracionMin': 20,
    });

    final int servicio3Id = await db.insert('servicios', {
      'nombre': 'Combo Completo (Corte + Barba)',
      'precio': 22.0,
      'duracionMin': 45,
    });

    // Fecha actual en formato YYYY-MM-DD
    final now = DateTime.now();
    final String today =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Inserción de 2 citas iniciales para la fecha actual
    await db.insert('citas', {
      'clienteNombre': 'Carlos Mendoza',
      'clienteTelefono': '+57 300 123 4567',
      'fecha': today,
      'hora': '09:00',
      'servicioId': servicio3Id,
      'estado': 'Completada',
    });

    await db.insert('citas', {
      'clienteNombre': 'Andrés Gómez',
      'clienteTelefono': '+57 311 987 6543',
      'fecha': today,
      'hora': '11:30',
      'servicioId': servicio1Id,
      'estado': 'Pendiente',
    });
  }

  // --- Operaciones de Servicios ---

  Future<int> insertService(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('servicios', row);
  }

  Future<List<Map<String, dynamic>>> getAllServices() async {
    final db = await database;
    return await db.query('servicios', orderBy: 'nombre ASC');
  }

  Future<Map<String, dynamic>?> getServiceById(int id) async {
    final db = await database;
    final results = await db.query(
      'servicios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateService(Map<String, dynamic> row) async {
    final db = await database;
    final int id = row['id'] as int;
    return await db.update(
      'servicios',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete(
      'servicios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Operaciones de Citas ---

  Future<int> insertAppointment(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('citas', row);
  }

  Future<List<Map<String, dynamic>>> getAllAppointments({String? filterEstado}) async {
    final db = await database;
    String query = '''
      SELECT c.id, c.clienteNombre, c.clienteTelefono, c.fecha, c.hora, c.servicioId, c.estado,
             s.nombre AS servicioNombre, s.precio AS servicioPrecio
      FROM citas c
      INNER JOIN servicios s ON c.servicioId = s.id
    ''';

    List<dynamic> arguments = [];
    if (filterEstado != null && filterEstado.isNotEmpty && filterEstado != 'Todas') {
      query += ' WHERE c.estado = ?';
      arguments.add(filterEstado);
    }

    query += ' ORDER BY c.fecha ASC, c.hora ASC';

    return await db.rawQuery(query, arguments);
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByDate(String fecha) async {
    final db = await database;
    const String query = '''
      SELECT c.id, c.clienteNombre, c.clienteTelefono, c.fecha, c.hora, c.servicioId, c.estado,
             s.nombre AS servicioNombre, s.precio AS servicioPrecio
      FROM citas c
      INNER JOIN servicios s ON c.servicioId = s.id
      WHERE c.fecha = ?
      ORDER BY c.hora ASC
    ''';
    return await db.rawQuery(query, [fecha]);
  }

  Future<int> updateAppointmentStatus(int id, String newStatus) async {
    final db = await database;
    return await db.update(
      'citas',
      {'estado': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete(
      'citas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Validación de colisión de turnos ---

  Future<bool> hasPendingAppointmentCollision({
    required String fecha,
    required String hora,
    int? excludeId,
  }) async {
    final db = await database;
    String query = '''
      SELECT COUNT(*) as count 
      FROM citas 
      WHERE fecha = ? AND hora = ? AND estado = 'Pendiente'
    ''';
    List<dynamic> args = [fecha, hora];

    if (excludeId != null) {
      query += ' AND id != ?';
      args.add(excludeId);
    }

    final result = await db.rawQuery(query, args);
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  // --- Métricas de Balance y Productividad Diaria ---

  Future<Map<String, dynamic>> getDailyMetrics(String fecha) async {
    final db = await database;

    // 1. Total programadas hoy
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM citas WHERE fecha = ?',
      [fecha],
    );
    final totalScheduled = Sqflite.firstIntValue(totalResult) ?? 0;

    // 2. Citas pendientes hoy
    final pendingResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas WHERE fecha = ? AND estado = 'Pendiente'",
      [fecha],
    );
    final totalPending = Sqflite.firstIntValue(pendingResult) ?? 0;

    // 3. Citas completadas hoy
    final completedResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas WHERE fecha = ? AND estado = 'Completada'",
      [fecha],
    );
    final totalCompleted = Sqflite.firstIntValue(completedResult) ?? 0;

    // 4. Citas canceladas hoy
    final cancelledResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas WHERE fecha = ? AND estado = 'Cancelada'",
      [fecha],
    );
    final totalCancelled = Sqflite.firstIntValue(cancelledResult) ?? 0;

    // 5. Total recaudado por citas completadas hoy
    final earningsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(s.precio), 0.0) as totalEarnings
      FROM citas c
      INNER JOIN servicios s ON c.servicioId = s.id
      WHERE c.fecha = ? AND c.estado = 'Completada'
    ''', [fecha]);

    final double totalEarnings = (earningsResult.first['totalEarnings'] as num?)?.toDouble() ?? 0.0;

    return {
      'totalScheduled': totalScheduled,
      'totalPending': totalPending,
      'totalCompleted': totalCompleted,
      'totalCancelled': totalCancelled,
      'totalEarnings': totalEarnings,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
