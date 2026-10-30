import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../connection.dart';

/// Shows the streamed window. In View mode no touch ever reaches the PC except
/// one-finger scrolling; Tap mode adds clicks. Pinch always zooms the picture
/// locally, and while zoomed a drag pans instead of scrolling.
class VideoView extends StatefulWidget {
  const VideoView({super.key, required this.conn, required this.tapMode});
  final HostConnection conn;
  final bool tapMode;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  final _tc = TransformationController();
  bool _zoomed = false;
  double _scrollAcc = 0;
  Offset _doubleTapPos = Offset.zero;
  Offset? _touch;
  Timer? _fling;
  static const _pxPerNotch = 36.0;

  @override
  void dispose() {
    _fling?.cancel();
    _tc.dispose();
    super.dispose();
  }

  /// Sends accumulated drag as wheel notches at the finger's position.
  void _emitScroll(Offset pos) {
    while (_scrollAcc.abs() >= _pxPerNotch) {
      final notches = _scrollAcc > 0 ? 1 : -1;
      _scrollAcc -= notches * _pxPerNotch;
      widget.conn.scroll(notches, x: pos.dx, y: pos.dy);
    }
  }

  /// Inertia: keep scrolling after the finger lifts, decaying like a native
  /// list. Interrupted by the next touch.
  void _startFling(double velocity, Offset pos) {
    _fling?.cancel();
    var v = velocity.clamp(-5000.0, 5000.0);
    var acc = _scrollAcc;
    _scrollAcc = 0;
    if (v.abs() < 120) return;
    _fling = Timer.periodic(const Duration(milliseconds: 16), (t) {
      v *= 0.90;
      acc += v * 0.016;
      while (acc.abs() >= _pxPerNotch) {
        final notches = acc > 0 ? 1 : -1;
        acc -= notches * _pxPerNotch;
        widget.conn.scroll(notches, x: pos.dx, y: pos.dy);
      }
      if (v.abs() < 120) t.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) setState(() => _zoomed = z);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Frame?>(
      valueListenable: widget.conn.frame,
      builder: (context, f, _) {
        if (f == null) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(builder: (context, box) {
          final s = math.min(box.maxWidth / f.w, box.maxHeight / f.h);
          final dw = f.w * s, dh = f.h * s;
          final ox = (box.maxWidth - dw) / 2, oy = (box.maxHeight - dh) / 2;
          final rect = Rect.fromLTWH(ox, oy, dw, dh);

          // Position inside the picture as 0..1, or null if outside it.
          Offset? norm(Offset p) {
            if (!rect.contains(p)) return null;
            return Offset((p.dx - ox) / dw, (p.dy - oy) / dh);
          }

          void tap(Offset p, String kind) {
            final n = norm(p);
            if (n != null) widget.conn.tap(n.dx, n.dy, kind);
          }

          return InteractiveViewer(
            transformationController: _tc,
            minScale: 1,
            maxScale: 5,
            panEnabled: _zoomed,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.tapMode ? (d) => tap(d.localPosition, 'left') : null,
              onTapDown: (d) => _fling?.cancel(),
              onLongPressStart: widget.tapMode ? (d) => tap(d.localPosition, 'right') : null,
              onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
              onDoubleTap: () {
                if (widget.tapMode) {
                  tap(_doubleTapPos, 'double');
                } else {
                  _tc.value = Matrix4.identity(); // View mode: back to fit
                }
              },
              // One-finger scroll, only when not zoomed (zoomed drags pan the picture).
              onVerticalDragStart: _zoomed
                  ? null
                  : (d) {
                      _fling?.cancel();
                      _touch = d.localPosition;
                    },
              onVerticalDragUpdate: _zoomed
                  ? null
                  : (d) {
                      _touch = d.localPosition;
                      _scrollAcc += d.delta.dy;
                      _emitScroll(d.localPosition);
                    },
              onVerticalDragEnd: _zoomed
                  ? null
                  : (d) {
                      final pos = _touch ?? Offset.zero;
                      _startFling(d.primaryVelocity ?? 0, pos);
                    },
              child: SizedBox(
                width: box.maxWidth,
                height: box.maxHeight,
                child: Stack(children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: Image.memory(
                      f.jpeg,
                      gaplessPlayback: true,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );
  }
}
