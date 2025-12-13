lib/
 ├── BLE/
 │    └── ble_service.dart        // BLE 掃描、連線、送資料
 │
 ├── Controllers/
 │    └── car_controller.dart     // 將 UI 操作轉成控制指令
 │
 ├── UI/
 │    ├── control_page.dart       // 主控制畫面
 │    ├── status_panel.dart       // BLE 狀態顯示
 │    └── widgets/
 │          ├── joystick.dart     // 方向搖桿
 │          └── vertical_lever.dart // 油門 / 煞車（垂直拉桿）
 │
 ├── main.dart                    // App 入口
