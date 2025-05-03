import 'package:flutter/material.dart';

class PredictionInsights extends StatelessWidget {
  final String outletId;

  const PredictionInsights({super.key, required this.outletId});

  @override
  Widget build(BuildContext context) {
    // Static sample prediction (replace with real logic from SQLite, MQTT, etc.)
    final double predictedPower = 0.15; // in kW
    final double monthlyUsage = predictedPower * 24 * 30; // kWh estimate
    final double cost = monthlyUsage * 9.7545; // Cost in PHP

    String tip;
    if (monthlyUsage > 4) {
      tip = 'Consider significant usage reduction during peak hours';
    } else if (monthlyUsage > 2) {
      tip = 'Consider reducing usage during peak hours';
    } else {
      tip = 'Your energy usage is within normal range';
    }

    // Simple date string using Dart only
    final now = DateTime.now();
    final String dateStr = "${now.month}/${now.day}/${now.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediction Insights"),
        backgroundColor: const Color(0xFF0A9B88),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1EBEA5), Color(0xFF0A9B88)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _buildPredictionCard(context, monthlyUsage, cost, tip, dateStr),
        ),
      ),
    );
  }

  Widget _buildPredictionCard(
    BuildContext context,
    double usage,
    double cost,
    String tip,
    String dateStr,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly's Predicted Usage",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Usage: ${usage.toStringAsFixed(2)} kWh",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Cost: Php ${cost.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Tip:\n$tip",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Last updated: $dateStr",
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
