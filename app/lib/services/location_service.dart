import 'package:geolocator/geolocator.dart';

enum LocationStatus { ok, serviceOff, denied, deniedForever, error }

class LocationResult {
  const LocationResult(this.status, [this.position]);
  final LocationStatus status;
  final Position? position;

  bool get ok => status == LocationStatus.ok && position != null;

  String get message {
    switch (status) {
      case LocationStatus.ok:
        return 'Lokasi tersedia';
      case LocationStatus.serviceOff:
        return 'GPS/lokasi di perangkat sedang mati.';
      case LocationStatus.denied:
        return 'Izin lokasi ditolak.';
      case LocationStatus.deniedForever:
        return 'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan.';
      case LocationStatus.error:
        return 'Lokasi tidak dapat diambil. Coba lagi di tempat terbuka.';
    }
  }
}

/// GPS bersifat opsional: aplikasi tetap berfungsi penuh tanpa lokasi.
class LocationService {
  /// True jika izin lokasi belum pernah diminta (untuk menampilkan dialog penjelasan dulu).
  Future<bool> needsPermissionPrompt() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.denied;
  }

  Future<LocationResult> getCurrent() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceOff);
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(LocationStatus.ok, pos);
    } catch (_) {
      return const LocationResult(LocationStatus.error);
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
