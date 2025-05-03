// lib/daily_usage_screen.dart

import 'package:flutter/material.dart';
import 'db_helper.dart';              // ← relative import of your helper

/// 1) Define your model
class DailyLog {
  final DateTime date;
  final double outlet1Kwh, outlet1Hours;
  final double outlet2Kwh, outlet2Hours;

  DailyLog({
    required this.date,
    required this.outlet1Kwh,
    required this.outlet1Hours,
    required this.outlet2Kwh,
    required this.outlet2Hours,
  });
}

class DailyUsageScreen extends StatefulWidget {
  const DailyUsageScreen({super.key});

  @override
  State<DailyUsageScreen> createState() => _DailyUsageScreenState();
}

class _DailyUsageScreenState extends State<DailyUsageScreen> {
  late Future<List<DailyLog>> _futureLogs;

  @override
  void initState() {
    super.initState();
    _futureLogs = _loadLogs();
  }

  /// 2) Fetch today’s readings from SQLite and map into DailyLog
  Future<List<DailyLog>> _loadLogs() async {
    final db = DBHelper();

    // get all readings since midnight for outlet_1 and outlet_2
    final rows1 = await db.getDaily('outlet_1');
    final rows2 = await db.getDaily('outlet_2');

    // build one DailyLog per entry (you can group by date if you prefer)
    final allRows = <Map<String,dynamic>>[
      ...rows1.map((r) => {...r, 'outlet': 'outlet_1'}),
      ...rows2.map((r) => {...r, 'outlet': 'outlet_2'}),
    ];

    return allRows.map((r) {
      final date = DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int);
      if (r['outlet'] == 'outlet_1') {
        return DailyLog(
          date: date,
          outlet1Kwh: r['kwh']   as double,
          outlet1Hours: r['hours'] as double,
          outlet2Kwh: 0.0,
          outlet2Hours: 0.0,
        );
      } else {
        return DailyLog(
          date: date,
          outlet1Kwh: 0.0,
          outlet1Hours: 0.0,
          outlet2Kwh: r['kwh']   as double,
          outlet2Hours: r['hours'] as double,
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Usage Log')),
      body: FutureBuilder<List<DailyLog>>(
        future: _futureLogs,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No data for today.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    '${log.date.month}/${log.date.day}/${log.date.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Outlet 1: ${log.outlet1Kwh.toStringAsFixed(3)} kWh, '
                    '${log.outlet1Hours.toStringAsFixed(2)} hrs\n'
                    'Outlet 2: ${log.outlet2Kwh.toStringAsFixed(3)} kWh, '
                    '${log.outlet2Hours.toStringAsFixed(2)} hrs',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
