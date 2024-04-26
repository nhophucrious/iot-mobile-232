import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hcmut_iot/repository/data_repository.dart';
import 'package:hcmut_iot/repository/mqtt_manager.dart';
import 'package:hcmut_iot/repository/user_defaults_repository.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SensorDetailScreen extends StatefulWidget {
  String feedName;
  String sensorName;
  SensorDetailScreen(
      {Key? key, required this.feedName, required this.sensorName})
      : super(key: key);

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  DataRepository dataRepository = DataRepository();
  List<dynamic> data = [];
  MQTTManager? manager;
  final StreamController<List<ChartData>> _dataStreamController =
      StreamController<List<ChartData>>.broadcast();
  late Future<List<ChartData>> initialData;
  String latestValue = '';

  @override
  void initState() {
    super.initState();
    initialData = fetchData();
    fetchLatestValue();
    initMQTT();
  }

  Future<void> fetchLatestValue() async {
    var username = await UserDefaultsRepository.getUsername() as String;
    var latestValueString =
        await dataRepository.fetchLatestData(username, widget.feedName);
    var myjson = (jsonDecode(latestValueString));
    var value = myjson[0]['value'];
    setState(() {
      latestValue = value.toString();
    });
  }

  Future<List<ChartData>> fetchData() async {
    var username = await UserDefaultsRepository.getUsername() as String;
    var test = (await dataRepository.fetchData(username, widget.feedName));
    var myjson = (jsonDecode(test));
    data = myjson;
    data.sort((a, b) => DateTime.parse(a['created_at'])
        .compareTo(DateTime.parse(b['created_at'])));
    return data.map((item) {
      return ChartData(
        DateTime.parse(item['created_at']),
        double.parse(item['value'].toString()),
      );
    }).toList();
  }

  Future<void> initMQTT() async {
    var username = await UserDefaultsRepository.getUsername() as String;
    var key = await UserDefaultsRepository.getKey() as String;
    const String clientId = 'hcmut_iot_indie';
    manager = MQTTManager(username, key, clientId);
    await manager!.connect();

    String topic = '$username/feeds/${widget.feedName}';
    manager!.subscribe(topic);

    manager!.updates(topic).listen((message) {
      setState(() {
        latestValue = message;
        data.add({
          'created_at': DateTime.now().toIso8601String(),
          'value': message,
        });
        _dataStreamController.add(data.map((item) {
          return ChartData(
            DateTime.parse(item['created_at']),
            double.parse(item['value'].toString()),
          );
        }).toList());
      });
      print(data);
    });
  }

  @override
  void dispose() {
    super.dispose();
    manager?.disconnect();
    _dataStreamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sensorName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05),
              child: const Text(
                "Live Data",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05),
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05),
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(16)),
            height: 150,
            child: Center(
                child: Text(latestValue == '' ? 'Loading...' : latestValue,
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 32))),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05),
              child: const Text(
                "History",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          FutureBuilder<List<ChartData>>(
            future: initialData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                return StreamBuilder<List<ChartData>>(
                  initialData: snapshot.data,
                  stream: _dataStreamController.stream,
                  builder: (context, snapshot) {
                    return SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('dd/MM HH:mm'),
                      ),
                      series: <ChartSeries>[
                        LineSeries<ChartData, DateTime>(
                          color: Theme.of(context).primaryColor,
                          width: 3,
                          dataSource: snapshot.data!,
                          xValueMapper: (ChartData readings, _) =>
                              readings.time,
                          yValueMapper: (ChartData readings, _) =>
                              readings.reading,
                        )
                      ],
                    );
                  },
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final DateTime time;
  final double reading;

  ChartData(this.time, this.reading);
}
