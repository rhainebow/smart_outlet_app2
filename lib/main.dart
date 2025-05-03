// lib/main.dart

import 'package:flutter/material.dart';
import 'mqtt_service.dart';
import 'db_helper.dart';
import 'daily_usage_screen.dart';
import 'prediction_insights.dart';
import 'notification_screen.dart';
import 'dart:convert';

/// Global notifier for notifications
final ValueNotifier<List<String>> notifications = ValueNotifier([]);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Outlet',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final mqtt = MQTTService();
  final db = DBHelper();

  double _kwh1 = 0, _lim1 = 0;
  String _hrs1 = '00:00';

  double _kwh2 = 0, _lim2 = 0;
  String _hrs2 = '00:00';

  @override
  void initState() {
    super.initState();
    mqtt.onMessage = _handle;
    mqtt.connect(); // connect() now subscribes to smart_outlet/outlet_1 & …/outlet_2
  }

  void _handle(String topic, String payload) {
    // decode JSON
    final p = json.decode(payload) as Map<String, dynamic>;
    final kwh    = (p['kwh'] as num).toDouble();
    final hrsStr = p['hours'] as String; // e.g. "02:30"

    // parse "HH:MM" → numeric hours
    final parts = hrsStr.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final hoursNumeric = h + (m / 60);

    // save reading (outlet topic used as key)
    db.insertReading(topic, kwh, hoursNumeric);

    // choose which outlet to update
    if (topic.endsWith('outlet_1')) {
      if (_lim1 > 0 && kwh > _lim1) {
        notifications.value = [
          ...notifications.value,
          '⚠️ Outlet 1 over limit: ${kwh.toStringAsFixed(2)} kWh'
        ];
      }
      setState(() {
        _kwh1 = kwh;
        _hrs1 = hrsStr;
      });
    } else if (topic.endsWith('outlet_2')) {
      if (_lim2 > 0 && kwh > _lim2) {
        notifications.value = [
          ...notifications.value,
          '⚠️ Outlet 2 over limit: ${kwh.toStringAsFixed(2)} kWh'
        ];
      }
      setState(() {
        _kwh2 = kwh;
        _hrs2 = hrsStr;
      });
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Outlet'),
        backgroundColor: const Color(0xFF0A9B88),
        actions: [
          // Connection indicator
          ValueListenableBuilder<bool>(
            valueListenable: mqtt.isConnected,
            builder: (_, connected, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                connected ? Icons.cloud_done : Icons.cloud_off,
                color: connected
                    ? Colors.lightGreenAccent
                    : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1EBEA5), Color(0xFF0A9B88)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutletCard(
              name: 'Outlet 1',
              kwh: _kwh1,
              hrsLabel: _hrs1,
              limit: _lim1,
              onLimit: (v) => setState(() => _lim1 = v),
            ),
            const SizedBox(height: 16),
            OutletCard(
              name: 'Outlet 2',
              kwh: _kwh2,
              hrsLabel: _hrs2,
              limit: _lim2,
              onLimit: (v) => setState(() => _lim2 = v),
            ),
            const SizedBox(height: 24),
            MenuButton('Daily Usage', () {
              Navigator.push(
                  c,
                  MaterialPageRoute(
                      builder: (_) => const DailyUsageScreen()));
            }),
            const SizedBox(height: 16),
            MenuButton('Prediction Insights', () {
              Navigator.push(
                  c,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PredictionInsights(outletId: '1')));
            }),
            const SizedBox(height: 16),
            MenuButton('Notifications', () {
              Navigator.push(
                  c,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()));
            }),
          ],
        ),
      ),
    );
  }
}

/// ─── SHARED WIDGETS ─────────────────────────────────────────

class OutletCard extends StatelessWidget {
  final String name;
  final double kwh;
  final String hrsLabel;
  final double limit;
  final ValueChanged<double> onLimit;

  const OutletCard({
    required this.name,
    required this.kwh,
    required this.hrsLabel,
    required this.limit,
    required this.onLimit,
    super.key,
  });

  @override
  Widget build(BuildContext c) => Card(
        color: Colors.white.withAlpha(230),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 8),
              Text('${kwh.toStringAsFixed(3)} kWh',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 4),
              Text('Hours: $hrsLabel',
                  style: const TextStyle(fontSize: 16, color: Colors.black)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Limit: ${limit.toStringAsFixed(2)} kWh',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black)),
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => showDialog(
                            context: c,
                            builder: (_) {
                              final ctl =
                                  TextEditingController(text: limit.toString());
                              return AlertDialog(
                                title: const Text('Set limit (kWh)'),
                                content: TextField(
                                  controller: ctl,
                                  keyboardType: TextInputType.number,
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('Cancel')),
                                  ElevatedButton(
                                      onPressed: () {
                                        onLimit(double.tryParse(ctl.text) ??
                                            limit);
                                        Navigator.pop(c);
                                      },
                                      child: const Text('Save'))
                                ],
                              );
                            },
                          )),
                ],
              ),
            ],
          ),
        ),
      );
}

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const MenuButton(this.text, this.onTap, {super.key});

  @override
  Widget build(BuildContext c) => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(230),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onTap,
          child: Text(text,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
      );
}
