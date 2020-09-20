import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mask_detection/image_tool.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// You will need this for part 2 of the workshop
const MASK_DETECTOR_URL = "http://34.87.210.160/automl.php";

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Hello World")
      )
    );
  }
}
