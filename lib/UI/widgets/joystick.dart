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

    // === 阻力調整核心 (減輕 30%) ===
    // 原本是除以 radius (需推到底才滿速)
    // 現在除以 radius * 0.7 (只需推到 70% 處即滿速，感覺更輕盈)
    double effectiveRadius = radius * 0.7;

    dx = (localPosition.dx - radius) / effectiveRadius;
    dy = (localPosition.dy - radius) / effectiveRadius;

    // 計算距離，限制在圓內 (邏輯：超過 1.0 就鎖定在 1.0)
    double dist = dx * dx + dy * dy;
    if (dist > 1) {
      // 這裡做正規化，保持方向但限制長度
      Offset normalized = Offset(dx, dy) / Offset(dx, dy).distance;
      dx = normalized.dx;
      dy = normalized.dy;
    } else {
      // 額外增加：如果還沒到底，加入一點點非線性曲線，讓中間更靈敏
      // 這是選配的，不喜歡可以拿掉
      // dx = dx * (1.2);
      // dy = dy * (1.2);
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

    // UI 顯示用的位置 (不能因為計算變輕就跑出圓圈外，所以這裡要限制 UI 顯示範圍)
    // 我們用原本的 radius 來限制 UI 的球球不會飛出去
    double displayDx = dx;
    double displayDy = dy;

    // 這裡的邏輯是：即使數值滿了，UI 球球還是乖乖待在邊緣
    double uiX = displayDx * (radius - thumbSize / 2);
    double uiY = displayDy * (radius - thumbSize / 2);

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