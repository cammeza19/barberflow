import 'package:flutter/material.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/barber_repository_impl.dart';
import 'domain/repositories/barber_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/appointments_screen.dart';
import 'presentation/screens/services_screen.dart';
import 'presentation/screens/new_appointment_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de la capa de datos y repositorio
  final databaseHelper = DatabaseHelper.instance;
  await databaseHelper.database;

  final BarberRepository repository = BarberRepositoryImpl(databaseHelper: databaseHelper);

  runApp(BarberFlowApp(repository: repository));
}

class BarberFlowApp extends StatelessWidget {
  final BarberRepository repository;

  const BarberFlowApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFD4AF37); // Tono Dorado / Ámbar Barbería

    return MaterialApp(
      title: 'BarberFlow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      // Tema Claro Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
          primary: const Color(0xFFB8860B),
          secondary: const Color(0xFF2C3E50),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 3,
        ),
      ),
      // Tema Oscuro Material 3 Elegante
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121417),
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          primary: const Color(0xFFE5A93C),
          surface: const Color(0xFF1E2228),
          surfaceContainerHighest: const Color(0xFF282D36),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121417),
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E2228),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1D23),
          selectedItemColor: Color(0xFFE5A93C),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: MainNavigationContainer(repository: repository),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  final BarberRepository repository;

  const MainNavigationContainer({super.key, required this.repository});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<AppointmentsScreenState> _appointmentsKey = GlobalKey<AppointmentsScreenState>();
  final GlobalKey<ServicesScreenState> _servicesKey = GlobalKey<ServicesScreenState>();

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      _homeKey.currentState?.loadData();
    } else if (index == 1) {
      _appointmentsKey.currentState?.loadAppointments();
    } else if (index == 2) {
      _servicesKey.currentState?.loadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        key: _homeKey,
        repository: widget.repository,
        onNavigateToAppointments: () => _onTabSelected(1),
        onNavigateToServices: () => _onTabSelected(2),
      ),
      AppointmentsScreen(
        key: _appointmentsKey,
        repository: widget.repository,
      ),
      ServicesScreen(
        key: _servicesKey,
        repository: widget.repository,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            selectedIcon: Icon(Icons.design_services),
            label: 'Servicios',
          ),
        ],
      ),
    );
  }
}