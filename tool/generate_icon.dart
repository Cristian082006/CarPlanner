// Generator script pentru iconița aplicației — NU e un test real, doar
// folosește `flutter test` ca să aibă acces la un motor de randare Skia
// (dart:ui nu funcționează în `dart run` simplu). Rulează o singură dată cu
// `flutter test tool/generate_icon.dart`, apoi poate fi șters.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _kPrimary = Color(0xFF2D6A4F);
const double _kSize = 1024;

void _drawCalendarCar(Canvas canvas, {required bool withBackground}) {
  if (withBackground) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, _kSize, _kSize), Paint()..color = _kPrimary);
  }

  final white = Paint()..color = Colors.white;
  for (final cx in [372.0, 652.0]) {
    final tab = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 215), width: 56, height: 170),
      const Radius.circular(28),
    );
    canvas.drawRRect(tab, white);
  }

  final card = RRect.fromRectAndRadius(
    const Rect.fromLTWH(170, 230, 684, 660),
    const Radius.circular(56),
  );
  canvas.drawRRect(card, white);

  final car = Paint()..color = _kPrimary;
  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(280, 560, 464, 120),
    const Radius.circular(40),
  );
  canvas.drawRRect(body, car);
  final cabin = RRect.fromRectAndRadius(
    const Rect.fromLTWH(380, 480, 264, 100),
    const Radius.circular(36),
  );
  canvas.drawRRect(cabin, car);
  for (final cx in [360.0, 664.0]) {
    canvas.drawCircle(Offset(cx, 680), 56, car);
  }
}

class _FullIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => _drawCalendarCar(canvas, withBackground: true);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Aceleași forme, fără fundal (transparent) și scalate la ~66% din canvas,
/// centrate — zona sigură standard pentru foreground-ul iconiței adaptive
/// Android (restul până la margine e "mâncat" de forma măștii pe diverse
/// launchere).
class _ForegroundIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(_kSize * 0.17, _kSize * 0.17);
    canvas.scale(0.66);
    _drawCalendarCar(canvas, withBackground: false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _renderAndSave(
  WidgetTester tester,
  CustomPainter painter,
  String path,
) async {
  await tester.binding.setSurfaceSize(const Size(_kSize, _kSize));
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: SizedBox(
      width: _kSize,
      height: _kSize,
      child: CustomPaint(painter: painter),
    ),
  ));
  await tester.pumpAndSettle();

  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  // `toImage`/`toByteData` do real (non-fake-timer) async work on the raster
  // thread — without `runAsync` they hang forever inside `testWidgets`'s
  // FakeAsync zone.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

void main() {
  testWidgets('generate app icon PNGs', (tester) async {
    await _renderAndSave(tester, _FullIconPainter(), 'assets/icon/icon.png');
    await _renderAndSave(tester, _ForegroundIconPainter(), 'assets/icon/icon_foreground.png');
  });
}
