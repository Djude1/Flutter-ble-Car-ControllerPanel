# Flutter BLE 遙控車 App

本專案是一個使用 **Flutter** 開發的行動應用程式，透過 **Bluetooth Low Energy（BLE）** 與車輛控制模組（如 樹梅派）進行通訊，實現即時遙控車輛行駛的功能。App 以模組化架構設計，將 BLE 通訊、控制邏輯與 UI 清楚拆分，方便維護與擴充。
---

## 📂 專案目錄結構說明

```text
lib/
 ├── BLE/
 │    └── ble_service.dart        // BLE 掃描、連線、資料傳輸封裝
 │
 ├── Controllers/
 │    └── car_controller.dart     // 控制邏輯，將 UI 操作轉為車輛指令
 │
 ├── UI/
 │    ├── control_page.dart       // 主控制畫面（整合所有控制元件）
 │    ├── status_panel.dart       // BLE 狀態顯示元件
 │    └── widgets/
 │          ├── joystick.dart     // 方向控制搖桿元件
 │          └── vertical_lever.dart // 油門 / 煞車垂直拉桿
 │
 ├── main.dart                    // App 入口點
```