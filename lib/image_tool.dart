import 'dart:math';
import 'package:image/image.dart' as image;
import 'dart:ui';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

const int MAX_IMAGE_SIZE = 16000;

resize(image.Image img, {int maxSize=MAX_IMAGE_SIZE}) {
  if (img.data.length > maxSize) {
    int downSampleRatio = (sqrt(img.data.length / maxSize)).ceil();
    int reducedWidth = (img.width / downSampleRatio).round();
    img = image.copyResize(img, width: reducedWidth);
  }
  return img;
}

crop(List<int> data, int x, int y, int w, int h) {
  final image.Image img = image.decodeImage(data);
  image.Image croppedImg = image.copyCrop(img, x, y, w, h);
  croppedImg = resize(croppedImg);
  return image.encodePng(croppedImg);
}

cropFace(List<int> image, Face face){
  Rect boundingBox = face.boundingBox;
  int x = boundingBox.topLeft.dx.round();
  int y = boundingBox.topLeft.dy.round();
  int w = boundingBox.width.round();
  int h = boundingBox.height.round();
  List <int> croppedFace = crop(image, x, y, w, h);
  return croppedFace;
}

