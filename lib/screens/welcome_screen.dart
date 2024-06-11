// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hcmut_iot/repository/mqtt_manager.dart';
import 'package:hcmut_iot/repository/user_defaults_repository.dart';

class WelcomeScreen extends StatefulWidget {
  WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  late MQTTManager mqttManager;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        // remove focus from text fields when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to HCMUT IoT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                        'Enter your Adafruit IO Username and Key to continue.'),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 6),
                // text field for username
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          labelText: 'Username',
                          hintText: 'Enter your username',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // text field for key
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: TextField(
                        controller: _keyController,
                        maxLength: 32,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          labelText: 'Key',
                          hintText: 'Enter your key',
                        ),
                      ),
                    ),

                    TextButton(
                        onPressed: () async {
                          if (_usernameController.text.isEmpty ||
                              _keyController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                action: SnackBarAction(
                                  label: "Close",
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                  },
                                ),
                                content: Text(
                                    'Please enter your Adafruit IO Username and Key')));
                            return;
                          } else if (_keyController.text.length != 32) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                action: SnackBarAction(
                                  label: "Close",
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                  },
                                ),
                                content:
                                    Text('Key must be 32 characters long')));
                            return;
                          } else {
                            // save to user defaults
                            UserDefaultsRepository.saveUsername(
                                _usernameController.text);
                            UserDefaultsRepository.saveKey(_keyController.text);

                            // connect to test key validity
                            mqttManager = MQTTManager(_usernameController.text,
                                _keyController.text, "flutter_client");
                            try {
                              await mqttManager.connect();
                              mqttManager.disconnect();
                              Navigator.pushNamed(context, '/');
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Error'),
                                    content: Text(
                                        'Failed to connect to MQTT server: $e'),
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
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(16)),
                          child: Text(
                            'Continue',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ))
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
