# Chủ đề 03 — Xử lý tác vụ nặng với Isolate (compute)

Ứng dụng Flutter minh họa nghẽn giao diện khi tính toán trên Main Isolate,
và cách dùng compute để chuyển cùng phép tính sang isolate riêng.

## 1. Chạy trên VS Code / Windows

Yêu cầu: đã cài Flutter SDK, extension Flutter/Dart trong VS Code.
Nếu chạy Android: cài Android SDK, có máy ảo hoặc điện thoại bật USB debugging.
Nếu chạy Windows: cần Visual Studio với workload Desktop development with C++
(Visual Studio là bộ công cụ build, khác VS Code là trình soạn thảo).

1. Giải nén rồi mở đúng thư mục `isolate_demo` bằng VS Code.
2. Chạy `setup_windows.bat`, hoặc mở Terminal trong thư mục và chạy:

```powershell
flutter doctor
flutter create --platforms=android,windows --project-name isolate_demo .
# Nếu Flutter vừa sinh file test/widget_test.dart mẫu, xóa file đó.
# Giữ nguyên test/prime_worker_test.dart của dự án.
flutter pub get
flutter devices
flutter run -d <DEVICE_ID>
```

Thay `<DEVICE_ID>` bằng ID thật từ `flutter devices`, không giữ dấu < >.
Ví dụ chạy desktop: `flutter run -d windows`.
Hoặc chọn thiết bị Android ở thanh dưới VS Code rồi nhấn F5.
Nếu máy ảo chưa bật: mở Device Manager của Android Studio và khởi động máy ảo.

**Bộ mã nguồn chưa chứa thư mục runner Android/Windows.** Lệnh `flutter create`
ở trên tạo chúng bằng đúng Flutter SDK đang cài trên máy bạn; không dùng
`--overwrite` để tránh ghi đè mã nguồn có sẵn. Script tự xóa test bộ đếm mẫu.

Không chọn Chrome/Edge: trên Flutter Web, compute không tạo isolate riêng.
Ứng dụng có thông báo riêng khi phát hiện đang chạy Web.

## 2. Kịch bản demo khoảng 2–3 phút

1. Mở app, chỉ vào biểu tượng xoay và vòng CircularProgressIndicator.
2. Giữ giới hạn 5 triệu, bấm **1. Chạy trên Main Isolate**.
3. Quan sát chuyển động bị đứng/khựng trong thời gian tính toán, rồi chạy tiếp.
4. Giữ nguyên giới hạn, bấm **2. Chạy bằng compute**.
5. Quan sát animation vẫn cập nhật trong khi chờ kết quả.
6. Chỉ vào số lượng số nguyên tố và số lớn nhất: hai cách phải giống nhau.
7. Nếu quá nhanh, tăng giới hạn rồi chạy lại cả hai nút với cùng giá trị.

Thời gian phụ thuộc thiết bị và chế độ build. Không cam kết số giây cố định.
Có thể dùng `flutter run --profile -d <DEVICE_ID>` trên thiết bị hỗ trợ
để quan sát hiệu năng gần thực tế hơn. Không dùng debug timing để kết luận tốc độ sản phẩm.

## 3. Đọc mã nguồn theo thứ tự

- `lib/prime_worker.dart`: hàm `countPrimes` dùng thử chia để đếm nguyên tố.
- `lib/main.dart`: UI, animation, nút gọi trực tiếp và nút gọi compute.
- `test/prime_worker_test.dart`: kiểm tra mốc nguyên tố và tính nhất quán hai cách.

Điểm khác biệt chính trong hàm `_run`:

```dart
final result = background
    ? await compute(countPrimes, limit, debugLabel: 'prime-worker')
    : countPrimes(limit);
```

Hai nút gọi đúng cùng một hàm, cùng dữ liệu vào. Trong demo này, main thread
được gọi chính xác hơn là Main Isolate: nơi chạy mã Dart điều khiển UI.

## 4. Giải thích dễ hiểu

**UI jank / freeze:** Khi Main Isolate bận vòng lặp dài, nó chưa thể xử lý
các cập nhật giao diện và tương tác kịp thời. Animation vì vậy bị khựng.
Với màn hình 60 Hz, mỗi khung hình có khoảng 16,7 ms; ở 120 Hz là khoảng 8,3 ms.

**Isolate:** Môi trường thực thi Dart có bộ nhớ riêng. Các isolate không tùy ý
cùng sửa một đối tượng; dữ liệu được trao đổi qua cơ chế thông điệp.

**compute:** Nhận một hàm và dữ liệu đầu vào, thực thi hàm đó trên isolate
riêng trên nền tảng native rồi trả về Future chứa kết quả. Trong lúc `await`,
Main Isolate có thể tiếp tục xử lý UI.

**async/await:** Không tự biến vòng lặp CPU thành công việc chạy song song.
Chỉ thêm `async`, `Future(() => countPrimes(limit))` hay `Future.delayed`
vẫn có thể làm UI khựng khi hàm tính toán chạy trên Main Isolate.

**Callback:** Dùng hàm top-level `countPrimes`, tránh bắt kèm BuildContext
hay State qua closure. Callback, dữ liệu vào và kết quả phải truyền được
giữa isolate. Không cập nhật Widget/setState bên trong worker.

**Thời gian:** `workerMs` đo riêng thuật toán, `totalMs` đo từ lúc gọi
đến khi có kết quả (bao gồm tạo isolate và truyền dữ liệu nếu dùng compute).
100 ms nhường UI trước khi tính không được cộng vào hai số đo này.
compute có thể tổng thời gian lâu hơn; mục tiêu demo là tránh chặn UI.

**Giới hạn:** Khi đang tính, hai nút và thanh trượt bị khóa để không chạy
chồng nhiều phép tính. Demo không có nút hủy. Không hiển thị phần trăm tiến độ
vì compute chỉ trả về kết quả cuối. Với worker lâu dài cần cập nhật tiến độ,
có thể cân nhắc Isolate.spawn và SendPort/ReceivePort ở phần mở rộng.

## 5. Kiểm tra trên máy có Flutter

```powershell
dart format lib test
flutter analyze
flutter test test/prime_worker_test.dart
```

Mốc đối chiếu: có 25 số nguyên tố không vượt 100 (lớn nhất 97);
có 9.592 số nguyên tố không vượt 100.000.

Kiểm tra bằng mắt trên Android/Windows là bước bắt buộc để xác nhận hiệu ứng
khựng và mượt. Test thuật toán không chứng minh hiệu năng giao diện.

Tình trạng bàn giao: mã nguồn đã được kiểm tra cấu trúc, thuật toán được
đối chiếu bằng phép sàng độc lập. Môi trường tạo bộ mã nguồn không có Flutter
SDK nên chưa chạy được flutter analyze, flutter test hoặc build APK.

## 6. Lỗi thường gặp

- `flutter is not recognized`: thêm thư mục Flutter SDK/bin vào PATH, mở lại VS Code.
- `No devices`: bật máy ảo hoặc kết nối điện thoại và chấp nhận USB debugging.
- Lỗi Android toolchain/license: xem `flutter doctor -v`; chạy
  `flutter doctor --android-licenses` khi doctor yêu cầu.
- Không tìm thấy thư mục android/windows: chạy bước flutter create ở mục 1.
- Hai nút đều đứng khi chạy Chrome: chuyển sang Android hoặc Windows.
- Test MyApp không tồn tại: xóa test/widget_test.dart mẫu do flutter create sinh.

## 7. Tài liệu chính thức

- https://api.flutter.dev/flutter/foundation/compute.html
- https://docs.flutter.dev/perf/isolates
- https://dart.dev/language/concurrency
