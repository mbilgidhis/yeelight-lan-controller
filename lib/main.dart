import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
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
    YeelightDevices({Key key}) : super(key: key);
    @override
    _YeelightDeviceState createState() => new _YeelightDeviceState();
}

class _YeelightDeviceState extends State<YeelightDevices> {
    var devices = new List();
    final _biggerFont = const TextStyle(fontSize: 22.0);
    
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
                        onPressed: () => setState(() {
                          _pushRefresh();
                        }),
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
        devices.clear();
        _getDevices();
    }
    
    _getInfo(DiscoveryResponse dev) {
        Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (BuildContext context){
                    // Always scan for devices;
                    _pushRefresh();
                    final _styleHead = TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                    );
                    final _styleBody = TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                    );
                    bool _lampState = dev.powered;
                    
                    // Color color = Theme.of(context).primaryColor;
                    
                    Future<Null> _onOffPres() async {
                        // Always scan for devices
                        _pushRefresh();
                        
                        final device = Device(
                            address: dev.address,
                            port: dev.port,
                        );
                        var _devState = await device.getProps(id: 1, parameters: ['power']);
//                        print(_devState.result[0] );
                        if ( await _devState.result[0] == 'on' ) {
                            device.turnOff();
                        } else {
                            device.turnOn();
                        }
//                        print(_devState.result[0] );
    
                        // bagian ini kebalikannya
                        setState(() {
//                            print(_devState.result[0]);
                            if ( _devState.result[0] == 'on' ) {
                                _lampState = false;
                            } else {
                                _lampState = true;
                            }
//                            print(_lampState);
                        });
                    }
                    
                    Widget containerTable = Container(
                        padding: EdgeInsets.all(18),
                        child: Table(
                            children: [
                                TableRow(
                                    
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Name', style: _styleHead),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Value', style: _styleHead),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                                TableRow(
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('ID', style: _styleBody),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text(dev.id.toString(), style: _styleBody),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                                TableRow(
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Name', style: _styleBody),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: (dev.name != "") ? Text(utf8.decode( base64.decode(dev.name.toString())), style: _styleBody) : Text(''),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                                TableRow(
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Address', style: _styleBody),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text(dev.address.address.toString(), style: _styleBody),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                                TableRow(
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Port', style: _styleBody),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text(dev.port.toString(), style: _styleBody),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                                TableRow(
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Model', style: _styleBody),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text(dev.model.toString(), style: _styleBody),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                                TableRow(
                                    children: [
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text('Firmware Version', style: _styleBody),
                                                )
                                            ],
                                        ),
                                        Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Container(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text(dev.firmwareVersion.toString(), style: _styleBody),
                                                )
                                            ],
                                        )
                                    ]
                                ),
                            ],
                        ),
                    );
                    
                    Widget _buildOffButton() {
                        assert(!dev.powered);
                        return new Container(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                    RaisedButton(
                                        onPressed: _onOffPres,
                                        child: Text( 'OFF', style: TextStyle(fontSize: 20)),
                                        textColor: Colors.black54,
                                        color: Colors.grey[400],
                                    )
                                ],
                            )
                        );
                    }

                    Widget _buildOnButton() {
                        assert(dev.powered);
                        return new Container(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                    RaisedButton(
                                        onPressed: _onOffPres,
                                        child: Text('ON', style: TextStyle(fontSize: 20)),
                                        textColor: Colors.white,
                                        color: Colors.blue,
                                    )
                                ],
                            )
                        );
                    }
                    
                    return Scaffold (
                        appBar: AppBar(
                            title: Text(dev.model.toString()),
                        ),
                        body: ListView(
                            children: [
                                containerTable,
                                ( _lampState ) ? _buildOnButton() : _buildOffButton(),
                            ],
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
//        print( await responses );
        return responses;
    }
}