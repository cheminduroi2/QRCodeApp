import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Codes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 0 = default qr image,
  // 1 = scanned QR code result, (stored in qrCodeMsg)
  // 2 = generated QR (stored in qrCodeMsg)
  int centerWidgetMode = 0;
  String qrCodeMsg = '';
  // this helps flutter know what widget to turn into a png image
  // (by wrapping the target widget in a RepaintBoundary widget and
  // setting this for the 'key' property)
  GlobalKey globalKey = new GlobalKey();
  List<Color> gradientColors = [
    Color(0xFFFBC2EB),
    Color(0xFFA6C1EE),
  ];

  _showErrorDialog(String errMsg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(errMsg),
        actions: <Widget>[
          FlatButton(
            child: Text('CLOSE'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Future _shareQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage();
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      await Share.file(
        'Generated QR Code',
        'qrcode.png',
        pngBytes.buffer.asUint8List(),
        'image/png',
      );
    } catch (e) {
      print(e.toString());
    }
  }

  Future scan() async {
    try {
      String qrCodeMsg = await BarcodeScanner.scan();
      setState(() {
        this.centerWidgetMode = 1;
        this.qrCodeMsg = qrCodeMsg;
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        _showErrorDialog('Camera access was not granted');
      } else {
        _showErrorDialog('Unknown error: $e');
      }
    } on FormatException {
      // user clicked on back button without scanning anything. result is null
      return;
    } catch (e) {
      _showErrorDialog('Unknown error: $e');
    }
  }

  _getMsgForNewQRCode() {
    final TextEditingController qrMsgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: TextField(
                controller: qrMsgCtrl,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter message',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    onPressed: () {
                      if (qrMsgCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          centerWidgetMode = 2;
                          qrCodeMsg = qrMsgCtrl.text;
                        });
                      }
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_forward),
                  ),
                ),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(30.0),
                ),
                color: Colors.white,
              ),
              padding: EdgeInsets.fromLTRB(
                15.0,
                8.0,
                8.0,
                8.0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterWidget() {
    switch (centerWidgetMode) {
      case 0:
        return QrImage(
          data: 'Hello!',
          size: 200,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        );
      case 1:
        return SelectableText(
          qrCodeMsg,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RepaintBoundary(
              key: globalKey,
              child: QrImage(
                data: qrCodeMsg,
                size: 200,
                backgroundColor: Colors.transparent,
                // change foreground color if you want the qr code
                // to be more visible against a white background
                // when sharing it to other applications as an image
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 3.0),
            RaisedButton(
              color: Colors.white,
              textColor: Colors.transparent,
              child: GradientText(
                'SHARE',
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              onPressed: () async => await _shareQRCode(),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 105.0),
              child: OutlineButton(
                padding: EdgeInsets.all(10.0),
                borderSide: BorderSide(
                  color: Colors.white,
                  width: 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.0),
                ),
                onPressed: () async => await scan(),
                textColor: Colors.white,
                splashColor: Colors.white,
                child: Text(
                  'SCAN QR CODE',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ),
          ),
          Center(child: _buildCenterWidget()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 105.0),
              child: OutlineButton(
                padding: EdgeInsets.all(10.0),
                borderSide: BorderSide(
                  color: Colors.white,
                  width: 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.0),
                ),
                onPressed: _getMsgForNewQRCode,
                textColor: Colors.white,
                splashColor: Colors.white,
                child: Text(
                  'CREATE QR CODE',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
