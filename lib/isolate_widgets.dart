import 'package:flutter/material.dart';

/// ============================================================================
/// MODULE: GIAO DIỆN QUAN SÁT HIỆU NĂNG & KẾT QUẢ ĐO LƯỜNG ISOLATE
/// ============================================================================
/// Minh họa trực quan hiện tượng nghẽn giao diện (UI Jank / Freeze):
/// - Trên màn hình 60Hz, mỗi khung hình (frame) cần được dựng xong trong ~16.7ms.
/// - Nếu chạy vòng lặp nặng trực tiếp trên Main Isolate, Event Loop bị chặn khiến
///   `RotationTransition` và `CircularProgressIndicator` bị đứng hình hoàn toàn.
/// - Khi tách sang Isolate riêng bằng `compute()`, Main Isolate vẫn rảnh để vẽ
///   animation mượt mà ở 60/120 FPS trong suốt thời gian chờ kết quả.
/// ============================================================================
class AnimationMonitorCard extends StatelessWidget {
  const AnimationMonitorCard({
    required this.animation,
    required this.busy,
    required this.background,
    super.key,
  });

  final Animation<double> animation;
  final bool busy;
  final bool background;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Biểu tượng xoay liên tục để kiểm tra Main Isolate có bị chặn hay không
            RotationTransition(
              turns: animation,
              child: const Icon(
                Icons.autorenew_rounded,
                size: 82,
                color: Color(0xff375be8),
              ),
            ),
            const SizedBox(height: 14),
            // Vòng xoay tiến trình chuẩn của Material 3
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(
              busy
                  ? (background
                      ? 'Đang tính bằng compute…'
                      : 'Đang tính trên Main Isolate…')
                  : 'Hãy quan sát chuyển động khi bấm từng nút.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// Thẻ hiển thị kết quả đếm số nguyên tố và thời gian thực thi:
/// - `totalMs`: Tổng thời gian từ lúc gọi đến khi nhận kết quả (bao gồm chi phí
///   khởi tạo Isolate và truyền thông điệp nếu dùng `compute`).
/// - `workerMs`: Thời gian thuần túy CPU thực thi thuật toán `countPrimes`.
/// ============================================================================
class ResultCard extends StatelessWidget {
  const ResultCard({
    required this.title,
    required this.result,
    required this.color,
    super.key,
  });

  final String title;
  final Map<String, int>? result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final data = result;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            if (data == null)
              const Text('Chưa chạy phép tính.')
            else ...[
              Text('Phạm vi: 2 → ${data['limit']}'),
              Text('Số lượng số nguyên tố: ${data['count']}'),
              Text('Số nguyên tố lớn nhất: ${data['largest']}'),
              const SizedBox(height: 8),
              Text(
                'Tổng thời gian: ${data['totalMs']} ms',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Riêng phép tính: ${data['workerMs']} ms'),
            ],
          ],
        ),
      ),
    );
  }
}
