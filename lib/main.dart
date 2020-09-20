import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_recognition/image_tool.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(
      MaterialApp(
        title: 'Mask Detection',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage(),
      ),
    );

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  ui.Image _image;
  List<int> _imageData;
  List<Face> _faces;
  Map<Face, bool> _wearingMask = Map();

  _getImageAndDetectFaces() async {
    final imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    setState(() {
      isLoading = true;
    });

    final imageFV = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(
            mode: FaceDetectorMode.fast, enableLandmarks: true));
    List<Face> faces = await faceDetector.processImage(imageFV);
    List<int> imageData = imageFile.readAsBytesSync();

    // Save image in state
    decodeImageFromList(imageData).then(
            (image) => setState(() {
          _image = image;
          isLoading = false;
        })
    );
    setState(() {
      _imageData = imageData;
      _faces = faces;
      _faces.forEach((face) {
        _labelFace(face);
      });
    });
  }

  _labelFace(Face face) async {
    List<int> croppedFace = cropFace(_imageData, face);
    String base64Image = base64.encode(croppedFace);
    Map<String, String> headers = {"Accept": "application/json"};
    Map body = {"image": base64Image};
    // Replace ip address with the public ip address of your VM
    var response = await http.post("http://34.87.210.160/automl.php",
        body: body, headers: headers);
    // print(response.body);
    final payload = json.decode(response.body)["payload"][0];
    Map<Face, bool> wearingMask = Map.from(_wearingMask);
    wearingMask[face] = payload["displayName"] == "with_mask";
    setState(() {
      _wearingMask = wearingMask;
    });
    // await decodeImageFromList(croppedFace).then((value) => setState(() {
    //       _image = value;
    //     }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : (_image== null)
                  ? Text('No image selected')
                  : FittedBox(
                      child: SizedBox(
                        width: _image.width.toDouble(),
                        height: _image.height.toDouble(),
                        child: CustomPaint(
                          painter: FacePainter(_image, _faces, _wearingMask),
                        ),
                      ),
                    )),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageAndDetectFaces,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];
  final Map<Face, bool> labels;

  FacePainter(this.image, this.faces, this.labels) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.blue;

    canvas.drawImage(image, Offset.zero, Paint());
    for (Face face in faces) {
      if (labels.containsKey(face)) {
        if (labels[face]) {
          paint.color = Colors.green;
        } else {
          paint.color = Colors.red;
        }
      } else {
        paint.color = Colors.blue;
      }
      canvas.drawRect(face.boundingBox, paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image ||
        faces != oldDelegate.faces ||
        labels != oldDelegate.labels;
  }
}
