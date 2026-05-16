// =============================================================================
// SMART WHEELCHAIR — ESP32 Firmware (Arduino Framework)
// =============================================================================
// Vi điều khiển: NodeMCU ESP32 (Dual-core 240MHz)
// Chức năng:
//   - Kết nối WiFi với cơ chế auto-retry
//   - Kết nối MQTT Broker (HiveMQ Cloud) qua TLS
//   - Subscribe topic lệnh điều khiển (smart_wheelchair/cmd)
//   - Publish heartbeat trạng thái (smart_wheelchair/status)
//   - Điều khiển 2 động cơ DC qua module L298N (PWM)
//   - Đọc khoảng cách vật cản qua cảm biến siêu âm HC-SR04
//   - Logic an toàn: dừng khẩn cấp khi vật cản < 15cm
//
// Thư viện cần cài trong Arduino IDE / PlatformIO:
//   - PubSubClient (by Nick O'Leary)
//   - ArduinoJson (by Benoit Blanchon)
//   - WiFiClientSecure (built-in ESP32)
// =============================================================================

#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// =============================================================================
// CẤU HÌNH BẢO MẬT (WIFI & MQTT)
// =============================================================================
// Mọi thông tin nhạy cảm đã được chuyển sang file secrets.h (không push lên Git)
#include "secrets.h"

// =============================================================================
// MQTT TOPICS — Phải khớp với Flutter App
// =============================================================================
const char *TOPIC_CMD = "smart_wheelchair/cmd";         // App → ESP32
const char *TOPIC_SENSORS = "smart_wheelchair/sensors"; // ESP32 → App
const char *TOPIC_STATUS = "smart_wheelchair/status";   // ESP32 → App (LWT)

// =============================================================================
// CẤU HÌNH CHÂN GPIO — MODULE L298N (Điều khiển 2 động cơ DC)
// =============================================================================
// Motor A = Bánh trái, Motor B = Bánh phải
// ENA/ENB: Chân PWM điều khiển tốc độ (0-255)
// IN1-IN4: Chân điều khiển hướng quay
// =============================================================================
const int ENA = 14; // PWM tốc độ motor A (bánh trái)
const int IN1 = 27; // Hướng quay motor A — chân 1
const int IN2 = 26; // Hướng quay motor A — chân 2
const int ENB = 25; // PWM tốc độ motor B (bánh phải)
const int IN3 = 33; // Hướng quay motor B — chân 1
const int IN4 = 32; // Hướng quay motor B — chân 2

// =============================================================================
// CẤU HÌNH CHÂN GPIO — CẢM BIẾN SIÊU ÂM HC-SR04
// =============================================================================
// Nguyên lý: Phát xung siêu âm (Trigger) → Đo thời gian phản hồi (Echo)
// Công thức: Khoảng cách (cm) = Thời gian (μs) × 0.034 / 2
// Phạm vi: 2cm - 400cm
// =============================================================================
const int TRIG_PIN = 5;  // Chân phát xung trigger
const int ECHO_PIN = 18; // Chân nhận xung echo

// =============================================================================
// CẤU HÌNH PWM (LEDC — LED Control trên ESP32)
// =============================================================================
// ESP32 sử dụng module LEDC để tạo xung PWM (khác Arduino Uno dùng
// analogWrite). Tần số 5000Hz, độ phân giải 8-bit (0-255).
// =============================================================================
const int PWM_FREQ = 5000;    // Tần số PWM (Hz)
const int PWM_RESOLUTION = 8; // Độ phân giải 8-bit (0-255)
const int PWM_CHANNEL_A = 0;  // Kênh LEDC cho motor A
const int PWM_CHANNEL_B = 1;  // Kênh LEDC cho motor B

// =============================================================================
// NGƯỠNG AN TOÀN
// =============================================================================
const float DANGER_DISTANCE = 15.0;  // cm — Dừng khẩn cấp
const float WARNING_DISTANCE = 30.0; // cm — Cảnh báo (giảm tốc)

// =============================================================================
// BIẾN TOÀN CỤC
// =============================================================================
WiFiClientSecure espClient;         // Client WiFi bảo mật (TLS)
PubSubClient mqttClient(espClient); // Client MQTT

unsigned long lastHeartbeat = 0;      // Thời điểm heartbeat cuối
const long HEARTBEAT_INTERVAL = 5000; // Gửi heartbeat mỗi 5 giây

unsigned long lastSensorRead = 0;      // Thời điểm đọc cảm biến cuối
const long SENSOR_READ_INTERVAL = 500; // Đọc cảm biến mỗi 500ms

bool emergencyStop = false; // Cờ dừng khẩn cấp

// =============================================================================
// HÀM KẾT NỐI WIFI
// =============================================================================
// Cơ chế auto-retry: thử tối đa 20 lần, mỗi lần cách nhau 500ms.
// Tương đương với pattern Retry trong Java (Spring Retry).
// =============================================================================
void setupWiFi() {
  Serial.println("\n[WiFi] Đang kết nối WiFi...");
  Serial.print("[WiFi] SSID: ");
  Serial.println(WIFI_SSID);

  WiFi.mode(WIFI_STA); // Chế độ Station (client)
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retryCount = 0;
  const int MAX_RETRIES = 20;

  while (WiFi.status() != WL_CONNECTED && retryCount < MAX_RETRIES) {
    delay(500);
    Serial.print(".");
    retryCount++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] ✅ Kết nối thành công!");
    Serial.print("[WiFi] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WiFi] ❌ Kết nối thất bại sau 20 lần thử.");
    Serial.println("[WiFi] Khởi động lại ESP32 sau 5 giây...");
    delay(5000);
    ESP.restart(); // Tự khởi động lại
  }
}

// =============================================================================
// HÀM KẾT NỐI MQTT BROKER
// =============================================================================
// Kết nối tới HiveMQ Cloud qua TLS/SSL.
// Cấu hình LWT (Last Will and Testament) — khi ESP32 mất kết nối đột ngột,
// broker tự động publish message offline lên topic status.
// =============================================================================
void connectMQTT() {
  while (!mqttClient.connected()) {
    Serial.println("[MQTT] Đang kết nối MQTT Broker...");

    // Cấu hình LWT — "Di chúc" của ESP32
    // Nếu ESP32 mất kết nối bất ngờ, broker sẽ tự gửi message này.
    // Tương đương với @PreDestroy trong Spring Boot.
    const char *lwtMessage = "{\"online\": false, \"state\": \"disconnected\"}";

    if (mqttClient.connect(MQTT_CLIENT, MQTT_USER, MQTT_PASS, TOPIC_STATUS, 1,
                           true, lwtMessage)) {
      Serial.println("[MQTT] ✅ Kết nối thành công!");

      // Subscribe topic lệnh điều khiển từ App
      mqttClient.subscribe(TOPIC_CMD);
      Serial.print("[MQTT] 📡 Subscribed: ");
      Serial.println(TOPIC_CMD);

      // Publish trạng thái Online (retain = true → lưu trên broker)
      publishStatus(true);

    } else {
      Serial.print("[MQTT] ❌ Thất bại, mã lỗi: ");
      Serial.println(mqttClient.state());
      Serial.println("[MQTT] Thử lại sau 3 giây...");
      delay(3000);
    }
  }
}

// =============================================================================
// CALLBACK — Xử lý message nhận được từ MQTT
// =============================================================================
// Hàm này được gọi tự động mỗi khi có message mới trên topic đã subscribe.
// Tương đương với @MessageMapping trong Spring WebSocket.
// =============================================================================
void mqttCallback(char *topic, byte *payload, unsigned int length) {
  // Chuyển payload byte[] → String
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("[MQTT] 📩 Nhận từ [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);

  // Xử lý lệnh điều khiển
  if (String(topic) == TOPIC_CMD) {
    handleCommand(message);
  }
}

// =============================================================================
// XỬ LÝ LỆNH ĐIỀU KHIỂN TỪ APP
// =============================================================================
// Parse JSON và điều khiển motor tương ứng.
// JSON format: {"cmd": "forward", "speed": 200}
//
// Bảng điều khiển:
//   forward  → Cả 2 motor quay tiến
//   backward → Cả 2 motor quay lùi
//   left     → Motor phải tiến, motor trái dừng (xoay tại chỗ)
//   right    → Motor trái tiến, motor phải dừng (xoay tại chỗ)
//   stop     → Tất cả dừng
// =============================================================================
void handleCommand(String jsonMessage) {
  // Cấp phát bộ nhớ cho JSON document (tương đương ObjectMapper trong Jackson)
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, jsonMessage);

  if (error) {
    Serial.print("[CMD] ❌ Lỗi parse JSON: ");
    Serial.println(error.c_str());
    return;
  }

  const char *cmd = doc["cmd"];   // Lệnh điều khiển
  int speed = doc["speed"] | 200; // Tốc độ PWM (mặc định 200)

  Serial.print("[CMD] 🎮 Lệnh: ");
  Serial.print(cmd);
  Serial.print(" | Tốc độ: ");
  Serial.println(speed);

  // Kiểm tra dừng khẩn cấp — nếu vật cản quá gần, từ chối lệnh tiến
  if (emergencyStop && strcmp(cmd, "forward") == 0) {
    Serial.println("[SAFETY] ⛔ Từ chối lệnh TIẾN — Vật cản quá gần!");
    stopMotors();
    return;
  }

  // Thực thi lệnh điều khiển motor
  if (strcmp(cmd, "forward") == 0) {
    moveForward(speed);
  } else if (strcmp(cmd, "backward") == 0) {
    moveBackward(speed);
  } else if (strcmp(cmd, "left") == 0) {
    turnLeft(speed);
  } else if (strcmp(cmd, "right") == 0) {
    turnRight(speed);
  } else if (strcmp(cmd, "stop") == 0) {
    stopMotors();
  } else {
    Serial.print("[CMD] ⚠️ Lệnh không hợp lệ: ");
    Serial.println(cmd);
  }
}

// =============================================================================
// ĐIỀU KHIỂN MOTOR — Module L298N
// =============================================================================
// L298N hoạt động theo nguyên tắc:
//   IN1=HIGH, IN2=LOW  → Motor quay tiến
//   IN1=LOW,  IN2=HIGH → Motor quay lùi
//   IN1=LOW,  IN2=LOW  → Motor dừng (freewheel)
//   ENA (PWM)          → Điều chỉnh tốc độ (0=dừng, 255=max)
//
// Tương đương với điều khiển GPIO trong Java Pi4J trên Raspberry Pi.
// =============================================================================

/// Di chuyển tiến — cả 2 motor quay cùng chiều.
void moveForward(int speed) {
  Serial.println("[MOTOR] ⬆ TIẾN");
  // Motor A (trái) — tiến
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  // Motor B (phải) — tiến
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  // Đặt tốc độ
  ledcWrite(ENA, speed);
  ledcWrite(ENB, speed);
}

/// Di chuyển lùi — cả 2 motor quay ngược chiều.
void moveBackward(int speed) {
  Serial.println("[MOTOR] ⬇ LÙI");
  // Motor A (trái) — lùi
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  // Motor B (phải) — lùi
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  // Đặt tốc độ
  ledcWrite(ENA, speed);
  ledcWrite(ENB, speed);
}

/// Rẽ trái — motor phải tiến, motor trái dừng.
void turnLeft(int speed) {
  Serial.println("[MOTOR] ⬅ RẼ TRÁI");
  // Motor A (trái) — dừng
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  ledcWrite(ENA, 0);
  // Motor B (phải) — tiến
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  ledcWrite(ENB, speed);
}

/// Rẽ phải — motor trái tiến, motor phải dừng.
void turnRight(int speed) {
  Serial.println("[MOTOR] ➡ RẼ PHẢI");
  // Motor A (trái) — tiến
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  ledcWrite(ENA, speed);
  // Motor B (phải) — dừng
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  ledcWrite(ENB, 0);
}

/// Dừng tất cả motor.
void stopMotors() {
  Serial.println("[MOTOR] ⏹ DỪNG");
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  ledcWrite(ENA, 0);
  ledcWrite(ENB, 0);
}

// =============================================================================
// ĐỌC CẢM BIẾN SIÊU ÂM HC-SR04
// =============================================================================
// Nguyên lý hoạt động:
//   1. Phát xung Trigger 10μs (HIGH)
//   2. Đo thời gian Echo (từ HIGH → LOW)
//   3. Tính khoảng cách: distance = duration × 0.034 / 2
//
// Vận tốc âm thanh trong không khí: ~340 m/s = 0.034 cm/μs
// Chia 2 vì sóng đi và về.
//
// Tương đương với việc đọc sensor qua I2C/SPI trong Java embedded.
// =============================================================================
float readUltrasonic() {
  // Bước 1: Đảm bảo Trigger ở mức LOW
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  // Bước 2: Phát xung Trigger 10μs
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Bước 3: Đo thời gian Echo (timeout 30ms ≈ 500cm)
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);

  // Bước 4: Tính khoảng cách (cm)
  float distance = duration * 0.034 / 2.0;

  // Kiểm tra giá trị hợp lệ (phạm vi HC-SR04: 2-400cm)
  if (distance <= 0 || distance > 400) {
    distance = 400.0; // Ngoài phạm vi → coi như không có vật cản
  }

  return distance;
}

// =============================================================================
// PUBLISH DỮ LIỆU CẢM BIẾN LÊN MQTT
// =============================================================================
// Đóng gói dữ liệu vào JSON và publish lên topic sensors.
// JSON format: {"distance": 45.2, "battery": 87.5, "timestamp": 123456}
// =============================================================================
void publishSensorData(float distance, float battery) {
  JsonDocument doc;
  doc["distance"] =
      round(distance * 10.0) / 10.0; // Làm tròn 1 chữ số thập phân
  doc["battery"] = round(battery * 10.0) / 10.0;
  doc["timestamp"] = millis() / 1000; // Uptime tính bằng giây

  char buffer[128];
  serializeJson(doc, buffer);

  mqttClient.publish(TOPIC_SENSORS, buffer);

  Serial.print("[SENSOR] 📤 distance=");
  Serial.print(distance);
  Serial.print("cm | battery=");
  Serial.print(battery);
  Serial.println("%");
}

// =============================================================================
// PUBLISH TRẠNG THÁI THIẾT BỊ (Heartbeat)
// =============================================================================
void publishStatus(bool isOnline) {
  JsonDocument doc;
  doc["online"] = isOnline;
  doc["state"] = isOnline ? "connected" : "disconnected";

  char buffer[128];
  serializeJson(doc, buffer);

  mqttClient.publish(TOPIC_STATUS, buffer, true); // retain = true
  Serial.print("[STATUS] 📤 ");
  Serial.println(buffer);
}

// =============================================================================
// ĐỌC MỨC PIN (Ước tính qua ADC)
// =============================================================================
// Đọc điện áp qua chân ADC (GPIO 34) và quy đổi sang phần trăm.
// ESP32 ADC: 12-bit (0-4095), điện áp tham chiếu 3.3V.
// Lưu ý: Đây là ước tính đơn giản. Pin thật cần mạch đo chuyên dụng.
// =============================================================================
float readBatteryLevel() {
  int adcValue = analogRead(34);           // Đọc giá trị ADC (0-4095)
  float voltage = adcValue / 4095.0 * 3.3; // Quy đổi sang Volt

  // Ước tính phần trăm pin (giả sử pin LiPo 3.0V-4.2V)
  float percentage = (voltage - 3.0) / (4.2 - 3.0) * 100.0;
  percentage = constrain(percentage, 0.0, 100.0);

  return percentage;
}

// =============================================================================
// LOGIC AN TOÀN — NGẮT KHẨN CẤP
// =============================================================================
// Kiểm tra khoảng cách vật cản mỗi chu kỳ đọc cảm biến.
// Nếu vật cản < 15cm → BUỘC xe dừng lập tức, BẤT KỂ lệnh từ App.
// Đây là tuyến phòng thủ cuối cùng (Last Line of Defense) trên phần cứng.
//
// Tương đương với Circuit Breaker pattern trong microservices.
// =============================================================================
void checkSafety(float distance) {
  if (distance > 0 && distance < DANGER_DISTANCE) {
    // ⛔ NGUY HIỂM — Dừng khẩn cấp
    if (!emergencyStop) {
      Serial.println("=========================================");
      Serial.println("[SAFETY] ⛔ VẬT CẢN QUÁ GẦN — DỪNG KHẨN CẤP!");
      Serial.print("[SAFETY] Khoảng cách: ");
      Serial.print(distance);
      Serial.println(" cm");
      Serial.println("=========================================");

      stopMotors();
      emergencyStop = true;
    }
  } else if (distance >= WARNING_DISTANCE) {
    // ✅ An toàn — gỡ cờ dừng khẩn cấp
    if (emergencyStop) {
      Serial.println("[SAFETY] ✅ Vật cản đã rời xa — Cho phép di chuyển.");
      emergencyStop = false;
    }
  }
  // Vùng 15-30cm: Cảnh báo nhưng không dừng (App sẽ hiển thị warning)
}

// =============================================================================
// SETUP — Chạy một lần khi ESP32 khởi động
// =============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("   SMART WHEELCHAIR — ESP32 Firmware");
  Serial.println("   Version: 1.0.0");
  Serial.println("========================================");

  // 1. Kết nối WiFi
  setupWiFi();

  // 2. Cấu hình MQTT
  espClient.setInsecure(); // Bỏ qua xác thực chứng chỉ (dev/demo mode)
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(512); // Tăng buffer cho JSON payload lớn

  // 3. Cấu hình chân GPIO cho L298N
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  // Cấu hình PWM bằng LEDC (ESP32-specific)
  ledcAttach(ENA, PWM_FREQ, PWM_RESOLUTION);
  ledcAttach(ENB, PWM_FREQ, PWM_RESOLUTION);

  // 4. Cấu hình chân GPIO cho HC-SR04
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // 5. Đảm bảo motor dừng khi khởi động
  stopMotors();

  // 6. Kết nối MQTT Broker
  connectMQTT();

  Serial.println("[SETUP] ✅ Khởi tạo hoàn tất! Sẵn sàng hoạt động.");
}

// =============================================================================
// LOOP — Vòng lặp chính (chạy liên tục)
// =============================================================================
void loop() {
  // --- Kiểm tra và duy trì kết nối MQTT ---
  if (!mqttClient.connected()) {
    stopMotors(); // Dừng motor khi mất kết nối (an toàn)
    connectMQTT();
  }
  mqttClient.loop(); // Xử lý message queue của PubSubClient

  unsigned long now = millis();

  // --- Đọc cảm biến mỗi 500ms ---
  if (now - lastSensorRead > SENSOR_READ_INTERVAL) {
    lastSensorRead = now;

    // Đọc khoảng cách vật cản
    float distance = readUltrasonic();

    // Đọc mức pin (ước tính)
    float battery = readBatteryLevel();

    // Kiểm tra an toàn — DỪNG KHẨN CẤP nếu cần
    checkSafety(distance);

    // Publish dữ liệu cảm biến lên App
    publishSensorData(distance, battery);
  }

  // --- Gửi heartbeat mỗi 5 giây ---
  if (now - lastHeartbeat > HEARTBEAT_INTERVAL) {
    lastHeartbeat = now;
    publishStatus(true);
  }
}
