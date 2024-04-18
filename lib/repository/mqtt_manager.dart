// ignore_for_file: avoid_print

import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager {
  late MqttServerClient client;

  final _controllers = <String, StreamController<String>>{};

  Stream<String> updates(String topic) {
    return _controllers[topic]!.stream;
  }

  MQTTManager(String username, String aioKey, String clientId) {
    client = MqttServerClient('io.adafruit.com', clientId);
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, aioKey);
    // .startClean(); // Non persistent session for testing
  }

  Future<void> connect() async {
    print('Connecting to Adafruit IO...');
    try {
      await client.connect();
    } catch (e) {
      print('Exception while connecting: $e');
      client.disconnect();
    }

    // Wait until the client is connected before completing the Future
    while (client.connectionStatus?.state != MqttConnectionState.connected) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> publish(String topic, String message) async {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('MQTT client is not connected, attempting to reconnect...');
      await connect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      print('MQTT client is not connected, cannot publish message');
    }
  }

  void disconnect() {
    client.disconnect();
  }

  // Connection callback
  void onConnected() {
    print('Connected');
  }

  // Disconnected callback
  void onDisconnected() {
    print('Disconnected');
  }

  // Subscribed callback
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  // Subscribe to a topic
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> subscribe(
      String topic) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      throw Exception(
          'MQTT client is not connected, cannot subscribe to topic');
    }

    client.subscribe(topic, MqttQos.atLeastOnce);

    _controllers[topic] = StreamController<String>.broadcast();

    return client.updates!.listen(
      (List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        // Check if the message is for the correct topic
        if (c[0].topic == topic) {
          print("Received message: $message from topic: $topic");
          _controllers[topic]!.add(message);
        }
      },
      onError: (e) {
        print('Error when receiving message: $e');
      },
    );
  }

  // dispose
  void dispose() {
    _controllers.values.forEach((controller) => controller.close());
    client.disconnect();
  }
}
