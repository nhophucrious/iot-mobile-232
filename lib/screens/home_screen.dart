// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hcmut_iot/repository/mqtt_manager.dart';
import 'package:hcmut_iot/widgets/device_tile_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _sensors = [
    [
      'sensor1',
      'Temperature',
      Colors.deepOrange[200],
      Icons.thermostat,
      "20°C"
    ],
    ['sensor2', 'Light', Colors.yellow[200], Icons.sunny, "30 lux"],
    ['sensor3', 'Humidity', Colors.blue[200], Icons.grass, "50%"],
  ];

  List<dynamic> _switches = [
    ['button1', 'Light Switch', Icons.lightbulb, false],
    ['button2', 'Pump Switch', Icons.water_drop, false],
  ];

  late MQTTManager manager;
  Future<void>? _connectAndSubscribe;

  @override
  void initState() {
    super.initState();
    initMQTT();
  }

  Future<void> initMQTT() async {
    final String username = 'phucnguyenng';
    final String aioKey = 'aio_pkkz09Ksjdb56LZdQRizTTkPwMyJ';
    final String clientId = 'flutter_client';
    manager = MQTTManager(username, aioKey, clientId);
    await manager.connect();

    // _deviceFeedNames.forEach((device) {
    //   manager.subscribe('${username}/feeds/${device[0]}');
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // title text, aligned left
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: MediaQuery.of(context).size.height * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "HCMUT IoT",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 34,
                                color: Theme.of(context).primaryColor),
                          ),
                          Text("Welcome back!",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      IconButton(
                          onPressed: () {},
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.settings),
                          ))
                    ],
                  ),
                ),
              ),

              SizedBox(
                height: 20,
              ),

              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05),
                  child: Text(
                    "Sensors",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              // grid view for sensors
              GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _sensors.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 1, mainAxisSpacing: 1),
                itemBuilder: (context, index) {
                  return Container(
                      margin: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _sensors[index][2], width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_sensors[index][3],
                              size: 50, color: _sensors[index][2]),
                          Text(
                            _sensors[index][1],
                          ),
                          Text(
                            _sensors[index][4],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          )
                        ],
                      ));
                },
              ),

              // Expanded(child: Container()),

              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05),
                  child: Text(
                    "Switches",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              // grid view for switches
              GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _switches.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.02),
                    decoration: BoxDecoration(
                        color: (_switches[index][3])
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        border: (_switches[index][3])
                            ? null
                            : Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_switches[index][2],
                            size: 50,
                            color: (_switches[index][3])
                                ? Colors.white
                                : Theme.of(context).primaryColor),
                        Text(
                          _switches[index][1],
                          style: TextStyle(
                              color: (_switches[index][3])
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        Switch(
                          activeColor: Theme.of(context).primaryColorLight,
                          value: _switches[index][3],
                          onChanged: (bool value) {
                            setState(() {
                              _switches[index][3] = value;
                            });
                          },
                        )
                      ],
                    ),
                  );
                },
              ),
              // Expanded(child: Container())
            ],
          ),
        ),
      ),
    );
  }
}
