# Lời trình bày gợi ý — Chủ đề 03

## Mở đầu

Hôm nay nhóm em trình bày cách xử lý tác vụ nặng trong Flutter bằng Isolate,
cụ thể là hàm compute, nhằm giữ cho giao diện phản hồi mượt mà.

## Vấn đề

Trong Flutter, mã Dart điều khiển giao diện chạy trên Main Isolate.
Nếu chúng ta thực hiện một vòng lặp tính toán lớn ngay tại đây,
Main Isolate sẽ bận xử lý và không kịp cập nhật chuyển động.
Người dùng sẽ thấy giao diện bị khựng hoặc đứng tạm thời.

Trong ứng dụng của nhóm, biểu tượng xoay và vòng tròn tải chạy liên tục.
Nhóm dùng thuật toán đếm số nguyên tố để tạo ra công việc cần nhiều CPU.
Hai nút đều chạy cùng một thuật toán với cùng giới hạn được chọn.

## Demo nút thứ nhất

Em bấm nút chạy trên Main Isolate. Mọi người quan sát biểu tượng xoay.
Trong lúc tính toán, chuyển động bị ngưng hoặc khựng. Khi phép tính xong,
giao diện mới tiếp tục cập nhật và hiển thị kết quả.

## Giải pháp và demo nút thứ hai

Để giải quyết, nhóm sử dụng compute. Trên Android hoặc Windows,
compute thực hiện hàm tính toán trong isolate riêng. Main Isolate được
giải phóng khỏi phép tính này và tiếp tục xử lý giao diện.

Em giữ nguyên giới hạn và bấm nút thứ hai. Trong thời gian chờ,
chuyển động vẫn tiếp tục. Sau khi hoàn thành, ứng dụng nhận kết quả
và cập nhật giao diện bằng setState trên Main Isolate.

Hai cách có số lượng số nguyên tố và số nguyên tố lớn nhất giống nhau.
Điểm khác biệt cần quan sát là khả năng cập nhật UI trong lúc xử lý.
compute không đảm bảo tính nhanh hơn vì còn chi phí tạo isolate và truyền dữ liệu.

## Giải thích đoạn code

Hàm countPrimes được viết ở ngoài lớp giao diện, nhận một số nguyên
và trả về dữ liệu kết quả. Ở cách thứ nhất, nhóm gọi trực tiếp hàm này.
Ở cách thứ hai, nhóm gọi await compute với hàm và giới hạn tính toán.

Chỉ thêm async hoặc await vào một hàm không tự chuyển phép tính sang
isolate khác. Trong ví dụ này, compute mới là phần thực hiện việc đó
trên nền tảng native. Worker cũng không dùng BuildContext hay setState.

## Kết thúc

Qua demo, khi gặp tác vụ cần nhiều CPU như tính toán lớn hoặc xử lý JSON dài,
chúng ta có thể dùng compute để giảm việc chặn giao diện.
Riêng Flutter Web, compute vẫn chạy trên luồng giao diện nên nhóm demo
bằng Android hoặc Windows để thể hiện đúng sự khác biệt.

## Câu hỏi thường gặp

**Vì sao không chỉ dùng Future hoặc async?**
Vì chúng hỗ trợ lập trình bất đồng bộ nhưng không tự chuyển vòng lặp CPU
sang isolate khác. Vòng lặp vẫn chặn Main Isolate nếu thực thi tại đó.

**Vì sao hai kết quả giống nhau?**
Hai nút dùng cùng hàm và cùng dữ liệu vào; chỉ thay đổi nơi thực thi.

**compute có dùng để vẽ Widget không?**
Không. Worker tính toán và trả dữ liệu; Main Isolate cập nhật Widget.

**Vì sao thời gian compute có thể dài hơn?**
Vì phải tạo isolate và truyền dữ liệu. Lợi ích ở đây là UI tiếp tục phản hồi.

**Isolate có dùng chung bộ nhớ không?**
Mỗi isolate có bộ nhớ riêng, trao đổi bằng thông điệp; không dùng mô hình
cùng tùy ý sửa một đối tượng như các thread chia sẻ bộ nhớ.
