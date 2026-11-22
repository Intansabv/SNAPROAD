import 'package:flutter/material.dart';

import '../models/detection.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'home_screen.dart' show DetectionTile;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Severity? _filter;
  List<DetectionRecord> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppServices.db.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppServices.db.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await AppServices.db.all(severity: _filter);
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  void _setFilter(Severity? value) {
    setState(() => _filter = value);
    _load();
  }

  /// Susun daftar: header tanggal + item.
  List<Object> _grouped() {
    final out = <Object>[];
    String? lastLabel;
    for (final r in _items) {
      final label = Fmt.dayLabel(r.createdAt);
      if (label != lastLabel) {
        out.add(label);
        lastLabel = label;
      }
      out.add(r);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _grouped();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Riwayat Deteksi',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Text(
              'Dokumentasi Anda, tersimpan lokal.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _filter == null,
                  onTap: () => _setFilter(null),
                ),
                for (final s in Severity.values)
                  _FilterChip(
                    label: s.label,
                    selected: _filter == s,
                    onTap: () => _setFilter(s),
                    color: s.color,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: EmptyState(
                            icon: Icons.history,
                            title: _filter == null
                                ? 'Belum ada riwayat'
                                : 'Tidak ada hasil "${_filter!.label}"',
                            message: _filter == null
                                ? 'Hasil yang Anda simpan akan muncul di sini.'
                                : 'Coba pilih filter lain.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final item = rows[i];
                          if (item is String) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 10),
                              child: SectionLabel(item),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DetectionTile(record: item as DetectionRecord),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.cyan,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.cyanSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
