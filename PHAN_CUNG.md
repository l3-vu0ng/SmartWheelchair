# 🔧 Yêu cầu Phần cứng — SmartWheel

## Phần cứng hiện có

| # | Linh kiện | Số lượng | Chức năng hiện tại |
|---|---|---|---|
| 1 | NodeMCU ESP32 DevKit V1 | 1 | Vi điều khiển chính, WiFi, MQTT |
| 2 | Module L298N | 1 | Điều khiển 2 motor DC |
| 3 | Cảm biến HC-SR04 | 1 | Đo khoảng cách vật cản |
| 4 | Motor DC | 2 | Động cơ bánh trái + phải |
| 5 | Pin / Nguồn cấp | 1 | Cấp nguồn toàn hệ thống |

---

## Phần cứng cần mua thêm

| # | Linh kiện | Model đề xuất | Giá ước tính | Dùng cho chức năng | Giao tiếp |
|---|---|---|---|---|---|
| 1 | **Cảm biến nhịp tim** | MAX30102 | 80k–120k VNĐ | Theo dõi nhịp tim realtime | I2C (SDA/SCL) |
| 2 | **Gia tốc kế + Gyroscope** | MPU6050 (GY-521) | 30k–50k VNĐ | Phát hiện ngã, nghiêng xe | I2C (SDA/SCL) |
| 3 | **Module GPS** | NEO-6M (GY-GPS6MV2) | 100k–150k VNĐ | Định vị, điều hướng bản đồ | UART (TX/RX) |
| 4 | **Module Microphone** | INMP441 (I2S) | 50k–80k VNĐ | Lệnh giọng nói | I2S |
| 5 | **Điện trở chia áp** | 10kΩ + 20kΩ | ~2k VNĐ | Đo mức pin qua ADC | Analog (GPIO34) |

**Tổng chi phí ước tính:** 260k – 400k VNĐ

---

## Sơ đồ chân GPIO dự kiến

```
ESP32 DevKit V1
┌─────────────────────────────────────┐
│                                     │
│  GPIO14 (ENA) ──→ L298N Motor A    │  ← Đã dùng
│  GPIO27 (IN1) ──→ L298N            │  ← Đã dùng
│  GPIO26 (IN2) ──→ L298N            │  ← Đã dùng
│  GPIO25 (ENB) ──→ L298N Motor B    │  ← Đã dùng
│  GPIO33 (IN3) ──→ L298N            │  ← Đã dùng
│  GPIO32 (IN4) ──→ L298N            │  ← Đã dùng
│  GPIO5  (TRIG) ─→ HC-SR04         │  ← Đã dùng
│  GPIO18 (ECHO) ─→ HC-SR04         │  ← Đã dùng
│                                     │
│  GPIO21 (SDA) ──→ MAX30102 + MPU6050│  ← Cần thêm (I2C bus chung)
│  GPIO22 (SCL) ──→ MAX30102 + MPU6050│  ← Cần thêm (I2C bus chung)
│  GPIO16 (RX2) ──→ NEO-6M TX       │  ← Cần thêm
│  GPIO17 (TX2) ──→ NEO-6M RX       │  ← Cần thêm
│  GPIO34 (ADC) ──→ Mạch chia áp pin │  ← Cần thêm
│  GPIO19 (WS)  ──→ INMP441 WS      │  ← Cần thêm
│  GPIO23 (SD)  ──→ INMP441 SD      │  ← Cần thêm
│  GPIO4  (SCK) ──→ INMP441 SCK     │  ← Cần thêm
│                                     │
└─────────────────────────────────────┘
```

> **Lưu ý:** MAX30102 và MPU6050 dùng chung bus I2C (cùng SDA/SCL) vì mỗi module có địa chỉ I2C khác nhau (0x57 và 0x68). Chỉ cần 2 chân GPIO cho cả 2.

---

## Thư viện Arduino cần cài thêm

| Thư viện | Cho linh kiện | Cài qua |
|---|---|---|
| `Wire.h` | I2C (MAX30102 + MPU6050) | Built-in ESP32 |
| `MAX30105.h` | MAX30102 | SparkFun MAX3010x |
| `MPU6050.h` | MPU6050 | MPU6050 by Electronic Cats |
| `TinyGPSPlus.h` | NEO-6M GPS | TinyGPSPlus by Mikal Hart |
| `driver/i2s.h` | INMP441 Mic | Built-in ESP32 |

---

## Danh sách mua hàng (Shopee / Lazada)

Tìm kiếm các từ khóa sau:
1. `MAX30102 module cảm biến nhịp tim` — chọn loại có header đã hàn
2. `GY-521 MPU6050 gia tốc kế` — loại board xanh phổ biến nhất
3. `GY-GPS6MV2 NEO-6M GPS module` — loại có anten gốm kèm theo
4. `INMP441 I2S microphone module` — loại board tím/đen nhỏ gọn
5. `Điện trở 10kΩ + 20kΩ` — mua combo pack

> Tất cả đều dùng điện áp 3.3V, tương thích trực tiếp với ESP32 mà không cần level shifter.
