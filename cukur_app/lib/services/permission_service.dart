import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<Map<String, bool>> requestAllPermissions() async {
    final permissions = await [
      Permission.camera,
      Permission.location,
      Permission.storage,
    ].request();

    return {
      'camera': permissions[Permission.camera]?.isGranted ?? false,
      'location': permissions[Permission.location]?.isGranted ?? false,
      'storage': permissions[Permission.storage]?.isGranted ?? false,
    };
  }

  Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }

  Future<bool> areAllPermissionsGranted() async {
    final camera = await Permission.camera.isGranted;
    final location = await Permission.location.isGranted;
    return camera && location;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
