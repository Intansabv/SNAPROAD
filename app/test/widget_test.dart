import 'package:flutter_test/flutter_test.dart';
import 'package:snaproad/models/detection.dart';

void main() {
  test('Severity.fromKey memetakan label dengan benar', () {
    expect(Severity.fromKey('Ringan'), Severity.ringan);
    expect(Severity.fromKey(' berat '), Severity.berat);
    expect(Severity.fromKey('xyz'), isNull);
  });

  test('Urutan Severity sama dengan labels.txt notebook', () {
    expect(
      Severity.values.map((s) => s.key).toList(),
      ['ringan', 'sedang', 'berat'],
    );
  });

  test('ClassificationResult memilih kelas teratas', () {
    const r = ClassificationResult(
      scores: {Severity.ringan: 0.1, Severity.sedang: 0.2, Severity.berat: 0.7},
      inferenceMs: 5,
    );
    expect(r.top, Severity.berat);
    expect(r.confidence, 0.7);
    expect(r.isConfident, isTrue);
  });

  test('Hasil di bawah ambang dianggap belum yakin', () {
    const r = ClassificationResult(
      scores: {Severity.ringan: 0.4, Severity.sedang: 0.35, Severity.berat: 0.25},
      inferenceMs: 5,
    );
    expect(r.isConfident, isFalse);
  });

  test('DetectionRecord toMap/fromMap round-trip', () {
    final rec = DetectionRecord(
      id: 1,
      imagePath: '/tmp/a.jpg',
      severity: Severity.sedang,
      confidence: 0.82,
      scores: const {Severity.ringan: 0.1, Severity.sedang: 0.82, Severity.berat: 0.08},
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      latitude: -7.63,
      longitude: 111.52,
      accuracy: 12,
    );
    final back = DetectionRecord.fromMap(rec.toMap());
    expect(back.severity, Severity.sedang);
    expect(back.scores[Severity.sedang], 0.82);
    expect(back.hasLocation, isTrue);
    expect(back.createdAt, rec.createdAt);
  });
}
