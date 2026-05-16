---
description: SMART WHEELCHAIR - VẠN VẬT KẾT NỐI - HỌC KỲ 2 - ĐỢT 2
---

# 🦽 Smart Wheelchair - Dự án Xe lăn thông minh (IoT)

**Môn học:** Vạn Vật Kết Nối (IoT)  
**Lớp:** 252INOT231780_06  
**Nhóm:** Nhóm 7  
**Đề tài:** SMART WHEELCHAIR
---

## 📖 1. Giới thiệu dự án (Mô tả ứng dụng)

Dự án "Smart Wheelchair" là một hệ thống xe lăn thông minh ứng dụng công nghệ IoT nhằm hỗ trợ việc di chuyển và theo dõi an toàn cho người sử dụng.

Hệ thống cho phép người dùng hoặc người thân điều khiển xe lăn từ xa thông qua một ứng dụng di động (phát triển bằng Flutter) với độ trễ thấp nhờ giao thức MQTT. Bên cạnh đó, xe lăn được tích hợp cảm biến siêu âm để tự động phát hiện vật cản, hỗ trợ phanh khẩn cấp để đảm bảo an toàn tối đa.

## 👥 2. Thành viên nhóm

| STT | Họ và Tên | MSSV |
|:---:|---|---|
| 1 | Võ Lê Vương | 24110391 |
| 2 | Nguyễn Đức Phát | 24110296 |
| 3 | Nông Văn Cường | 24110176 |

## 🛠 3. Công nghệ và Linh kiện sử dụng

### Phần cứng (Hardware)

* **Vi điều khiển trung tâm:** NodeMCU ESP32 (Xử lý đa luồng, tích hợp Wi-Fi).
* **Cơ cấu chấp hành:** Động cơ giảm tốc DC & Module điều khiển động cơ L298N.
* **Cảm biến:** Cảm biến siêu âm HC-SR04 (Đo khoảng cách, tránh vật cản).
* **Nguồn cấp:** [Điền loại pin bạn dùng, VD: 2 Pin 18650 3.7V].

### Phần mềm & Kết nối (Software & Connectivity)

* **Firmware:** C++ trên Arduino IDE.
* **Mobile App:** Framework Flutter (Ngôn ngữ Dart).
* **Giao thức:** MQTT (Broker: HiveMQ Cloud).
* **Định dạng dữ liệu:** JSON.

## 🏗️ 4. Kiến trúc Hệ thống

Dự án được xây dựng dựa trên **Kiến trúc IoT 4 lớp (4-Layer IoT Architecture)**, đảm bảo luồng dữ liệu hai chiều (điều khiển & giám sát) hoạt động với độ trễ thấp (low latency) và đáng tin cậy.

```mermaid
flowchart TD
    classDef layerFill fill:#f8f9fa,stroke:#adb5bd,stroke-width:2px,stroke-dasharray: 5 5
    classDef item fill:#ffffff,stroke:#495057,stroke-width:1px
    classDef highlight fill:#e7f5ff,stroke:#228be6,stroke-width:2px

    subgraph L4 ["4. Lớp Ứng dụng (Application Layer)"]
        App["📱 Smart Wheelchair App (Flutter)"]:::highlight
    end

    subgraph L3 ["3. Lớp Xử lý (Middleware Layer)"]
        Broker["☁️ HiveMQ Cloud (MQTT Broker)"]:::highlight
    end

    subgraph L2 ["2. Lớp Mạng (Network Layer)"]
        Network["📶 Wi-Fi & Giao thức MQTT"]:::item
    end

    subgraph L1 ["1. Lớp Nhận thức (Perception Layer)"]
        ESP["⚡ NodeMCU ESP32 (Edge Device)"]:::highlight
        Sensors["📡 Cảm biến (Siêu âm, Nhịp tim, Gia tốc, GPS)"]:::item
        Motors["⚙️ Động cơ (L298N, Động cơ DC)"]:::item
        
        Sensors -- "Dữ liệu" --> ESP
        ESP -- "PWM" --> Motors
    end

    %% Liên kết giữa các lớp
    App <=="Luồng Điều khiển (Commands)"==> Broker
    Broker <=="Định tuyến (Pub/Sub)"==> Network
    Network <=="Luồng Giám sát (Telemetry)"==> ESP

    class L1,L2,L3,L4 layerFill
```

> **Lưu ý:** Xem chi tiết phân tích từng lớp chức năng và luồng dữ liệu (Data Flow) tại file [`KIENTRUC.md`](./KIENTRUC.md).
