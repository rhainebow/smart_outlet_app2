// lib/mqtt_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient _client;

  /// Called on every incoming message (after parsing).
  Function(String topic, String payload)? onMessage;

  /// True when connected, false otherwise.
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  Future<void> connect() async {
    // 🛠 Change this to match where your broker really lives
    // • Emulator: use "10.0.2.2"
    // • Real device on same LAN: use the LAN IP (e.g. "192.168.4.1")
    const server = '192.168.4.1';

    _client = MqttServerClient(server, 'flutter_client')
      ..port = 1883
      ..keepAlivePeriod = 20
      ..setProtocolV311()
      ..autoReconnect = true
      ..logging(on: true) // 🔥 TURN ON FOR FULL PROTOCOL LOGGING
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier('flutter_client')
          .startClean();

    // update our notifier
    _client.onConnected    = () => isConnected.value = true;
    _client.onDisconnected = () => isConnected.value = false;

    // listen raw messages
    _client.updates?.listen((msgs) {
      final rec = msgs[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(rec.payload.message);

      debugPrint("⟡ MQTT ← topic=${msgs[0].topic} payload=$payload");
      onMessage?.call(msgs[0].topic, payload);
    });

    try {
      final status = await _client.connect();
      if (_client.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('✅ MQTT Connected, subscribing…');
        _client.subscribe('smart_outlet/outlet_1', MqttQos.atMostOnce);
        _client.subscribe('smart_outlet/outlet_2', MqttQos.atMostOnce);
      } else {
        debugPrint('⚠️ MQTT CONNECTED BUT BAD STATE: ${status!.state}');
        isConnected.value = false;
        _client.disconnect();
      }
    } on SocketException catch (e) {
      debugPrint('❌ MQTT SocketException: $e');
      isConnected.value = false;
    } catch (e) {
      debugPrint('❌ MQTT connection failed: $e');
      isConnected.value = false;
      _client.disconnect();
    }
  }

  /// If you ever need to re-subscribe at runtime
  void subscribe(String topic) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('🔂 MQTT re-subscribing to $topic');
      _client.subscribe(topic, MqttQos.atMostOnce);
    }
  }
}
