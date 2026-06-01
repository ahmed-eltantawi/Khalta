import 'dart:io';
import 'package:image/image.dart';

void main() {
  final img = decodeImage(File('assets/images/app_icon.png').readAsBytesSync());
  if (img != null) {
    final pixel = img.getPixel(0, 0);
    print('Top-left color: , , , ');
  }
}
