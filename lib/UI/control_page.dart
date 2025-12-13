import 'dart:async'; // 引入 Timer
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../BLE/ble_service.dart';
import '../Controllers/car_controller.dart';
import 'widgets/joystick.dart';
import 'widgets/vertical_lever.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String connectionText = "未連線";
  Color connectionColor = Colors.redAccent;
  bool isConnecting = false;

  // 定時發送器
  Timer? _sendTimer;

  @override
  void initState() {
    super.initState();

    // ====================================================
    // ★★★ 設定為 120ms (約每秒 8 次) ★★★
    // 這是最佳平衡點：操作順暢，且不會讓藍芽模組塞車
    // ====================================================
    _sendTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (bleService.isConnected) {
        bleService.send(carController.command);
      }
    });
  }

  @override
  void dispose() {
    // 離開頁面時銷毀 Timer，防止記憶體洩漏
    _sendTimer?.cancel();
    super.dispose();
  }

  // 強制立即發送 (煞車專用，不等待 Timer，確保瞬停)
  void _forceSync() {
    if (!bleService.isConnected) return;
    bleService.send(carController.command);
  }

  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] == PermissionStatus.permanentlyDenied ||
        statuses[Permission.location] == PermissionStatus.permanentlyDenied) {
      return false;
    }
    return true;
  }

  Future<void> _connect() async {
    if (isConnecting) return;

    bool hasPerm = await _checkPermissions();
    if (!hasPerm) {
      if (mounted) {
        setState(() {
          connectionText = "權限被拒絕";
          connectionColor = Colors.orange;
        });
        openAppSettings();
      }
      return;
    }

    setState(() {
      isConnecting = true;
      connectionText = "掃描中...";
      connectionColor = Colors.yellowAccent;
    });

    final device = await bleService.scanAndConnect();

    if (mounted) {
      setState(() {
        isConnecting = false;
        if (device != null) {
          connectionText = "已連線：${device.platformName}";
          connectionColor = Colors.greenAccent;
        } else {
          connectionText = "連線失敗";
          connectionColor = Colors.red;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E11),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ===============================================
              // 區域 1 (最左邊)：煞車 STOP 按鈕 (長條形)
              // ===============================================
              Expanded(
                flex: 3,
                child: Center(
                  child: GestureDetector(
                    onTapDown: (_) {
                      carController.isBraking = true;
                      setState(() {});
                      _forceSync(); // 按下瞬間強制發送停止指令
                    },
                    onTapUp: (_) {
                      carController.isBraking = false;
                      setState(() {});
                      _forceSync(); // 放開瞬間恢復控制
                    },
                    onTapCancel: () {
                      carController.isBraking = false;
                      setState(() {});
                      _forceSync();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 90,   // 長條形寬度
                      height: 200, // 長條形高度
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(24),
                        color: carController.isBraking
                            ? Colors.redAccent.shade700
                            : const Color(0xFF3A1010),
                        border: Border.all(
                          color: Colors.redAccent,
                          width: carController.isBraking ? 6 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: carController.isBraking ? 30 : 10,
                            spreadRadius: carController.isBraking ? 5 : 0,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "STOP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ===============================================
              // 區域 2 (煞車右邊)：引擎油門拉桿
              // ===============================================
              Expanded(
                flex: 2,
                child: Center(
                  child: VerticalLever(
                    type: LeverType.throttle,
                    value: carController.throttle,
                    onChanged: (v) {
                      carController.throttle = v;
                      // 不需手動 _sync()，交給 Timer 每 120ms 自動發送
                      setState(() {});
                    },
                  ),
                ),
              ),

              // ===============================================
              // 區域 3 (中間)：狀態顯示與連線按鈕
              // ===============================================
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: connectionColor.withOpacity(0.3))
                      ),
                      child: Text(
                        connectionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: connectionColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _connect,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF292929),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isConnecting)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            else
                              const Icon(Icons.bluetooth, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(isConnecting ? "SCAN..." : "CONNECT", style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Debug 資訊
                    Text(
                      "CMD: ${carController.command.trim()}",
                      style: const TextStyle(color: Colors.white12, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // ===============================================
              // 區域 4 (最右邊)：方向搖桿
              // ===============================================
              Expanded(
                flex: 4,
                child: Center(
                  child: Joystick(
                    size: 200,
                    innerColor: Colors.blueAccent,
                    outerColor: Colors.white10,
                    onChanged: (x, y) {
                      carController.updateJoystick(x, y);
                      // 不需手動 _sync()，交給 Timer
                      setState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}