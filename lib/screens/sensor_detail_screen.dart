import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hcmut_iot/repository/data_repository.dart';
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

  @override
  void initState() {
    super.initState();
    fetchData();
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

  @override
  void dispose() {
    super.dispose();
    print('SensorDetailScreen disposed');
  }

  @override
  Widget build(BuildContext context) {
    data.sort((a, b) => DateTime.parse(a['created_at'])
        .compareTo(DateTime.parse(b['created_at'])));

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
                "History",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          FutureBuilder<List<ChartData>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    dateFormat: DateFormat('dd/MM HH:mm'),
                  ),
                  series: <ChartSeries>[
                    LineSeries<ChartData, DateTime>(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                      dataSource: snapshot.data!,
                      xValueMapper: (ChartData readings, _) => readings.time,
                      yValueMapper: (ChartData readings, _) => readings.reading,
                    )
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
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
