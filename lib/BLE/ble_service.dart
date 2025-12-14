// 判斷平台用的 (放在檔案最上面 import 'dart:io';)
import 'dart:io';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  // 定義 UUID
  final Guid serviceUuid = Guid('0000FFA0-0000-1000-8000-00805F9B34FB');
  final Guid charUuid =    Guid('0000FFA1-0000-1000-8000-00805F9B34FB');

  bool get isConnected => characteristic != null && device != null;

  // 斷線處理
  Future<void> disconnect() async {
    if (device != null) {
      print(">>> [BLE] 正在斷開連線...");
      try {
        await device!.disconnect();
      } catch (e) {
        print(">>> [BLE] 斷線異常 (可忽略): $e");
      }
    }
    device = null;
    characteristic = null;
  }

  // 核心連線邏輯
  Future<BluetoothDevice?> scanAndConnect() async {
    print(">>> [BLE] 開始連線流程...");

    // 0. 清理舊狀態
    await disconnect();

    // 1. 【快速通道】檢查是否已經在系統層級連線 (很重要！解決重連失敗的主因)
    // Android/iOS有時會自己連著藍芽，這時候掃描是掃不到的，必須直接抓出來
    List<BluetoothDevice> systemDevices = await FlutterBluePlus.connectedSystemDevices;
    for (var d in systemDevices) {
      if (_isTargetDevice(d.platformName, d.remoteId.str)) {
        print(">>> [BLE] 發現系統已連線裝置，直接使用: ${d.platformName}");
        device = d;
        return await connectDevice();
      }
    }

    // 2. 準備掃描
    Completer<BluetoothDevice?> completer = Completer();
    StreamSubscription? scanSub;

    try {
      // 確保掃描前是停止狀態
      await FlutterBluePlus.stopScan();

      // 監聽掃描結果
      scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (_isTargetDevice(r.device.platformName, r.advertisementData.serviceUuids.toString())) {
            print(">>> [BLE] 掃描發現目標: ${r.device.platformName}");

            // ★★★ 關鍵優化：一找到馬上停止掃描，不再傻傻等 4 秒 ★★★
            if (!completer.isCompleted) {
              FlutterBluePlus.stopScan();
              completer.complete(r.device);
            }
            break;
          }
        }
      });

      // 開始掃描 (設定 5 秒超時，沒找到就算了)
      print(">>> [BLE] 啟動掃描...");
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      // 等待掃描結果或超時
      device = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
        print(">>> [BLE] 掃描超時，未發現裝置");
        return null;
      });

    } catch (e) {
      print(">>> [BLE] 掃描過程錯誤: $e");
    } finally {
      // 確保停止監聽，釋放資源
      scanSub?.cancel();
      await FlutterBluePlus.stopScan();
    }

    // 3. 執行連線
    if (device != null) {
      return await connectDevice();
    }
    return null;
  }

  // 輔助判斷：是否為我們的目標車車
  bool _isTargetDevice(String name, String uuidStr) {
    String upperName = name.toUpperCase();
    String upperUuid = uuidStr.toUpperCase();

    return upperUuid.contains("FFA0") ||
        upperName == "BLE-CAR" ||
        upperName.contains("JDY") ||
        upperName.contains("BT05") ||
        upperName.contains("HM-10");
  }

  Future<BluetoothDevice?> connectDevice() async {
    if (device == null) return null;

    try {
      print(">>> [BLE] 正在建立連線: ${device!.platformName}");
      // autoConnect: false 是為了加快連線速度 (Android 適用)
      await device!.connect(license: License.free, autoConnect: false);

      // Android 需要一點點時間來發現服務
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 300)); // 縮短等待時間
        // 清除 GATT 快取，解決「連過一次後就連不上」的經典問題
        try { await device!.clearGattCache(); } catch(_) {}
      }

      print(">>> [BLE] 尋找服務 FFA0...");
      final services = await device!.discoverServices();
      for (final s in services) {
        if (s.uuid.toString().toUpperCase().contains("FFA0")) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toUpperCase().contains("FFA1")) {
              characteristic = c;
              print(">>> [BLE] 成功對接特徵值 FFA1！");
              return device;
            }
          }
        }
      }
      print(">>> [BLE] 連上了但找不到 FFA0 服務");
    } catch (e) {
      print(">>> [BLE] 連線失敗: $e");
      // 失敗一定要斷乾淨
      disconnect();
    }
    return null;
  }

  Future<void> send(String text) async {
    if (characteristic == null) return;
    try {
      await characteristic!.write(text.codeUnits, withoutResponse: true);
    } catch (e) {
      // 發送失敗通常代表斷線了
      print(">>> [BLE] 發送失敗: $e");
    }
  }
}



final BleService bleService = BleService();