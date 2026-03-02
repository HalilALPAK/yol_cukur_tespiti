import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pothole_provider.dart';
import '../services/permission_service.dart';
import 'camera_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _permissionsGranted = false;
  bool _checkingPermissions = true;
  final PermissionService _permissionService = PermissionService();

  final List<Widget> _screens = [
    const CameraScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay permission check to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!mounted) return;
    
    setState(() {
      _checkingPermissions = true;
    });

    try {
      final permissions = await _permissionService.requestAllPermissions();
      final granted = permissions['camera'] == true && permissions['location'] == true;

      if (!mounted) return;
      
      setState(() {
        _permissionsGranted = granted;
        _checkingPermissions = false;
      });

      if (granted && mounted) {
        // Initialize the model
        context.read<PotholeProvider>().initialize();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingPermissions = false;
        _permissionsGranted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepOrange.shade400,
                Colors.deepOrange.shade800,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'İzinler kontrol ediliyor...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepOrange.shade400,
                Colors.deepOrange.shade800,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'İzinler Gerekli',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uygulamanın düzgün çalışması için kamera ve konum izinleri gereklidir.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _PermissionItem(
                    icon: Icons.camera_alt,
                    title: 'Kamera',
                    description: 'Çukurları tespit etmek için',
                  ),
                  const SizedBox(height: 16),
                  _PermissionItem(
                    icon: Icons.location_on,
                    title: 'Konum',
                    description: 'Çukur konumlarını kaydetmek için',
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _checkAndRequestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'İzinleri Ver',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.camera_alt_outlined),
            selectedIcon: const Icon(Icons.camera_alt),
            label: 'Tespit',
          ),
          NavigationDestination(
            icon: Badge(
              label: Consumer<PotholeProvider>(
                builder: (context, provider, child) {
                  return Text('${provider.detections.length}');
                },
              ),
              isLabelVisible: true,
              child: const Icon(Icons.map_outlined),
            ),
            selectedIcon: Badge(
              label: Consumer<PotholeProvider>(
                builder: (context, provider, child) {
                  return Text('${provider.detections.length}');
                },
              ),
              isLabelVisible: true,
              child: const Icon(Icons.map),
            ),
            label: 'Harita',
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
