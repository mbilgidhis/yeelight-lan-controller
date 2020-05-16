import 'package:flutter/material.dart';
import 'dart:io';
import 'package:yeedart/yeedart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Yeelight Controller',
            theme: ThemeData(primaryColor: Colors.blue),
            home: YeelightDevices()
        );
    }
}

class YeelightDevices extends StatefulWidget {
    @override
    _YeelightDeviceState createState() => new _YeelightDeviceState();
}

class _YeelightDeviceState extends State<YeelightDevices> {
    var devices = new List();
    final _biggerFont = const TextStyle(fontSize: 24.0);
    
    _getDevices() {
        Discover._discover().then((responses){
            setState(() {
                devices = responses;
            });
        });
    }
    
    @override
    void initState() {
        super.initState();
        _getDevices();
    }
    
    dispose() {
        super.dispose();
    }
    
    build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Yeelight Controller'),
                actions:<Widget>[
                    IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _pushRefresh,
                    )
                ]
            ),
            body: Center(
                child: ListView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                        return ListTile(
                            title: Text(
                                devices[index].address.address.toString() + ' - ' + devices[index].model.toString(),
                                style: _biggerFont,
                            ),
                            trailing: Icon( Icons.chevron_right ),
                            onTap: () {
                                setState(() {
                                    _getInfo(devices[index]);
                                });
                            },
                        );
                    }
                ),
            )
        );
        throw UnimplementedError();
    }
    
    _pushRefresh() {
        print('Test');
    }
    
    _getInfo(DiscoveryResponse dev) {
        Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (BuildContext context){
                    return Scaffold(
                        appBar: AppBar(
                            title: Text(dev.model.toString()),
                        ),
                        body: Center(
                            child: Text(dev.address.address.toString()),
                        )
                    );
                },
            ),
        );
    }
}

class Discover {
    static Future<List> _discover() async {
        final responses = await Yeelight.discover();
        print( await responses[2] );
        return responses;
    }
}