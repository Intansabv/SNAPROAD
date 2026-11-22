import 'classifier_service.dart';
import 'database_service.dart';
import 'location_service.dart';

/// Akses sederhana ke layanan global (cukup untuk aplikasi sekecil ini).
class AppServices {
  AppServices._();

  static final classifier = ClassifierService();
  static final db = DatabaseService();
  static final location = LocationService();
}
