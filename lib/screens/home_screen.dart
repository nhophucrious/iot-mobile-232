// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hcmut_iot/repository/data_repository.dart';
import 'package:hcmut_iot/repository/mqtt_manager.dart';
import 'package:hcmut_iot/credentials.dart';
import 'package:hcmut_iot/repository/user_defaults_repository.dart';
import 'package:mqtt_client/mqtt_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /*
  final List<dynamic> _sensors = [
    [
      'sensor1',
      'Temperature',
      Colors.deepOrange[200],
      Icons.thermostat,
      "20°C"
    ],
    ['sensor2', 'Light', Colors.amber, Icons.sunny, "30 lux"],
    ['sensor3', 'Humidity', Colors.blue[200], Icons.grass, "50%"],
  ];
  */

  bool _hasThirdPumpRun = false;

  final List<dynamic> _switches = [
    ['mixer1', 'Mixer 1', Icons.water_drop_sharp, false],
    ['mixer2', 'Mixer 2', Icons.water_drop_sharp, false],
    ['mixer3', 'Mixer 3', Icons.water_drop_sharp, false]
  ];
  final List<dynamic> _sensors = [
    [
      'soil-temp',
      'Soil Temperature',
      Colors.deepOrange[200],
      Icons.thermostat,
      "20°C"
    ],
    ['soil-moist', 'Soil Moisture', Colors.blue, Icons.water_drop, "30%"],
    ['temperature', 'Air Temperature', Colors.blue[200], Icons.ac_unit, "25°C"],
    ['luminance', 'Light', Colors.amber, Icons.sunny, "30 lux"],
  ];

  late MQTTManager manager;
  Future<void>? _connectAndSubscribe;
  StreamController<String> ackController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe = initMQTT();
  }

  Future<void> initMQTT() async {
    // String username = await UserDefaultsRepository.getUsername() as String;
    String username = USERNAME;
    print('username: $username');
    // String aioKey = await UserDefaultsRepository.getKey() as String;
    String aioKey = KEY;
    print('key: $aioKey');
    print("Username: $username, Key: $aioKey");
    const String clientId = 'newf_client';
    manager = MQTTManager(username, aioKey, clientId);
    print(clientId);
    await manager.connect();

    DataRepository dataRepository = DataRepository();

    // Subscribe to the "ack" feed
    String ackTopic = '$username/feeds/ack';
    manager.subscribe(ackTopic);

    // Convert the updates stream to a broadcast stream
    Stream<String> ackUpdates = manager.updates(ackTopic).asBroadcastStream();

    // Listen for acknowledgment messages
    ackUpdates.listen((message) {
      ackController.add(message);
    });

    manager.connectionStatus.listen((status) {
      if (status == MqttConnectionState.disconnected) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('MQTT Disconnected'),
              content: Text('The MQTT client has been disconnected.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });

    for (var i = 0; i < _switches.length; i++) {
      String feedName = _switches[i][0];
      String topic = '$username/feeds/$feedName';
      manager.subscribe(topic);

      // Listen to updates for the switch
      manager.updates(topic).listen((message) {
        print('Got message: $message from $topic');
        setState(() {
          _switches[i][3] = message == 'ON' ? true : false;
          if (feedName == 'mixer3' && message == 'OFF') {
            // _hasThirdPumpRun = true;
            // now we select the watering area
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return MyBottomSheet(
                  onRedo: () {
                    // Publish the message
                    manager.publish(
                      '$USERNAME/feeds/${_switches[0][0]}',
                      'ON',
                    );

                    // Update the local state
                    setState(() {
                      _switches[0][3] = true; // restart the flow
                    });
                  },
                );
              },
            );
          }
        });
      });

      // Fetch the initial value
      try {
        String initialValueString =
            await dataRepository.fetchLatestData(username, feedName);
        print('Initial value for $feedName: $initialValueString');
        var myjson = (jsonDecode(initialValueString));
        var initialValue = myjson[0]['value'];
        setState(() {
          _switches[i][3] = initialValue == 'ON' ? true : false;
        });
      } catch (e) {
        print('Failed to fetch initial value for $feedName: $e');
      }
    }

    // now for the sensors!
    for (var i = 0; i < _sensors.length; i++) {
      String feedName = _sensors[i][0];
      String topic = '$username/feeds/$feedName';
      manager.subscribe(topic);

      // Listen to updates for the sensor
      manager.updates(topic).listen((message) {
        setState(() {
          _sensors[i][4] = message;
        });
      });

      // Fetch the initial value
      try {
        String initialValueString =
            await dataRepository.fetchLatestData(username, feedName);
        print('Initial value for $feedName: $initialValueString');
        var myjson = (jsonDecode(initialValueString));
        var initialValue = myjson[0]['value'];
        setState(() {
          _sensors[i][4] = initialValue;
        });
      } catch (e) {
        print('Failed to fetch initial value for $feedName: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _connectAndSubscribe,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _buildHomeScreen();
        } else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Scaffold _buildHomeScreen() {
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
                          Text("Welcome!",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      // button to reconnect (disabled when connected)
                      Row(
                        children: [
                          StreamBuilder<MqttConnectionState>(
                            stream: manager.connectionStatus,
                            builder: (context, snapshot) {
                              return IconButton(
                                onPressed: () async {
                                  await initMQTT();
                                },
                                icon: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: snapshot.data ==
                                              MqttConnectionState.connected
                                          ? Colors.grey
                                          : Colors.white,
                                      border: Border.all(
                                          color: Theme.of(context).primaryColor,
                                          width: 2),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.refresh),
                                ),
                              );
                            },
                          ),
                          // button to log out
                          IconButton(
                              onPressed: () {
                                // shows attribution dialog
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog.adaptive(
                                        title: Text('Greetings! 🎊'),
                                        content: Text(
                                            'This app was developed by: \n\n-Hồ Nguyễn Ngọc Bảo\n- Nguyễn Nho Gia Phúc\n- Lưu Quốc Vinh\n\nWe hope you enjoy using it! 🎉'),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('OK')),
                                        ],
                                      );
                                    });
                              },
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.info),
                              )),
                        ],
                      )
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
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/sensor-detail',
                          arguments: <String, String>{
                            'feedName': _sensors[index][0],
                            'sensorName': _sensors[index][1]
                          });
                    },
                    child: Container(
                        margin: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: _sensors[index][2], width: 2),
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
                        )),
                  );
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
                          onChanged: (bool value) async {
                            var connectivityResult =
                                await (Connectivity().checkConnectivity());
                            print(connectivityResult);
                            if (connectivityResult[0] ==
                                ConnectivityResult.none) {
                              // No internet connection, show a dialog and don't change the switch state
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('No Internet Connection'),
                                    content: Text(
                                        'Please check your internet connection and try again.'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('OK'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              // Internet connection available, try to publish message
                              try {
                                manager.publish(
                                    '$USERNAME/feeds/${_switches[index][0]}',
                                    (value) ? 'ON' : 'OFF');

                                // Change the switch state immediately after publishing
                                setState(() {
                                  _switches[index][3] = value;
                                });
                              } catch (e) {
                                if (e is TimeoutException) {
                                  // If a TimeoutException is thrown, revert the switch state and send the previous value back to Adafruit IO
                                  setState(() {
                                    _switches[index][3] = !_switches[index][3];
                                  });
                                  manager.publish(
                                      '$USERNAME/feeds/${_switches[index][0]}',
                                      (_switches[index][3]) ? 'ON' : 'OFF');
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('MQTT Disconnected'),
                                        content: Text(
                                            'The MQTT client is not connected.'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            }
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

class MyBottomSheet extends StatefulWidget {
  final Function onRedo;
  MyBottomSheet({required this.onRedo});
  @override
  _MyBottomSheetState createState() => _MyBottomSheetState();
}

class _MyBottomSheetState extends State<MyBottomSheet> {
  String _status = 'Choose the area to water:';
  int _step = 0;

  void _startTimer() {
    Future.delayed(Duration(seconds: 5)).then((_) {
      setState(() {
        _step++;
        if (_step == 1) {
          _status = 'Pumping water in...';
          _startTimer();
        } else if (_step == 2) {
          _status = 'Pumping out residue water...';
          _startTimer();
        } else if (_step == 3) {
          _status = 'Do you want to redo the steps?';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _status,
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
            if (_step == 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _status = 'Area 1 selected. Pumping water in...';
                        _step++;
                        _startTimer();
                      });
                    },
                    child: Text('Area 1'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _status = 'Area 2 selected. Pumping water in...';
                        _step++;
                        _startTimer();
                      });
                    },
                    child:
                        Text('Area 2', style: TextStyle(color: Colors.amber)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _status = 'Area 3 selected. Pumping water in...';
                        _step++;
                        _startTimer();
                      });
                    },
                    child: Text('Area 3', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            if (_step == 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onRedo();
                      Navigator.pop(context);
                    },
                    child: Text('Redo', style: TextStyle(fontSize: 20)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Done',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
