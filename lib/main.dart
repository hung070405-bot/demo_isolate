import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'isolate_widgets.dart';
import 'prime_worker.dart';

void main() => runApp(const IsolateDemoApp());

class IsolateDemoApp extends StatelessWidget {
  const IsolateDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolate Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff375be8)),
        scaffoldBackgroundColor: const Color(0xfff3f5fa),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  int _limit = 5000000;
  bool _busy = false;
  bool _background = false;
  String? _error;
  Map<String, int>? _mainResult;
  Map<String, int>? _computeResult;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _run(bool background) async {
    if (_busy) return;
    final limit = _limit;
    setState(() {
      _busy = true;
      _background = background;
      _error = null;
    });
    try {
      // Cho UI ve trang thai "dang xu ly" truoc khi bat dau phep tinh.
      // Delay nay KHONG dua phep tinh sang isolate khac.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final total = Stopwatch()..start();
      final result = background
          ? await compute(countPrimes, limit, debugLabel: 'prime-worker')
          : countPrimes(limit);
      total.stop();
      result['totalMs'] = total.elapsedMilliseconds;
      if (!mounted) return;
      setState(() {
        if (background) {
          _computeResult = result;
        } else {
          _mainResult = result;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Không thể tính toán: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sameInput = _mainResult != null &&
        _computeResult != null &&
        _mainResult!['limit'] == _computeResult!['limit'];
    final sameOutput = sameInput &&
        _mainResult!['count'] == _computeResult!['count'] &&
        _mainResult!['largest'] == _computeResult!['largest'];
    return Scaffold(
      appBar: AppBar(title: const Text('ISOLATE LAB · Chủ đề 03')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Tính toán nặng,\ngiao diện vẫn mượt',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'So sánh cùng một thuật toán đếm số nguyên tố trên '
                  'Main Isolate và isolate riêng qua compute.',
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn đang chạy Web: compute vẫn chạy trên luồng '
                    'giao diện. Hãy chạy Android hoặc Windows để demo isolate.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                AnimationMonitorCard(
                  animation: _animation,
                  busy: _busy,
                  background: _background,
                ),
                const SizedBox(height: 18),
                Text(
                  'Giới hạn tính toán: ${(_limit / 1000000).toStringAsFixed(0)} triệu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _limit.toDouble(),
                  min: 1000000,
                  max: 15000000,
                  divisions: 14,
                  label: '${(_limit / 1000000).round()} triệu',
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _limit = value.round()),
                ),
                const Text(
                  'Nếu chưa thấy khựng rõ, tăng giới hạn rồi chạy lại. '
                  'Hai nút luôn sử dụng cùng giới hạn đang chọn.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffb43e39),
                      ),
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('1. Chạy trên Main Isolate'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run(true),
                      icon: const Icon(Icons.bolt),
                      label: const Text('2. Chạy bằng compute'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ResultCard(
                  title: '01 · Main Isolate',
                  result: _mainResult,
                  color: const Color(0xffb43e39),
                ),
                ResultCard(
                  title: '02 · compute',
                  result: _computeResult,
                  color: const Color(0xff375be8),
                ),
                if (sameInput)
                  Text(
                    sameOutput
                        ? '✓ Hai cách cho kết quả giống nhau với cùng dữ liệu đầu vào.'
                        : 'Kết quả khác nhau — cần kiểm tra lại.',
                    style: TextStyle(
                      color: sameOutput ? Colors.green.shade800 : Colors.red,
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Mục tiêu của compute là giữ UI phản hồi. Tổng thời gian '
                  'có thể dài hơn vì cần tạo isolate và truyền dữ liệu.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
