import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'screens/map_screen.dart';
import 'screens/camera_screen.dart';
import 'utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeManager = ThemeManager();
  await Future.delayed(const Duration(milliseconds: 500)); // Splash-Screen-Simulation
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeManager,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          title: 'EU Flag Mapper v2',
          themeMode: themeManager.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 2,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 2,
            ),
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const MapScreen(),
    const CameraScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: colorScheme.primary.withOpacity(0.3))
              .animate(target: _selectedIndex == 0 ? 1.0 : 0.0)
              .animate()
              .scale(
                duration: const Duration(milliseconds: 300),
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
              ),
            label: 'Karte',
          ),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: colorScheme.primary.withOpacity(0.3))
              .animate(target: _selectedIndex == 1 ? 1.0 : 0.0)
              .animate()
              .scale(
                duration: const Duration(milliseconds: 300),
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
              ),
            label: 'Kamera',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ThemeManager>().toggleTheme(),
        child: Icon(isDark ? Icons.light_mode : Icons.dark_mode)
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 2000.ms, color: colorScheme.primary.withOpacity(0.3)),
      ),
    );
  }
}
