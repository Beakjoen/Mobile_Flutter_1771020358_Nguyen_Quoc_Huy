# Đối chiếu PHẦN 3 – Yêu cầu API & Mobile App

## 1. Backend API (ASP.NET Core)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| POST /api/auth/login (JWT + User Info) | ✅ | |
| GET /api/auth/me (current user + Wallet) | ✅ | |
| GET /api/members (Search, Filter, Pagination) | ✅ | |
| GET /api/members/{id}/profile | ✅ | |
| POST /api/wallet/deposit **(kèm ảnh CK)** | ⚠️ | API có `ImageUrl`; Flutter đang gửi `placeholder` – **chưa upload ảnh thật** |
| GET /api/wallet/transactions | ✅ | |
| PUT /api/admin/wallet/approve/{id} | ✅ | |
| GET /api/courts | ✅ | |
| GET /api/bookings/calendar?from=&to= | ✅ | |
| POST /api/bookings | ✅ | |
| POST /api/bookings/recurring (VIP) | ✅ | |
| POST /api/bookings/cancel/{id} | ✅ | |
| POST /api/tournaments | ✅ | |
| POST /api/tournaments/{id}/join | ✅ | |
| POST /api/tournaments/{id}/generate-schedule | ✅ | |
| POST /api/matches/{id}/result | ✅ | |
| SignalR: ReceiveNotification, UpdateCalendar, UpdateMatchScore | ✅ | |

---

## 2. Mobile – Layout chính

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| AppBar/SliverAppBar: Avatar, Tên, Số dư ví **(Live update)** | ⚠️ | Mỗi màn có AppBar riêng; Home có user card (tên, số dư). **Chưa có AppBar chung toàn app** với Avatar+Tên+Số dư live |
| BottomNav: Trang chủ, Lịch đặt sân, Giải đấu, Ví, Cá nhân | ✅ | |
| **(Admin: Quản lý)** trong nav/drawer | ⚠️ | Admin chỉ vào được qua nút trong Profile, **chưa có mục “Quản lý”** trong BottomNav/Drawer |
| Chuông thông báo + Badge số chưa đọc | ✅ | Ở Home |

---

## 3. Dashboards

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| User Dashboard: Biểu đồ rank / tiến trình | ✅ | Đã có “Tiến trình hạng thành viên” (progress) |
| **Lịch thi đấu sắp tới** (ListView/Card) | ❌ | **Thiếu** – Home chưa có block “Lịch thi đấu sắp tới” |
| Số dư ví nổi bật | ✅ | Ở Home + Ví |
| Admin Dashboard (doanh thu, booking trong tháng) | ✅ | |

---

## 4. Booking (Lịch đặt sân)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Calendar tuần/tháng, slot đỏ/xanh/trắng | ✅ | |
| Tap slot trống → BottomSheet đặt sân (Court, giờ, API) | ✅ | |
| SignalR: cập nhật lịch khi người khác đặt | ✅ | |
| Form Đặt lịch định kỳ (VIP) → recurring | ✅ | |

---

## 5. Tournament (Giải đấu)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Danh sách giải (Open, Ongoing, Finished) | ✅ | |
| Chi tiết giải | ✅ | |
| **Standings (Bảng xếp hạng)** | ❌ | **Thiếu** – chưa có tab/mục Standings trong chi tiết giải |
| **Bracket (Cây thi đấu) trực quan** | ⚠️ | Có tab “Nhánh đấu” dạng list trận; **chưa có cây đấu (CustomPainter / package bracket)** |
| Cập nhật kết quả real-time (SignalR) | ✅ | matchScoreUpdateStream |
| Nút Tham gia → POST join | ✅ | |

---

## 6. Wallet (Ví)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Số dư ví lớn, nút Nạp tiền | ✅ | |
| Form nạp: Số tiền + **upload ảnh CK (image_picker)** → POST deposit | ⚠️ | Có image_picker, **nhưng chưa gửi ảnh lên API** (đang gửi `imageUrl: 'placeholder_for_now'`) |
| Lịch sử giao dịch + **Filter: Nạp, Trừ tiền, Hoàn tiền** | ⚠️ | Có list; **chưa có filter** theo loại |
| Pull-to-refresh | ⚠️ | Có thể thêm cho list giao dịch |

---

## 7. Profile & Members

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Cá nhân: Xem Avatar, Rank, Tier | ✅ | |
| **Sửa thông tin** | ❌ | **Thiếu** (form sửa tên, SĐT, email nếu API có) |
| **Đổi mật khẩu** | ❌ | **Thiếu** (cần API đổi mật khẩu) |
| Danh sách Members (tìm kiếm) | ✅ | member_list_screen |
| **Lọc** (filter) | ❌ | **Thiếu** (vd: theo Tier, theo hạng) |
| **Xem profile member khác** | ❌ | **Thiếu** – tap member hiện `// TODO: Show member profile detail`; cần màn/route GET /members/{id}/profile |

---

## 8. Notifications

| Yêu cầu | Trạng thái | Ghi chú |
|---------|------------|---------|
| Màn danh sách thông báo | ✅ | |
| Đánh dấu đã đọc | ✅ | |
| Real-time qua SignalR + cập nhật badge | ✅ | |

---

## Tóm tắt còn thiếu / nên bổ sung

1. **Wallet – Nạp tiền:** Upload ảnh CK thật (backend cần endpoint upload file hoặc nhận base64/URL, Flutter gửi ảnh thay cho placeholder).
2. **Wallet – Lịch sử:** Filter theo loại (Nạp / Trừ tiền / Hoàn tiền) + pull-to-refresh.
3. **Layout:** (Tùy chọn) AppBar chung với Avatar + Tên + Số dư live; thêm mục “Quản lý” cho Admin trong BottomNav/Drawer.
4. **Home:** Block “Lịch thi đấu sắp tới” (gọi API matches hoặc bookings sắp tới của user).
5. **Tournament:** Tab **Standings** (bảng xếp hạng giải); Bracket dạng cây trực quan (CustomPainter hoặc package).
6. **Profile:** Sửa thông tin (nếu API hỗ trợ); Đổi mật khẩu (nếu API có).
7. **Members:** Filter (Tier, …); Tap member → màn **Profile member** gọi GET /members/{id}/profile.

File này nằm trong `Mobile/pcm_mobile/PHAN3_CHECKLIST.md` để team đối chiếu và làm tiếp.
