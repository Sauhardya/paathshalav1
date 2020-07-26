import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pdf_flutter/pdf_flutter.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:quiver/async.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(paathshala());
}

class paathshala extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(74, 111, 165, 1),
          title: Center(
            child: Text("Paathshala"),
          ),
        ),
        body: PDFListBody(),
      ),
    );
  }
}

class PDFListBody extends StatefulWidget {
  const PDFListBody({
    Key key,
  }) : super(key: key);
  @override
  _PDFListBodyState createState() => _PDFListBodyState();
}

class _PDFListBodyState extends State<PDFListBody> {
  bool recording = false;
  int _time = 0;
  List<Offset> _points = <Offset>[];
  File localFile;
  requestPermissions() async {
    await PermissionHandler().requestPermissions([
      PermissionGroup.storage,
      PermissionGroup.photos,
      PermissionGroup.microphone,
    ]);
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    startTimer();
  }

  void startTimer() {
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: 1000),
      new Duration(seconds: 1),
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() => _time++);
    });

    sub.onDone(() {
      print("Done");
      sub.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => stopScreenRecord(),
      child: Scaffold(
        backgroundColor: Color.fromRGBO(219, 233, 238, 1),
        body: Stack(
          children: <Widget>[
            Container(
                child: localFile != null
                    ? Stack(
                        children: <Widget>[
                          PDF.file(
                            localFile,
                            height: MediaQuery.of(context).size.height * 0.9,
                            width: MediaQuery.of(context).size.width,
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            margin: EdgeInsets.all(0),
                            padding: EdgeInsets.all(0),
                            child: GestureDetector(
                              onPanUpdate: (DragUpdateDetails details) {
                                setState(() {
                                  RenderBox object = context.findRenderObject();
                                  Offset _localPosition = object
                                      .globalToLocal(details.globalPosition);
                                  _points = new List.from(_points)
                                    ..add(_localPosition);
                                });
                              },
                              onPanEnd: (DragEndDetails details) =>
                                  _points.add(null),
                              child: new CustomPaint(
                                painter: new Signature(points: _points),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                          FloatingActionButton(
                            child: new Icon(Icons.clear),
                            onPressed: () => _points.clear(),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () async {
                          File file = await FilePicker.getFile(
                              allowedExtensions: ['pdf'],
                              type: FileType.custom);
                          setState(() {
                            localFile = file;
                          });
                        },
                        child: Column(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(top: 200, bottom: 20),
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "Select PDF from device",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.white),
                                ),
                              ),
                            ),
                            !recording
                                ? Center(
                                    child: RaisedButton(
                                      child: Text("Record Screen"),
                                      onPressed: () => startScreenRecord(false),
                                    ),
                                  )
                                : Container(),
                            !recording
                                ? Center(
                                    child: RaisedButton(
                                      child: Text("Record Screen & audio"),
                                      onPressed: () => startScreenRecord(true),
                                    ),
                                  )
                                : Center(
                                    child: RaisedButton(
                                      child: Text("Stop Record"),
                                      onPressed: () => stopScreenRecord(),
                                    ),
                                  )
                          ],
                        ),
                      )),
          ],
        ),
      ),
    );
  }

  startScreenRecord(bool audio) async {
    bool start = false;

    if (audio) {
      start = await FlutterScreenRecording.startRecordScreenAndAudio("Title");
    } else {
      start = await FlutterScreenRecording.startRecordScreen("Title");
    }

    if (start) {
      setState(() => recording = !recording);
    }

    return start;
  }

  stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    setState(() {
      recording = !recording;
    });
    print("Opening video");
    print(path);
//    OpenFile.open(path);
    File screenFile = File(path);
    //var aux = await screenFile.delete();
    print("aux");
    // print(aux);
    return SystemNavigator.pop();
  }
}

class Signature extends CustomPainter {
  List<Offset> points;

  Signature({this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => oldDelegate.points != points;
}
