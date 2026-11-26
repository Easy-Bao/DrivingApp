import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:foundation/foundation.dart';
import 'package:maps/src/presentation/marker_style_and_motion.dart';
import 'package:material_ui/material_ui.dart';

class MarkerBitmapRenderer._() {
  static const _markerImageCacheCapacity = 32;
  static final LinkedHashMap<String, Uint8List> _markerImageCache =
      LinkedHashMap();

  static String cacheKey(Color color, {String? label}) {
    final cacheLabel = label == null || label.trim().isEmpty ? '' : label;
    return '${color.toARGB32()}_$cacheLabel';
  }

  static Future<Uint8List> getOrRender(Color color, {String? label}) async {
    final key = cacheKey(color, label: label);
    final cachedImage = _markerImageCache.remove(key);
    if (cachedImage != null) {
      _markerImageCache[key] = cachedImage;
      return cachedImage;
    }

    final image = await traceTimelineStage(
      'maps.marker.rasterize_png',
      () => _renderMarkerImage(color, label: label),
    );
    if (_markerImageCache.length >= _markerImageCacheCapacity) {
      _markerImageCache.remove(_markerImageCache.keys.first);
    }
    _markerImageCache[key] = image;
    return image;
  }

  static Future<Uint8List> _renderMarkerImage(
    Color color, {
    String? label,
  }) async {
    if (label == null || label.trim().isEmpty) {
      return _createPinImage(color);
    }

    const width = 360.0;
    const height = 104.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final background = Paint()..color = TripMapMarkerStyle.markerSurface;
    final shadow = Paint()
      ..color = TripMapMarkerStyle.labelForeground.withValues(alpha: 0.12);
    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, width - 16, 78),
      const Radius.circular(22),
    );
    canvas.drawRRect(cardRect.shift(const Offset(0, 6)), shadow);
    canvas.drawRRect(cardRect, background);
    final pointer = Path()
      ..moveTo(width / 2 - 14, 84)
      ..lineTo(width / 2, height - 4)
      ..lineTo(width / 2 + 14, 84)
      ..close();
    canvas.drawPath(pointer, background);

    canvas.drawCircle(const Offset(48, 47), 20, Paint()..color = color);
    canvas.drawCircle(
      const Offset(48, 47),
      8,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );

    final lines = label.split('\n');
    _drawLabelText(
      canvas,
      lines.first,
      const Offset(82, 25),
      width: 250,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: TripMapMarkerStyle.labelForeground,
    );
    if (lines.length > 1) {
      _drawLabelText(
        canvas,
        lines.skip(1).join(' '),
        const Offset(82, 55),
        width: 250,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: TripMapMarkerStyle.labelForeground.withValues(alpha: 0.6),
      );
    }

    return _encodePictureAsPng(
      recorder.endRecording(),
      width: width.toInt(),
      height: height.toInt(),
    );
  }

  static void _drawLabelText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1, ellipsis: '…'))
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
          ..addText(text);
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(paragraph, offset);
  }

  static Future<Uint8List> _createPinImage(Color color) async {
    const width = 64.0;
    const height = 76.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(width / 2, 26);
    final outerTail = Path()
      ..moveTo(center.dx - 10, 41)
      ..lineTo(center.dx, height - 2)
      ..lineTo(center.dx + 10, 41)
      ..close();
    final innerTail = Path()
      ..moveTo(center.dx - 6, 40)
      ..lineTo(center.dx, height - 9)
      ..lineTo(center.dx + 6, 40)
      ..close();
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 23))
      ..addPath(outerTail, Offset.zero);

    canvas.drawShadow(
      shadowPath,
      TripMapMarkerStyle.labelForeground.withValues(alpha: 0.26),
      5,
      true,
    );
    canvas.drawPath(
      outerTail,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );
    canvas.drawPath(innerTail, Paint()..color = color);
    canvas.drawCircle(
      center,
      23,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );
    canvas.drawCircle(center, 18, Paint()..color = color);
    canvas.drawCircle(
      center,
      9,
      Paint()..color = TripMapMarkerStyle.markerSurface,
    );
    canvas.drawCircle(center, 4, Paint()..color = color);
    return _encodePictureAsPng(
      recorder.endRecording(),
      width: width.toInt(),
      height: height.toInt(),
    );
  }

  static Future<Uint8List> _encodePictureAsPng(
    ui.Picture picture, {
    required int width,
    required int height,
  }) async {
    ui.Image? image;
    try {
      image = await picture.toImage(width, height);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Failed to encode marker image as PNG.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }
}
