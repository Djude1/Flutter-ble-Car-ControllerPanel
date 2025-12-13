import 'dart:math';

class CarController {
  double throttle = 0; // 油門 0 ~ 100
  bool isBraking = false; // 煞車狀態

  double joyX = 0;
  double joyY = 0;

  /// 計算搖桿角度
  double get angleDegrees {
    // 雖然這裡回傳 0，但在下面的 sector 判斷中，
    // 我們會優先處理「搖桿沒動」的情況，所以這裡沒關係
    if (joyX == 0 && joyY == 0) return 0;

    double radians = atan2(-joyY, joyX);
    double degrees = radians * 180 / pi;
    if (degrees < 0) degrees += 360;

    // 保留修正後的偏移量 (原本方向錯亂的問題)
    double navDegrees = (0 - degrees + 360) % 360;
    return navDegrees;
  }

  /// 取得 12 個方位
  int get sector {
    // ★★★ 關鍵修正：搖桿沒動時，預設為 0 (正前方) ★★★
    // 這樣當你只拉右邊油門時，車子會預設往前跑，而不是停在原地空轉
    if (joyX.abs() < 0.1 && joyY.abs() < 0.1) {
      return 0; // 0 代表正前方
    }

    double d = (angleDegrees + 15) % 360;
    return (d / 30).floor();
  }

  /// 整合動力輸出
  int get power {
    if (isBraking) return 0; // 煞車優先
    return throttle.toInt();
  }

  /// 最終指令
  String get command {
    return "S:$sector,P:$power\n";
  }

  void updateJoystick(double x, double y) {
    joyX = x;
    joyY = y;
  }
}

final CarController carController = CarController();