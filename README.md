# PCM - Pickleball Club Management (Mobile Edition)

## Link sản phẩm online (đã deploy)

- **Backend (Swagger):** https://nguyenquochuy.online/swagger  
- **Backend (API):** https://nguyenquochuy.online/api  

**App Mobile (Android):** Chưa có link tải APK. Clone repo này, cài Flutter + Android SDK, rồi build APK theo hướng dẫn bên dưới (phần **Build APK**). App trong repo đã cấu hình sẵn Base URL trỏ về backend tại **https://nguyenquochuy.online**.

---

## Cấu trúc dự án
- **Backend**: ASP.NET Core Web API — thư mục `Backend/PcmBackend`
- **Mobile**: Ứng dụng Flutter — thư mục `Mobile/pcm_mobile`

## Yêu cầu
- .NET SDK 8.0 (cho Backend)
- Flutter SDK (cho Mobile)
- SQL Server (LocalDB hoặc instance đầy đủ — khi chạy Backend local)
- Entity Framework Core Tools: `dotnet tool install -g dotnet-ef` (khi chạy Backend local)
- Android SDK (khi build APK — cài qua Android Studio, set ANDROID_HOME)

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

**Bản trong repo (mặc định):** App Flutter đã cấu **Base URL = https://nguyenquochuy.online** (file `Mobile/pcm_mobile/lib/services/api_base_url_io.dart`). Clone và build APK là dùng được với backend đã deploy.

| Môi trường | Base URL | Ghi chú |
|------------|----------|--------|
| **APK / máy thật (mặc định)** | `https://nguyenquochuy.online/api` | Backend đã deploy, dùng trực tiếp |
| **Web** (Edge/Chrome) | `http://localhost:5000/api` | File `api_base_url_web.dart` — khi chạy API local |
| **Chạy local khác** | Sửa `api_base_url_io.dart` | Ví dụ trỏ về `http://10.0.2.2:5000/api` (emulator) hoặc IP máy chạy API |

**File cấu hình:** `Mobile/pcm_mobile/lib/services/api_base_url_io.dart` (API + SignalR hub).

---

## Build APK (Android)

App trong repo đã trỏ về backend **https://nguyenquochuy.online**. Chỉ cần clone, cài Flutter + Android SDK, rồi build APK.

**Yêu cầu:** Flutter SDK, Android SDK (cài qua [Android Studio](https://developer.android.com/studio)). Set biến môi trường **ANDROID_HOME** trỏ tới thư mục Android SDK.

**Build APK:**
```bash
cd Mobile/pcm_mobile
flutter pub get
flutter build apk
```

- File APK: `Mobile/pcm_mobile/build/app/outputs/flutter-apk/app-release.apk`
- Copy file này sang máy Android và cài (bật “Cài từ nguồn không xác định” nếu thiết bị yêu cầu).

**Chạy trên emulator / máy nối USB:** `flutter run` (chọn thiết bị khi được hỏi).

---

## Tính năng chính
- **Backend**: EF Core + SQL Server, Identity (JWT), SignalR, API Auth/Members/Wallet/Bookings/Tournaments, …
- **Mobile**: Flutter + Provider, đăng nhập JWT, Home/Dashboard, Ví, Đặt sân, Giải đấu, Admin (duyệt nạp tiền, thống kê), tích hợp SignalR.

---

## Thông tin sinh viên
NguyenQuocHuy - 1771020358
