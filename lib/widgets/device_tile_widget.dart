import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hcmut_iot/repository/mqtt_manager.dart';

class DeviceTileWidget extends StatefulWidget {
  final String feedName;
  final String deviceName;
  final MQTTManager mqttManager;
  DeviceTileWidget(
      {Key? key,
      required this.feedName,
      required this.deviceName,
      required this.mqttManager})
      : super(key: key);

  @override
  State<DeviceTileWidget> createState() => _DeviceTileWidgetState();
}

class _DeviceTileWidgetState extends State<DeviceTileWidget> {
  double? value;
  String? errorMessage;
  StreamSubscription<dynamic>? _subscription;

  // subscribe to the feed of the device
  @override
  void initState() {
    super.initState();
    _connectAndSubscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _connectAndSubscribe() async {
    print("do we know if he came a lot? Or just the");
    try {
      final topic = 'phucnguyenng/feeds/${widget.feedName}';
      widget.mqttManager.subscribe(topic);
      _subscription = widget.mqttManager.updates(topic).listen((message) {
        if (mounted) {
          setState(() {
            value = double.tryParse(message) ?? 0;
            print(
                "Do we know if he came a lot? Or just the same as an average man, about a tablespoon?");
            errorMessage = null;
          });
        }
      });
    } catch (e) {
      print('Exception while subscribing: $e');
      _subscription = const Stream.empty().listen((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.deepOrange[100],
      ),
      child: ListTile(
          leading: Icon(Icons.thermostat),
          title: Text(widget.deviceName),
          subtitle: Text("Feed: ${widget.feedName}"),
          trailing: Text(
              value != null
                  ? value!.toStringAsFixed(2)
                  : errorMessage ?? 'No data',
              style: TextStyle(
                  color: value != null
                      ? Colors.black
                      : errorMessage != null
                          ? Colors.red
                          : Colors.grey))),
    );
  }
}
