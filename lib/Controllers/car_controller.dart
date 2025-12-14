import 'dart:math';

class CarController {
  double throttle = 0; // 油門 0 ~ 100
  bool isBraking = false; // 煞車狀態

  double joyX = 0;
  double joyY = 0;

  /// 計算搖桿角度
  double get angleDegrees {
    if (joyX == 0 && joyY == 0) return 0;

    double radians = atan2(-joyY, joyX);
    double degrees = radians * 180 / pi;
    if (degrees < 0) degrees += 360;

    double navDegrees = (0 - degrees + 360) % 360;
    return navDegrees;
  }

  /// 取得 12 個方位
  int get sector {
    // 搖桿沒動時，預設為 0 (雖然這裡設 0，但因為下面 power 會被鎖死，所以實際上車不會動)
    if (joyX.abs() < 0.1 && joyY.abs() < 0.1) {
      return 0;
    }

    double d = (angleDegrees + 15) % 360;
    return (d / 30).floor();
  }

  /// 整合動力輸出
  int get power {
    // 1. 煞車優先權最高
    if (isBraking) return 0;

    // =========================================================
    // ★★★ 修改重點：檢查方向盤是否被操作 ★★★
    // =========================================================
    // 如果 X 軸和 Y 軸的絕對值都小於 0.1 (代表搖桿在中間死區沒動)
    if (joyX.abs() < 0.1 && joyY.abs() < 0.1) {
      return 0; // 強制將動力設為 0，這時拉油門也沒用
    }

    // 只有當方向盤有動作時，才輸出油門值
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