import 'package:flutter/material.dart';

class Joystick extends StatefulWidget {
  final double size;
  final Color innerColor;
  final Color outerColor;
  final void Function(double x, double y) onChanged;

  const Joystick({
    super.key,
    required this.onChanged,
    this.size = 200,
    this.innerColor = Colors.blueAccent,
    this.outerColor = Colors.white,
  });

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  double dx = 0;
  double dy = 0;

  void _updateDelta(Offset localPosition) {
    double radius = widget.size / 2;

    // === 修改：極低阻力/高靈敏度 ===
    // 原本 effectiveRadius 是 radius * 0.7
    // 現在改為 radius * 0.4
    // 意思是你只要推到 40% 的距離，輸出就已經是全速(1.0)了
    // 這樣手指不需要移動太多，感覺會非常輕盈
    double effectiveRadius = radius * 0.4;

    dx = (localPosition.dx - radius) / effectiveRadius;
    dy = (localPosition.dy - radius) / effectiveRadius;

    // 計算距離，限制在圓內
    double dist = dx * dx + dy * dy;
    if (dist > 1) {
      Offset normalized = Offset(dx, dy) / Offset(dx, dy).distance;
      dx = normalized.dx;
      dy = normalized.dy;
    }

    // 確保最終輸出鎖在 -1 ~ 1
    dx = dx.clamp(-1.0, 1.0);
    dy = dy.clamp(-1.0, 1.0);

    widget.onChanged(dx, dy);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double thumbSize = widget.size * 0.4;
    double radius = widget.size / 2;

    // UI 顯示邏輯：
    // 雖然計算上很靈敏，但 UI 上的球球我們還是讓它能跑滿整個圓盤
    // 這樣視覺上比較好看，不會覺得球球被卡在中間
    double visualDx = dx;
    double visualDy = dy;

    // 限制 UI 球球不跑出框
    double dist = visualDx * visualDx + visualDy * visualDy;
    if (dist > 1) {
      // 已經正規化過了，不用再動
    }

    double uiX = visualDx * (radius - thumbSize / 2);
    double uiY = visualDy * (radius - thumbSize / 2);

    return GestureDetector(
      onPanStart: (d) => _updateDelta(d.localPosition),
      onPanUpdate: (d) => _updateDelta(d.localPosition),
      onPanEnd: (_) {
        dx = 0;
        dy = 0;
        widget.onChanged(0, 0);
        setState(() {});
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black26,
          border: Border.all(
            color: widget.outerColor,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.outerColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(uiX, uiY),
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.innerColor,
                    widget.innerColor.withOpacity(0.6),
                  ],
                  center: const Alignment(-0.3, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.innerColor.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}