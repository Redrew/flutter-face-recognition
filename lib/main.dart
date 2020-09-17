import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as imm;
import 'package:image_picker/image_picker.dart';

void main() => runApp(
      MaterialApp(
        title: 'Face Recognition',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FacePage(),
      ),
    );

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  Map<Face, bool> _wearingMask = Map();
  ui.Image _image;

  _cropFace(List<int> data, Face face) async {
    Rect boundingBox = face.boundingBox;
    int x = boundingBox.topLeft.dx.round();
    int y = boundingBox.topLeft.dy.round();
    int w = boundingBox.width.round();
    int h = boundingBox.height.round();
    imm.Image image = imm.decodeImage(data);
    imm.Image croppedImage = imm.copyCrop(image, x, y, w, h);
    List<int> croppedFace = imm.encodePng(croppedImage);
    return croppedFace;
  }

  _labelFace(List<int> data, Face face) async {
    List<int> croppedFace = await _cropFace(data, face);
    String base64Image = base64.encode(croppedFace);
    Map<String, String> headers = {"Accept": "application/json"};
    Map body = {"image": base64Image};
    // Replace ip address with the public ip address of your VM
    var response = await http.post("http://34.87.210.160/automl.php",
        body: body, headers: headers);
    final payload = json.decode(response.body)["payload"][0];
    print(payload["displayName"]);
    Map<Face, bool> wearingMask = Map.from(_wearingMask);
    wearingMask[face] = payload["displayName"] == "with_mask";
    if (mounted) {
      setState(() {
        _wearingMask = wearingMask;
      });
    }
    // await decodeImageFromList(croppedFace).then((value) => setState(() {
    //       _image = value;
    //     }));
  }

  _getImageAndDetectFaces() async {
    final imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      isLoading = true;
    });
    final imageFV = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(
            mode: FaceDetectorMode.fast, enableLandmarks: true));
    List<Face> faces = await faceDetector.processImage(imageFV);
    List<int> imageData = imageFile.readAsBytesSync();

    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageData);
        _faces.forEach((face) {
          _labelFace(imageData, face);
        });
      });
    }
  }

  _loadImage(List<int> data) async {
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : (_imageFile == null)
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
