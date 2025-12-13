import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  // ==========================================================
  // ★★★ 關鍵修正：根據你舊程式碼 (FFA0)，這是正確的 UUID ★★★
  // ==========================================================
  final Guid serviceUuid = Guid('0000FFA0-0000-1000-8000-00805F9B34FB');
  final Guid charUuid =    Guid('0000FFA1-0000-1000-8000-00805F9B34FB');

  bool get isConnected => characteristic != null && device != null;

  Future<void> disconnect() async {
    try {
      await device?.disconnect();
    } catch (_) {}
    device = null;
    characteristic = null;
  }

  Future<BluetoothDevice?> scanAndConnect() async {
    print(">>> [BLE] 開始掃描 (目標 UUID: FFA0)...");

    await FlutterBluePlus.stopScan();

    try {
      // 啟動掃描 (4秒)
      // 這次我們不限制 Service UUID，改用廣泛掃描以免過濾掉
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      print(">>> [錯誤] 掃描啟動失敗: $e");
      return null;
    }

    BluetoothDevice? target;

    // 監聽掃描結果
    var subscription = FlutterBluePlus.scanResults.listen((scanData) {
      for (final r in scanData) {
        String name = r.device.platformName;

        // Debug: 印出來看
        if (name.isNotEmpty) {
          print(">>> 發現: [$name] RSSI:${r.rssi} UUIDs:${r.advertisementData.serviceUuids}");
        }

        // 判斷邏輯：
        // 1. 如果名字吻合
        // 2. 或者廣播封包裡直接含有 FFA0
        // 3. 或者常見的藍芽模組名稱
        bool hasService = r.advertisementData.serviceUuids.toString().toUpperCase().contains("FFA0");

        if (hasService ||
            name == "BLE-Car" ||
            name.contains("JDY") ||
            name.contains("BT05") ||
            name.contains("HM-10") ||
            name.contains("HC-08")) {

          print(">>> 鎖定目標！準備連線: $name");
          target = r.device;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 4));
    await subscription.cancel();
    await FlutterBluePlus.stopScan();

    if (target == null) {
      print(">>> 找不到裝置");
      return null;
    }

    print(">>> 正在連線到: ${target!.platformName}");
    device = target;
    return await connectDevice();
  }

  Future<BluetoothDevice?> connectDevice() async {
    if (device == null) return null;

    try {
      await device!.connect(license: License.free, autoConnect: false);
      print(">>> 連線成功！正在尋找服務 (FFA0)...");

      // 稍微延遲確保服務載入
      await Future.delayed(const Duration(milliseconds: 500));

      final services = await device!.discoverServices();
      for (final s in services) {
        String sUuid = s.uuid.toString().toUpperCase();

        // ★★★ 修正：尋找 FFA0 ★★★
        if (sUuid.contains("FFA0")) {
          print(">>> 找到 Service: $sUuid");

          for (final c in s.characteristics) {
            String cUuid = c.uuid.toString().toUpperCase();
            // ★★★ 修正：尋找 FFA1 ★★★
            if (cUuid.contains("FFA1")) {
              characteristic = c;

              // 嘗試開啟通知 (Notify) - 雖然這專案主要只用寫入
              if (c.properties.notify) {
                await c.setNotifyValue(true);
              }

              print(">>> [成功] 特徵值 (FFA1) 對接完成！");
              return device;
            }
          }
        }
      }
      print(">>> [警告] 找不到 FFA0 服務，請確認模組型號");

    } catch (e) {
      print(">>> [連線錯誤]: $e");
      disconnect();
    }
    return null;
  }

  Future<void> send(String text) async {
    if (characteristic == null) return;
    try {
      await characteristic!.write(text.codeUnits, withoutResponse: true);
    } catch (e) {
      print("發送失敗: $e");
    }
  }
}

final BleService bleService = BleService();