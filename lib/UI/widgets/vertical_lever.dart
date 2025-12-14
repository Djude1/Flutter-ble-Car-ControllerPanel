import 'package:flutter/material.dart';

enum LeverType { throttle, brake }

class VerticalLever extends StatefulWidget {
  final LeverType type;
  final double value; // 0 ~ 100
  final void Function(double v) onChanged;

  const VerticalLever({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  @override
  State<VerticalLever> createState() => _VerticalLeverState();
}

class _VerticalLeverState extends State<VerticalLever> {
  @override
  Widget build(BuildContext context) {
    double normValue = (widget.value / 100).clamp(0.0, 1.0);

    bool isThrottle = widget.type == LeverType.throttle;
    Color mainColor = isThrottle ? Colors.cyanAccent : Colors.redAccent;
    Color darkColor = isThrottle ? Colors.cyan.shade900 : Colors.red.shade900;
    String label = isThrottle ? "THROTTLE" : "BRAKE";

    return GestureDetector(
      onPanUpdate: (details) {
        // === 修改：極低阻力模式 (20% 阻力感) ===
        // 以前是除以 resistance (大於1的數)，現在我們直接讓它很靈敏
        // 這裡乘以 0.8 是為了讓手感不會「太滑」，保留一點點控制感，
        // 但比之前的重手感輕非常多。
        double sensitivity = 0.8;

        // 直接計算位移，不再使用複雜的阻尼係數
        double delta = (-details.delta.dy * sensitivity);

        double newValue = (widget.value + delta).clamp(0.0, 100.0);
        widget.onChanged(newValue);
      },
      onPanEnd: (_) {
        widget.onChanged(0); // 放手回彈
      },
      child: Container(
        width: 70,
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 背景刻度
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (index) =>
                  Container(
                      width: 20, height: 2,
                      color: Colors.white.withOpacity(0.05)
                  )
              ),
            ),
            // 能量條
            FractionallySizedBox(
              heightFactor: normValue,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [darkColor.withOpacity(0.5), mainColor.withOpacity(0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
            // 拉桿球頭
            Align(
              alignment: Alignment(0, 1.0 - (normValue * 2.0)),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2B2B30),
                  border: Border.all(color: mainColor, width: 2),
                  boxShadow: [BoxShadow(color: mainColor.withOpacity(0.3), blurRadius: 10)],
                ),
                child: Center(
                  child: Text(
                    "${widget.value.toInt()}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // 標籤
            Positioned(
              bottom: 10,
              child: Text(
                label,
                style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}