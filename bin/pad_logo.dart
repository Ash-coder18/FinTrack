import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  try {
    final imageBytes = File('assets/icon/logo.png').readAsBytesSync();
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      print('Could not decode image.');
      return;
    }
    
    final oldW = image.width;
    final oldH = image.height;
    
    final newW = (oldW * 0.65).toInt();
    final newH = (oldH * 0.65).toInt();
    
    final resized = img.copyResize(image, width: newW, height: newH, interpolation: img.Interpolation.cubic);
    
    final padded = img.Image(width: oldW, height: oldH);
    img.fill(padded, color: img.ColorRgba8(0, 0, 0, 0));
    
    final dstX = (oldW - newW) ~/ 2;
    final dstY = (oldH - newH) ~/ 2;
    img.compositeImage(padded, resized, dstX: dstX, dstY: dstY);
    
    File('assets/icon/logo_padded.png').writeAsBytesSync(img.encodePng(padded));
    print('Padded logo created successfully.');
  } catch (e) {
    print('Error: $e');
  }
}
