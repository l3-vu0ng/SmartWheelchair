// =============================================================================
// SMART WHEELCHAIR — ESP32 Firmware (Arduino Framework)
// =============================================================================
// Vi điều khiển: NodeMCU ESP32 (Dual-core 240MHz)
// Chức năng:
//   - Kết nối WiFi với cơ chế auto-retry
//   - Kết nối MQTT Broker (HiveMQ Cloud) qua TLS
//   - BLE GATT Server cho kết nối trực tiếp với App
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
//   - BLE (built-in ESP32)
// =============================================================================

#include <ArduinoJson.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <PubSubClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// =============================================================================
// CẤU HÌNH BẢO MẬT (WIFI & MQTT)
// =============================================================================
#include "secrets.h"

// =============================================================================
// CẤU HÌNH BLE
// =============================================================================
#include "ble_config.h"

// =============================================================================
// MQTT TOPICS — Phải khớp với Flutter App
// =============================================================================
const char *TOPIC_CMD = "smart_wheelchair/cmd";         // App → ESP32
const char *TOPIC_SENSORS = "smart_wheelchair/sensors"; // ESP32 → App
const char *TOPIC_STATUS = "smart_wheelchair/status";   // ESP32 → App (LWT)

// =============================================================================
// CẤU HÌNH CHÂN GPIO — MODULE L298N (Điều khiển 2 động cơ DC)
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
const int TRIG_PIN = 5;  // Chân phát xung trigger
const int ECHO_PIN = 18; // Chân nhận xung echo

// =============================================================================
// CẤU HÌNH PWM (LEDC — LED Control trên ESP32)
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
// BIẾN TOÀN CỤC — WIFI/MQTT
// =============================================================================
WiFiClientSecure espClient;         // Client WiFi bảo mật (TLS)
PubSubClient mqttClient(espClient); // Client MQTT

unsigned long lastHeartbeat = 0;      // Thời điểm heartbeat cuối
const long HEARTBEAT_INTERVAL = 5000; // Gửi heartbeat mỗi 5 giây

unsigned long lastSensorRead = 0;      // Thời điểm đọc cảm biến cuối
const long SENSOR_READ_INTERVAL = 500; // Đọc cảm biến mỗi 500ms

unsigned long lastMqttAttempt = 0;      // Thời điểm thử kết nối MQTT cuối
const long MQTT_ATTEMPT_INTERVAL = 5000; // Thử kết nối lại MQTT mỗi 5 giây
bool lastMqttStateConnected = false;    // Lưu trạng thái kết nối MQTT trước đó

bool emergencyStop = false; // Cờ dừng khẩn cấp

// =============================================================================
// BIẾN TOÀN CỤC — BLE
// =============================================================================
BLEServer *pServer = NULL;
BLECharacteristic *pSensorChar = NULL;
BLECharacteristic *pCommandChar = NULL;
BLECharacteristic *pStatusChar = NULL;
bool bleClientConnected = false;
bool oldBleClientConnected = false;

// =============================================================================
// BLE CALLBACKS
// =============================================================================

/// Callback khi BLE Client kết nối/ngắt kết nối.
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    bleClientConnected = true;
    Serial.println("[BLE] ✅ Client kết nối!");
  }

  void onDisconnect(BLEServer *pServer) {
    bleClientConnected = false;
    Serial.println("[BLE] ❌ Client ngắt kết nối.");
  }
};

/// Callback khi nhận lệnh từ App qua BLE Write.
class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue();
    if (value.length() > 0) {
      Serial.print("[BLE] 📩 Nhận lệnh: ");
      Serial.println(value.c_str());
      // Xử lý lệnh giống MQTT callback
      handleCommand(value);
    }
  }
};

// =============================================================================
// BLE SETUP — Khởi tạo BLE GATT Server
// =============================================================================
void setupBLE() {
  Serial.println("[BLE] Đang khởi tạo BLE Server...");

  BLEDevice::init(BLE_DEVICE_NAME);

  // Tạo BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Tạo BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Characteristic 1: Sensor Data (Notify)
  pSensorChar = pService->createCharacteristic(
      CHAR_SENSORS_UUID,
      BLECharacteristic::PROPERTY_NOTIFY);
  pSensorChar->addDescriptor(new BLE2902());

  // Characteristic 2: Command (Write)
  pCommandChar = pService->createCharacteristic(
      CHAR_COMMAND_UUID,
      BLECharacteristic::PROPERTY_WRITE);
  pCommandChar->setCallbacks(new CommandCallbacks());

  // Characteristic 3: Status (Read + Notify)
  pStatusChar = pService->createCharacteristic(
      CHAR_STATUS_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pStatusChar->addDescriptor(new BLE2902());

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.print("[BLE] ✅ BLE Server sẵn sàng! Tên: ");
  Serial.println(BLE_DEVICE_NAME);
}

// =============================================================================
// BLE PUBLISH — Gửi dữ liệu qua BLE Notify
// =============================================================================

/// Gửi sensor data qua BLE notification.
void publishSensorDataBLE(float distance, float battery) {
  if (!bleClientConnected || pSensorChar == NULL) return;

  JsonDocument doc;
  doc["distance"] = round(distance * 10.0) / 10.0;
  doc["battery"] = round(battery * 10.0) / 10.0;
  doc["latitude"] = 21.028511;
  doc["longitude"] = 105.804817;
  doc["timestamp"] = millis() / 1000;

  char buffer[128];
  serializeJson(doc, buffer);

  pSensorChar->setValue(buffer);
  pSensorChar->notify();
}

/// Gửi status qua BLE notification.
void publishStatusBLE(bool isOnline) {
  if (pStatusChar == NULL) return;

  JsonDocument doc;
  doc["online"] = isOnline;
  doc["state"] = isOnline ? "connected" : "disconnected";

  char buffer[128];
  serializeJson(doc, buffer);

  pStatusChar->setValue(buffer);
  if (bleClientConnected) {
    pStatusChar->notify();
  }
}

// =============================================================================
// HÀM KẾT NỐI WIFI
// =============================================================================
void setupWiFi() {
  Serial.println("\n[WiFi] Đang kết nối WiFi...");
  Serial.print("[WiFi] SSID: ");
  Serial.println(WIFI_SSID);

  WiFi.mode(WIFI_STA);
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
    Serial.println("[WiFi] Tiếp tục ở chế độ ngoại tuyến (BLE-Only)...");
  }
}

// =============================================================================
// HÀM KẾT NỐI MQTT BROKER (KHÔNG CHẶN)
// =============================================================================
void connectMQTTNonBlocking() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  if (mqttClient.connected()) {
    return;
  }

  unsigned long now = millis();
  if (now - lastMqttAttempt > MQTT_ATTEMPT_INTERVAL) {
    lastMqttAttempt = now;
    Serial.println("[MQTT] Đang thử kết nối lại MQTT Broker (không chặn)...");

    const char *lwtMessage = "{\"online\": false, \"state\": \"disconnected\"}";

    if (mqttClient.connect(MQTT_CLIENT, MQTT_USER, MQTT_PASS, TOPIC_STATUS, 1,
                           true, lwtMessage)) {
      Serial.println("[MQTT] ✅ Kết nối thành công!");

      mqttClient.subscribe(TOPIC_CMD);
      Serial.print("[MQTT] 📡 Subscribed: ");
      Serial.println(TOPIC_CMD);

      publishStatus(true);
    } else {
      Serial.print("[MQTT] ❌ Thất bại, mã lỗi: ");
      Serial.println(mqttClient.state());
    }
  }
}

// =============================================================================
// CALLBACK — Xử lý message nhận được từ MQTT
// =============================================================================
void mqttCallback(char *topic, byte *payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("[MQTT] 📩 Nhận từ [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);

  if (String(topic) == TOPIC_CMD) {
    handleCommand(message);
  }
}

// =============================================================================
// XỬ LÝ LỆNH ĐIỀU KHIỂN — Chung cho cả MQTT và BLE
// =============================================================================
void handleCommand(String jsonMessage) {
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, jsonMessage);

  if (error) {
    Serial.print("[CMD] ❌ Lỗi parse JSON: ");
    Serial.println(error.c_str());
    return;
  }

  const char *cmd = doc["cmd"];
  int speed = doc["speed"] | 200;

  Serial.print("[CMD] 🎮 Lệnh: ");
  Serial.print(cmd);
  Serial.print(" | Tốc độ: ");
  Serial.println(speed);

  // Kiểm tra dừng khẩn cấp
  if (emergencyStop && strcmp(cmd, "forward") == 0) {
    Serial.println("[SAFETY] ⛔ Từ chối lệnh TIẾN — Vật cản quá gần!");
    stopMotors();
    return;
  }

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

void moveForward(int speed) {
  Serial.println("[MOTOR] ⬆ TIẾN");
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  ledcWrite(ENA, speed);
  ledcWrite(ENB, speed);
}

void moveBackward(int speed) {
  Serial.println("[MOTOR] ⬇ LÙI");
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  ledcWrite(ENA, speed);
  ledcWrite(ENB, speed);
}

void turnLeft(int speed) {
  Serial.println("[MOTOR] ⬅ RẼ TRÁI");
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  ledcWrite(ENA, 0);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  ledcWrite(ENB, speed);
}

void turnRight(int speed) {
  Serial.println("[MOTOR] ➡ RẼ PHẢI");
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  ledcWrite(ENA, speed);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  ledcWrite(ENB, 0);
}

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
float readUltrasonic() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);

  float distance = duration * 0.034 / 2.0;

  if (distance <= 0 || distance > 400) {
    distance = 400.0;
  }

  return distance;
}

// =============================================================================
// PUBLISH DỮ LIỆU CẢM BIẾN — MQTT
// =============================================================================
void publishSensorData(float distance, float battery) {
  JsonDocument doc;
  doc["distance"] = round(distance * 10.0) / 10.0;
  doc["battery"] = round(battery * 10.0) / 10.0;
  doc["latitude"] = 21.028511;
  doc["longitude"] = 105.804817;
  doc["timestamp"] = millis() / 1000;

  char buffer[128];
  serializeJson(doc, buffer);

  mqttClient.publish(TOPIC_SENSORS, buffer);

  Serial.print("[SENSOR] 📤 distance=");
  Serial.print(distance);
  Serial.print("cm | battery=");
  Serial.print(battery);
  Serial.print("% | lat=");
  Serial.print(21.028511);
  Serial.print(" | lng=");
  Serial.println(105.804817);
}

// =============================================================================
// PUBLISH TRẠNG THÁI — MQTT
// =============================================================================
void publishStatus(bool isOnline) {
  JsonDocument doc;
  doc["online"] = isOnline;
  doc["state"] = isOnline ? "connected" : "disconnected";

  char buffer[128];
  serializeJson(doc, buffer);

  mqttClient.publish(TOPIC_STATUS, buffer, true);
  Serial.print("[STATUS] 📤 ");
  Serial.println(buffer);
}

// =============================================================================
// ĐỌC MỨC PIN (Ước tính qua ADC)
// =============================================================================
float readBatteryLevel() {
  int adcValue = analogRead(34);
  
  // Đổi giá trị ADC (0-4095) thành điện áp trên chân pin ESP32 (0V-3.3V)
  float pinVoltage = adcValue / 4095.0 * 3.3;
  
  // Tính toán điện áp thực tế của pin thông qua hệ số cầu phân áp (mặc định 4.2V / 3.3V = 1.27)
  float batteryVoltage = pinVoltage * (4.2 / 3.3);
  
  // Ước lượng phi tuyến tính cho pin Lithium-ion 1S
  float percentage = 0.0;
  if (batteryVoltage >= 4.15) {
    percentage = 100.0;
  } else if (batteryVoltage >= 4.0) {
    percentage = 90.0 + (batteryVoltage - 4.0) / (4.15 - 4.0) * 10.0;
  } else if (batteryVoltage >= 3.82) {
    percentage = 70.0 + (batteryVoltage - 3.82) / (4.0 - 3.82) * 20.0;
  } else if (batteryVoltage >= 3.75) {
    percentage = 50.0 + (batteryVoltage - 3.75) / (3.82 - 3.75) * 20.0;
  } else if (batteryVoltage >= 3.7) {
    percentage = 30.0 + (batteryVoltage - 3.7) / (3.75 - 3.7) * 20.0;
  } else if (batteryVoltage >= 3.6) {
    percentage = 15.0 + (batteryVoltage - 3.6) / (3.7 - 3.6) * 15.0;
  } else if (batteryVoltage >= 3.5) {
    percentage = 5.0 + (batteryVoltage - 3.5) / (3.6 - 3.5) * 10.0;
  } else if (batteryVoltage >= 3.0) {
    percentage = 0.0 + (batteryVoltage - 3.0) / (3.5 - 3.0) * 5.0;
  } else {
    percentage = 0.0;
  }
  
  return percentage;
}

// =============================================================================
// LOGIC AN TOÀN — NGẮT KHẨN CẤP
// =============================================================================
void checkSafety(float distance) {
  if (distance > 0 && distance < DANGER_DISTANCE) {
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
    if (emergencyStop) {
      Serial.println("[SAFETY] ✅ Vật cản đã rời xa — Cho phép di chuyển.");
      emergencyStop = false;
    }
  }
}

// =============================================================================
// SETUP — Chạy một lần khi ESP32 khởi động
// =============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("   SMART WHEELCHAIR — ESP32 Firmware");
  Serial.println("   Version: 2.0.0 (WiFi + BLE)");
  Serial.println("========================================");

  // 1. Khởi tạo BLE Server (trước WiFi để BLE sẵn sàng ngay)
  setupBLE();

  // 2. Kết nối WiFi
  setupWiFi();

  // 3. Cấu hình MQTT
  espClient.setInsecure();
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(512);

  // 4. Cấu hình chân GPIO cho L298N
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  // Cấu hình PWM
  ledcAttach(ENA, PWM_FREQ, PWM_RESOLUTION);
  ledcAttach(ENB, PWM_FREQ, PWM_RESOLUTION);

  // 5. Cấu hình chân GPIO cho HC-SR04
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // 6. Đảm bảo motor dừng khi khởi động
  stopMotors();

  // 7. Kết nối MQTT Broker
  connectMQTTNonBlocking();

  Serial.println("[SETUP] ✅ Khởi tạo hoàn tất! WiFi + BLE sẵn sàng.");
}

// =============================================================================
// LOOP — Vòng lặp chính (chạy liên tục)
// =============================================================================
void loop() {
  // --- Kiểm tra và duy trì kết nối MQTT (Không chặn) ---
  bool currentMqttState = mqttClient.connected();
  if (lastMqttStateConnected && !currentMqttState) {
    // Vừa mất kết nối -> Dừng động cơ để đảm bảo an toàn
    Serial.println("[SAFETY] ⚠️ Mất kết nối MQTT! Dừng động cơ.");
    stopMotors();
  }
  lastMqttStateConnected = currentMqttState;

  connectMQTTNonBlocking();

  if (mqttClient.connected()) {
    mqttClient.loop();
  }

  // --- Xử lý BLE reconnect advertising ---
  if (!bleClientConnected && oldBleClientConnected) {
    // Client đã ngắt kết nối → restart advertising
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] 📡 Đang quảng bá lại BLE...");
    oldBleClientConnected = bleClientConnected;
  }
  if (bleClientConnected && !oldBleClientConnected) {
    oldBleClientConnected = bleClientConnected;
  }

  unsigned long now = millis();

  // --- Đọc cảm biến mỗi 500ms ---
  if (now - lastSensorRead > SENSOR_READ_INTERVAL) {
    lastSensorRead = now;

    float distance = readUltrasonic();
    float battery = readBatteryLevel();

    checkSafety(distance);

    // Publish qua MQTT
    publishSensorData(distance, battery);

    // Publish qua BLE (nếu có client)
    publishSensorDataBLE(distance, battery);
  }

  // --- Gửi heartbeat mỗi 5 giây ---
  if (now - lastHeartbeat > HEARTBEAT_INTERVAL) {
    lastHeartbeat = now;
    publishStatus(true);
    publishStatusBLE(true);
  }
}
