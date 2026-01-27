# PCM - Pickleball Club Management (Mobile Edition)

## Cấu trúc dự án
- **Backend**: ASP.NET Core Web API — thư mục `Backend/PcmBackend`
- **Mobile**: Ứng dụng Flutter — thư mục `Mobile/pcm_mobile`

## Yêu cầu
- .NET SDK (8.0 trở lên, dự án dùng net10.0 nếu có)
- Flutter SDK
- SQL Server (LocalDB hoặc instance đầy đủ)
- Entity Framework Core Tools: `dotnet tool install -g dotnet-ef`

---

## Cách chạy

### 1. Backend (API)

**Migration (chạy lần đầu hoặc khi có thay đổi schema):**
```bash
cd Backend/PcmBackend
dotnet ef database update
```

**Chạy API:**
```bash
cd Backend/PcmBackend
dotnet run
```

- API mặc định: **http://localhost:5000** (hoặc https://localhost:5001 nếu cấu hình HTTPS)
- Swagger: **http://localhost:5000/swagger**

### 2. Mobile (Flutter)

**Cài dependency và chạy app:**
```bash
cd Mobile/pcm_mobile
flutter pub get
flutter run
```

- Chọn thiết bị khi được hỏi (ví dụ: `d` = device, `e` = Edge/web, `c` = Chrome).
- Chạy trên **web**: `flutter run -d edge` hoặc `flutter run -d chrome`
- Chạy trên **Android**: `flutter run` (máy/emulator đã kết nối) hoặc `flutter run -d <device_id>`

---

## Base URL API

Ứng dụng Flutter dùng Base URL theo môi trường:

| Môi trường | Base URL API | Ghi chú |
|------------|--------------|--------|
| **Web** (Edge/Chrome) | `http://localhost:5000/api` | API chạy trên cùng máy |
| **Android Emulator** | `http://10.0.2.2:5000/api` | `10.0.2.2` = localhost của máy host từ trong emulator |
| **iOS Simulator** | `http://localhost:5000/api` | dùng localhost khi API trên cùng máy |
| **Máy thật (Android/iOS)** | Địa chỉ IP máy chạy API, ví dụ `http://192.168.1.x:5000/api` | Cần sửa trong `lib/services/api_base_url_io.dart` (hoặc file tương ứng) nếu deploy API trên máy khác |

**File cấu hình trong project:**
- **Android / iOS / desktop**: `Mobile/pcm_mobile/lib/services/api_base_url_io.dart` — Android dùng `10.0.2.2:5000`, còn lại dùng `localhost:5000`
- **Web**: `Mobile/pcm_mobile/lib/services/api_base_url_web.dart` — dùng `localhost:5000`

**Khi deploy backend lên server:**  
Sửa Base URL trong các file trên trỏ về domain/thể hiện thật (ví dụ `https://api-pcm.example.com/api`).

---

## Build APK (Android) và kiểm tra trên máy thật


**Build APK (release):**
```bash
cd Mobile/pcm_mobile
flutter pub get
flutter build apk --release
```

- File APK nằm tại: `build/app/outputs/flutter-apk/app-release.apk`
- Copy file này lên máy Android và cài (cần bật “Cài từ nguồn không xác định” nếu có).

**Lưu ý khi chấm bài trên máy thật:**
- Nếu Backend chạy trên máy giảng viên, cần đổi Base URL trong app thành IP máy đó (ví dụ `http://192.168.x.x:5000/api`) rồi build lại APK; hoặc
- Chạy Backend và app trên **cùng một máy** (ví dụ máy ảo/emulator trỏ về `10.0.2.2` / `localhost` như bảng trên).

---

## Tính năng chính
- **Backend**: EF Core + SQL Server, Identity (JWT), SignalR, API Auth/Members/Wallet/Bookings/Tournaments, …
- **Mobile**: Flutter + Provider, đăng nhập JWT, Home/Dashboard, Ví, Đặt sân, Giải đấu, Admin (duyệt nạp tiền, thống kê), tích hợp SignalR.

---

## Thông tin sinh viên
NguyenQuocHuy - 1771020358
