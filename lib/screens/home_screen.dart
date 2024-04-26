// ignore_for_file: prefer_const_constructors, avoid_print

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

  final List<dynamic> _switches = [
    ['button1', 'Light Switch', Icons.lightbulb, false],
    ['button2', 'Pump Switch', Icons.water_drop, false],
  ];

  late MQTTManager manager;
  Future<void>? _connectAndSubscribe;

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe = initMQTT();
  }

  Future<void> initMQTT() async {
    String username = await UserDefaultsRepository.getUsername() as String;
    String aioKey = await UserDefaultsRepository.getKey() as String;
    print("Username: $username, Key: $aioKey");
    const String clientId = 'newf_client';
    manager = MQTTManager(username, aioKey, clientId);
    await manager.connect();

    DataRepository dataRepository = DataRepository();

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
        setState(() {
          _switches[i][3] = message == '1' ? true : false;
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
          _switches[i][3] = initialValue == '1' ? true : false;
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
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      // button to reconnect (disabled when connected)
                      Row(
                        children: [
                          StreamBuilder<MqttConnectionState>(
                            stream: manager.connectionStatus,
                            builder: (context, snapshot) {
                              if (snapshot.data ==
                                  MqttConnectionState.connected) {
                                Future.microtask(() {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('MQTT Reconnected'),
                                        content: Text(
                                            'The MQTT client has been reconnected.'),
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
                                });
                              }

                              return IconButton(
                                onPressed: snapshot.data ==
                                        MqttConnectionState.connected
                                    ? null
                                    : () async {
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
                                // push completely to welcome screen
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                            'Are you sure you want to log out?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancel')),
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                // clear user defaults
                                                UserDefaultsRepository.clear();
                                                Navigator.of(context)
                                                    .pushNamedAndRemoveUntil(
                                                        '/welcome',
                                                        (route) => false);
                                              },
                                              child: Text('Log out'))
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
                                child: Icon(Icons.logout),
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
                              // Internet connection available, change the switch state
                              setState(() {
                                // TODO: if internet was toggled on and off again, attempt to subscribe to the topic again
                                _switches[index][3] = value;
                                // publish message
                                manager.publish(
                                    '$USERNAME/feeds/${_switches[index][0]}',
                                    (value) ? '1' : '0');
                              });
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
