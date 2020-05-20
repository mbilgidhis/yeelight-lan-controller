import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:yeedart/yeedart.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  var devices = new List();
  final _biggerFont = const TextStyle(fontSize: 22.0);
  bool _lampState = false;
  Color currentColor = Colors.white;
  String deviceModel = 'mono';
  int brightness = 0;
  int colorTemperature = 1700;
  
  _getDevices() async {
    devices.clear();
    Discover._discover().then((responses){
      setState(() {
        devices = responses;
      });
      if( responses.isEmpty ) {
        showToast('No devices found.');
      }
    }).catchError((onError){
      showToast('Failed to discover devices.');
    });
  }
  
  void showToast(String string) {
    Fluttertoast.showToast(
        msg: string,
        toastLength: Toast.LENGTH_LONG
    );
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
                _onRefresh();
              }),
            )
          ]
      ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: MaterialClassicHeader(),
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
                  _lampState = devices[index].powered;
                  currentColor = Color(_replaceFF(devices[index].rgb));
                  brightness = devices[index].brightness;
                  colorTemperature = devices[index].colorTemperature;
                  setState(() {
                    _getInfo(devices[index]);
                  });
                },
              );
            }
        ),
      ),
    );
  }
  
  Future<void> _onRefresh() async{
    await _getDevices();
    _refreshController.refreshCompleted();
  }
  
  int _changeToInt(Color color) {
    String colorString = color.toString();
    String valueString = colorString.split('(0x')[1].split(')')[0];
    valueString = valueString.substring(2);
    int value = int.parse(valueString, radix: 16);
    return value;
  }
  
  int _replaceFF(int color) {
    Color colorWith00 = Color(color);
    String colorWithFF = colorWith00.toString().replaceAll('0x00', '0xff');
    String valueString = colorWithFF.split('(0x')[1].split(')')[0];
    int value = int.parse(valueString, radix: 16);
    return value;
  }
  
  _getInfo(DiscoveryResponse dev) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Always scan for devices;
              _onRefresh();
              final _styleHead = TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              );
              final _styleBody = TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              );
              
              deviceModel = dev.model;
              
              Future<Null> _onOffPres() async {
                _onRefresh();
                final device = Device(
                  address: dev.address,
                  port: dev.port,
                );
                var _devState = await device.getProps(id: 1, parameters: ['power'])
                    .catchError((onError){
                  showToast('Failed to get device information');
                });
                
                // bagian ini kebalikannya
                
                if ( await _devState.result[0] == 'on' ) {
                  await device.turnOff(
                      duration: Duration(milliseconds: 1000),
                      effect: Effect.smooth()
                  )
                      .catchError((onError){
                    showToast('Failed to turn off the device.');
                  })
                      .whenComplete(() => device.disconnect());
                } else {
                  await device.turnOn(
                      duration: Duration(milliseconds: 1000),
                      effect: Effect.smooth()
                  )
                      .catchError((onError){
                    showToast('Failed to turn on the device.');
                  })
                      .whenComplete(() => device.disconnect());
                }
                setState(() {
                  if ( _devState.result[0] == 'on' ) {
                    _lampState = false;
                  } else {
                    _lampState = true;
                  }
                });
              }
              
              Future<Null> changeColor(Color color) async {
                int convertColor = _changeToInt(currentColor);
                final device = Device(
                  address: dev.address,
                  port: dev.port,
                );
                
                var _devState = await device.getProps(id: 1, parameters: ['power'])
                    .catchError((onError){
                  showToast('Failed to get device information.');
                });
                if ( await _devState.result[0] == 'on' ) {
                  await device.setRGB(
                      color: convertColor,
                      effect: Effect.smooth(),
                      duration: Duration(microseconds: 1000)
                  ).catchError((onError){
                    showToast('Failed to set RGB color.');
                  })
                      .whenComplete(() => device.disconnect());
                }
                
                setState(() {
                  currentColor = color;
                });
              }
              
              Future<Null> changeBrightness(double value) async {
//                                _onRefresh();
                final device = Device(
                  address: dev.address,
                  port: dev.port,
                );
                
                var _devState = await device.getProps(id: 1, parameters: ['power'])
                    .catchError((onError){
                  showToast('Failed to get device information.');
                });
                
                if ( await _devState.result[0] == 'on' ) {
                  await device.setBrightness(
                    brightness: value.toInt(),
                    effect: Effect.smooth(),
                    duration: Duration(microseconds: 1000),
                  ).catchError((onError){
                    showToast('Failed to set brightness.');
                  })
                      .whenComplete(() => device.disconnect());
                }
                
                setState(() {
                  brightness = value.toInt();
                });
              }
              
              Future<Null> changeColorTemperature(double value) async {
//                                _onRefresh();
                final device = Device(
                  address: dev.address,
                  port: dev.port,
                );
                
                var _devState = await device.getProps(id: 1, parameters: ['power'])
                    .catchError((onError){
                  showToast('Failed to get device information.');
                });
                
                if ( await _devState.result[0] == 'on' ) {
                  await device.setColorTemperature(
                    colorTemperature: value.toInt(),
                    effect: Effect.smooth(),
                    duration: Duration(microseconds: 1000),
                  ).catchError((onError){
                    showToast('Failed to set color temperature.');
                  })
                      .whenComplete(() => device.disconnect());
                }
                
                setState(() {
                  colorTemperature = value.toInt();
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
              
              Widget buttonOnOff = Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RaisedButton(
                      onPressed: _onOffPres,
                      child: Text( (_lampState) ? 'ON' : 'OFF', style: TextStyle(fontSize: 20)),
                      textColor: (_lampState) ? Colors.white : Colors.black54,
                      color: (_lampState) ? Colors.blue : Colors.grey[400],
                    )
                  ],
                ),
              );
              
              Widget _colorPicker = Container(
                padding: EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RaisedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                titlePadding: const EdgeInsets.all(0.0),
                                contentPadding: const EdgeInsets.all(0.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.5),
                                ),
                                content: SingleChildScrollView(
                                  child: SlidePicker(
                                    pickerColor:  currentColor,
                                    onColorChanged: changeColor,
                                    paletteType: PaletteType.rgb,
                                    enableAlpha: false,
                                    displayThumbColor: true,
                                    showLabel: false,
                                    showIndicator: true,
                                    indicatorBorderRadius: const BorderRadius.vertical(
                                      top: const Radius.circular(20.0),
                                    ),
                                  ),
                                ),
                              );
                            }
                        );
                      },
                      child: Text('Set Color'),
                      color: currentColor,
                      textColor: useWhiteForeground(currentColor) ? Color(0xffffffff) :  Color(0xff000000),
                    ),
                  ],
                ),
              );
              
              Widget _emptyContainer = Container();
              
              Widget sliderBrightness = Container(
                padding: EdgeInsets.only(bottom: 10, top: 5, left: 18, right: 18),
                child: Slider(
                  min: 1,
                  max: 100,
                  label: 'Brightness',
                  value: brightness.toDouble(),
                  onChanged: (value){
                    setState(() {
                      brightness = value.toInt();
                    });
                  },
                  onChangeEnd: changeBrightness,
                ),
              );
              
              Widget sliderColorTemperature = Container(
                padding: EdgeInsets.only(bottom: 10, top: 5, left: 18, right: 18),
                child: Slider(
                  min: 1700,
                  max: 6500,
                  divisions: 50,
                  label: 'Color Temperature',
                  value: colorTemperature.toDouble(),
                  onChanged: (value){
                    setState(() {
                      colorTemperature = value.toInt();
                    });
                  },
                  onChangeEnd: changeColorTemperature,
                ),
              );
              
              Widget buildTextContainer(String label) {
                return Container(
                  padding: EdgeInsets.only(bottom: 10, top: 10, left: 18, right: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(label, style: _styleHead),
                    ],
                  ),
                );
              }
              
              return Scaffold (
                  appBar: AppBar(
                    title: Text(dev.model.toString()),
                  ),
                  body: ListView(
                    children: [
                      containerTable,
                      buttonOnOff,
                      (deviceModel != 'mono') ? _colorPicker : _emptyContainer,
                      buildTextContainer('Set Brightness'),
                      sliderBrightness,
                      (deviceModel != 'mono') ? buildTextContainer('Set Color Temperature') : _emptyContainer,
                      (deviceModel != 'mono') ? sliderColorTemperature : _emptyContainer,
                    ],
                  )
              );
            },
          );
        },
      ),
    );
  }
}

class Discover {
  static Future<List> _discover() async {
    final responses = await Yeelight.discover();
    print( await responses );
    return responses;
  }
}