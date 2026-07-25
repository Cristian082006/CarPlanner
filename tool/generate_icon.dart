// Generator script pentru iconița aplicației — NU e un test real, doar
// folosește `flutter test` ca să aibă acces la un motor de randare Skia
// (dart:ui nu funcționează în `dart run` simplu). Rulează o singură dată cu
// `flutter test tool/generate_icon.dart`, apoi poate fi șters.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double _kSize = 1024;

// Cadru degrade albastru → violet (stil "Auto Calendar"), header roșu cu
// "AUTO" și o mașină stilizată cu highlight (efect "glossy").
const Color _kGradientStart = Color(0xFF3B82F6); // albastru
const Color _kGradientEnd = Color(0xFF8B5CF6); // violet
const Color _kHeaderRed = Color(0xFFE53935);
const Color _kCarDark = Color(0xFF1F2933);
const Color _kCarHighlight = Color(0xFF4A5A68);

void _drawCalendarCar(Canvas canvas, {required bool withBackground}) {
  if (withBackground) {
    final bgShader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(_kSize, _kSize),
      [_kGradientStart, _kGradientEnd],
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _kSize, _kSize),
      Paint()..shader = bgShader,
    );
  }

  final white = Paint()..color = Colors.white;
  for (final cx in [372.0, 652.0]) {
    final tab = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 175), width: 56, height: 150),
      const Radius.circular(28),
    );
    canvas.drawRRect(tab, white);
  }

  const cardRect = Rect.fromLTWH(170, 200, 684, 690);
  const cardRadius = Radius.circular(56);
  final card = RRect.fromRectAndRadius(cardRect, cardRadius);
  canvas.drawRRect(card, white);
  canvas.save();
  canvas.clipRRect(card);

  // Header roșu, cu colțuri rotunjite doar sus — moștenite din clip-ul
  // cardului de mai sus. Fără text (TextPainter nu randează glife reale în
  // pipeline-ul de `flutter test` folosit aici — apar cutii goale, font de
  // test fără glife) — puncte albe (găuri de îndosariere) în loc.
  final headerRect = Rect.fromLTWH(cardRect.left, cardRect.top, cardRect.width, 150);
  canvas.drawRect(headerRect, Paint()..color = _kHeaderRed);

  for (final cx in [cardRect.center.dx - 90, cardRect.center.dx, cardRect.center.dx + 90]) {
    canvas.drawCircle(Offset(cx, headerRect.center.dy), 16, white);
  }

  canvas.restore();

  // Mașină stilizată, sub header, cu un highlight pentru efect glossy.
  canvas.save();
  canvas.translate(cardRect.center.dx - 372, 20);

  final carShader = ui.Gradient.linear(
    const Offset(280, 560),
    const Offset(280, 736),
    [_kCarHighlight, _kCarDark],
  );
  final carPaint = Paint()..shader = carShader;

  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(280, 560, 464, 120),
    const Radius.circular(40),
  );
  canvas.drawRRect(body, carPaint);
  final cabin = RRect.fromRectAndRadius(
    const Rect.fromLTWH(380, 480, 264, 100),
    const Radius.circular(36),
  );
  canvas.drawRRect(cabin, carPaint);

  // Highlight sticlă parbriz — accentuează efectul "glossy".
  final glassHighlight = RRect.fromRectAndRadius(
    const Rect.fromLTWH(400, 494, 100, 26),
    const Radius.circular(13),
  );
  canvas.drawRRect(glassHighlight, Paint()..color = Colors.white.withValues(alpha: 0.35));

  for (final cx in [360.0, 664.0]) {
    canvas.drawCircle(Offset(cx, 680), 56, Paint()..color = _kCarDark);
    canvas.drawCircle(Offset(cx, 680), 24, Paint()..color = _kCarHighlight);
  }
  canvas.restore();
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
