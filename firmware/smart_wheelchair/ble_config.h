#ifndef BLE_CONFIG_H
#define BLE_CONFIG_H

// =============================================================================
// BLE GATT SERVER — Cấu hình Bluetooth Low Energy cho SmartWheelchair
// =============================================================================
// Các UUID phải khớp 100% với Flutter App (ble_constants.dart).
// ESP32 hoạt động như BLE Peripheral (GATT Server), App là Central (Client).
// =============================================================================

// Tên thiết bị BLE — hiển thị khi scan
const char *BLE_DEVICE_NAME = "SmartWheelchair_01";

// Service UUID — Custom UUID cho SmartWheelchair
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"

// Characteristic: Sensor Data (ESP32 → App)
// Properties: Notify
// Payload: JSON {"distance": 45.2, "battery": 87.5}
#define CHAR_SENSORS_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Characteristic: Command (App → ESP32)
// Properties: Write
// Payload: JSON {"cmd": "forward", "speed": 200}
#define CHAR_COMMAND_UUID "e3223119-9445-4e96-a4a1-85358c4046a2"

// Characteristic: Status (ESP32 → App)
// Properties: Read + Notify
// Payload: JSON {"online": true, "state": "connected"}
#define CHAR_STATUS_UUID "d1a7e3b5-7c8f-4a2d-9e6b-5f3c1d8e2a4b"

#endif
