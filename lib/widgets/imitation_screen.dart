import 'package:flutter/material.dart';
import '../models/imitation_model.dart';

class ImitationScreen extends StatefulWidget {
  const ImitationScreen({super.key});

  @override
  State<ImitationScreen> createState() => _ImitationScreenState();
}

class _ImitationScreenState extends State<ImitationScreen> {
  final ImitationModel _model = ImitationModel();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Title
              const Text(
                'Имитация системы водоподготовки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Управляйте задвижками, наблюдайте динамику уровней',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),

              // --- Control buttons + speed ---
              _buildControls(),
              const SizedBox(height: 12),

              // --- Flow diagram ---
              _buildFlowDiagram(),
              const SizedBox(height: 12),

              // --- Two tanks side by side ---
              Row(
                children: [
                  Expanded(
                    child: _buildTank(
                      'Ёмкость\n2000 м³',
                      _model.hEmk,
                      ImitationModel.vEmk,
                      _model.emkStatus,
                      _model.emkDirection,
                      _model.emkTimeToAlarm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTank(
                      'Бак химцеха\n800 м³',
                      _model.hChem,
                      ImitationModel.vChem,
                      _model.chemStatus,
                      _model.chemDirection,
                      _model.chemTimeToAlarm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Vertical sliders ---
              _buildVerticalSliders(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctrlButton(
                icon: Icons.play_arrow,
                label: 'Пуск',
                color: Colors.green,
                onPressed: _model.running ? null : _model.start,
              ),
              const SizedBox(width: 8),
              _ctrlButton(
                icon: Icons.stop,
                label: 'Стоп',
                color: Colors.red,
                onPressed: _model.running ? _model.stop : null,
              ),
              const SizedBox(width: 8),
              _ctrlButton(
                icon: Icons.refresh,
                label: 'Сброс',
                color: Colors.orange,
                onPressed: _model.reset,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Speed slider (логарифмический: 1x..5000x)
          Row(
            children: [
              const Icon(Icons.speed, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              const Text('Ускорение:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.amber.withOpacity(0.15),
                    thumbColor: Colors.amber,
                    overlayColor: Colors.amber.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: _model.speedSlider,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: _model.speedLabel,
                    onChanged: _model.setSpeed,
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  _model.speedLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          // Симулированное время
          if (_model.running)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Время: ${_model.simulatedTimeFormatted}',
                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ctrlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.3),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.withOpacity(0.15),
        disabledForegroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }

  Widget _buildFlowDiagram() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Row 1: Ввод → З1 → Ёмкость
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _flowNode('Ввод', '${ImitationModel.qInMax} т/ч', Colors.blue),
              _arrow(),
              _flowNode('Задвижка 1', '${_model.qThroughValve1.toStringAsFixed(0)} т/ч', Colors.cyan),
              _arrow(),
              _flowNode('Ёмкость', '${_model.hEmk.toStringAsFixed(0)} м³', Colors.blue),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Ёмкость → Задвижка 2 → Химцех
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _flowNode('Задвижка 2', '${_model.qThroughValve2.toStringAsFixed(0)} т/ч', Colors.teal),
              _arrow(),
              _flowNode('Бак химцеха', '${_model.hChem.toStringAsFixed(0)} м³', Colors.orange),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: Химцех → Регулятор → Выход
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 100),
              _flowNodeRegulator('Регулятор', '${_model.qOut.toStringAsFixed(0)} т/ч'),
              _arrow(),
              _flowNode('Выход (подпитка)', '${_model.qOut.toStringAsFixed(0)} т/ч', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowNode(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }

  /// Зелёный треугольник ▲ для автоматического регулятора
  Widget _flowNodeRegulator(String label, String value) {
    return Column(
      children: [
        const Icon(Icons.play_arrow, size: 24, color: Colors.green),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 10, color: Colors.green),
        ),
      ],
    );
  }

  Widget _arrow() => const Icon(Icons.arrow_forward, size: 14, color: Colors.white38);

  /// Цвет статуса: 0=синий(норма), 1=жёлтый(внимание), 2=красный(авария)
  Color _statusColor(int status) {
    switch (status) {
      case 2: return Colors.red;
      case 1: return Colors.amber;
      default: return Colors.blue;
    }
  }

  Widget _buildTank(String name, double level, double maxVolume, int status, int direction, String? timeToAlarm) {
    final double percent = (level / maxVolume * 100).clamp(0.0, 100.0);
    final Color color = _statusColor(status);

    // Стрелка направления
    Widget directionIcon;
    Color? directionColor;
    if (direction > 0) {
      directionIcon = const Icon(Icons.arrow_upward, size: 16, color: Colors.green);
      directionColor = Colors.green;
    } else if (direction < 0) {
      directionIcon = const Icon(Icons.arrow_downward, size: 16, color: Colors.orange);
      directionColor = Colors.orange;
    } else {
      directionIcon = const Icon(Icons.arrow_right, size: 16, color: Colors.grey);
      directionColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: status == 2 ? 2.5 : (status == 1 ? 2.0 : 1.0),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 4),
              directionIcon,
            ],
          ),
          const SizedBox(height: 4),
          // Tank with colored water
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TankPainter(level: percent / 100.0, statusColor: color),
            ),
          ),
          const SizedBox(height: 6),
          // Level info
          Text(
            '${level.toStringAsFixed(0)} м³',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          // Прогноз времени до аварии
          if (timeToAlarm != null && status < 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Авария: $timeToAlarm',
                      style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          // Статус indicator
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusDot(0, 'Норм', status),
              const SizedBox(width: 6),
              _statusDot(1, 'Вним', status),
              const SizedBox(width: 6),
              _statusDot(2, 'Авар', status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDot(int level, String label, int current) {
    final bool active = current >= level;
    final Color c = _statusColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: active ? c.withOpacity(0.6) : Colors.white12,
          width: active ? 1 : 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: active ? c : Colors.grey[600],
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildVerticalSliders() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'Регулировка задвижек',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            'Задвижка 1 — приток в ёмкость (300×k т/ч)\n'
            'Задвижка 2 — отток из ёмкости (300×k т/ч)\n'
            'Подпитка — расход из химцеха (50–250 т/ч)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D5C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  'Ёмкость: приток − отток = 300×(k1−k2) т/ч',
                  style: TextStyle(fontSize: 8, color: Colors.cyan[300]),
                ),
                Text(
                  'Химцех: приток − расход = 300×k2 − Qпит т/ч',
                  style: TextStyle(fontSize: 8, color: Colors.teal[300]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _verticalSlider(
                label: 'Задвижка 1',
                subtitle: 'приток в ёмкость',
                hint: 'Больше → ёмкость наполняется быстрее',
                value: _model.kValve1,
                color: Colors.cyan,
                onChanged: _model.setKValve1,
                valueDisplay: '${_model.qThroughValve1.toStringAsFixed(0)} т/ч',
              ),
              _verticalSlider(
                label: 'Задвижка 2',
                subtitle: 'отток из ёмкости',
                hint: 'Больше → ёмкость опорожняется в химцех',
                value: _model.kValve2,
                color: Colors.teal,
                onChanged: _model.setKValve2,
                valueDisplay: '${_model.qThroughValve2.toStringAsFixed(0)} т/ч',
              ),
              _verticalSlider(
                label: 'Подпитка',
                subtitle: '50–250 т/ч',
                hint: 'Автоматический регулятор (возмущения)',
                value: (_model.qOut - ImitationModel.qOutMin) /
                    (ImitationModel.qOutMax - ImitationModel.qOutMin),
                color: Colors.red,
                onChanged: (v) => _model.setQOut(
                    ImitationModel.qOutMin + v * (ImitationModel.qOutMax - ImitationModel.qOutMin)),
                valueDisplay: '${_model.qOut.toStringAsFixed(0)} т/ч',
                showRandomToggle: true,
                isRandom: _model.randomQOut,
                onRandomToggle: _model.setRandomQOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalSlider({
    required String label,
    required String subtitle,
    required String hint,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
    required String valueDisplay,
    bool showRandomToggle = false,
    bool isRandom = false,
    ValueChanged<bool>? onRandomToggle,
  }) {
    return Tooltip(
      message: hint,
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D5C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      textStyle: TextStyle(fontSize: 10, color: Colors.grey[300], height: 1.4),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            valueDisplay,
            style: TextStyle(fontSize: 10, color: color),
          ),
          // Toggle для случайного/фиксированного режима
          if (showRandomToggle)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRandom ? 'Случайно' : 'Фикс',
                    style: TextStyle(fontSize: 7, color: isRandom ? Colors.green : Colors.blue),
                  ),
                  Switch(
                    value: isRandom,
                    onChanged: onRandomToggle,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.blue,
                    inactiveTrackColor: Colors.blue.withOpacity(0.3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          // Up arrow
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            color: color,
            onPressed: () => onChanged((value + 0.05).clamp(0.0, 1.0)),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          // Vertical slider
          SizedBox(
            height: 100,
            child: RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: 80,
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: color,
                  inactiveColor: color.withOpacity(0.2),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          // Down arrow
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            color: color,
            onPressed: () => onChanged((value - 0.05).clamp(0.0, 1.0)),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          // Percentage
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }

}

class _TankPainter extends CustomPainter {
  final double level;
  final Color statusColor;

  _TankPainter({required this.level, required this.statusColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(6),
    );

    // Tank border
    final borderPaint = Paint()
      ..color = statusColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, borderPaint);

    // Draw blue water
    if (level > 0) {
      final waterRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          4,
          size.height - 4 - (size.height - 8) * level,
          size.width - 8,
          (size.height - 8) * level,
        ),
        const Radius.circular(3),
      );
      final waterPaint = Paint()
        ..color = const Color(0xFF2196F3).withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(waterRect, waterPaint);

      // Water surface line
      final surfacePaint = Paint()
        ..color = const Color(0xFF64B5F6).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final surfaceY = size.height - 4 - (size.height - 8) * level;
      canvas.drawLine(
        Offset(6, surfaceY),
        Offset(size.width - 6, surfaceY),
        surfacePaint,
      );
    }

    // Границы: 15% и 85% линии
    final double y15 = size.height - 4 - (size.height - 8) * 0.15;
    final double y85 = size.height - 4 - (size.height - 8) * 0.85;
    final dashPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(6, y15), Offset(size.width - 6, y15), dashPaint);
    canvas.drawLine(Offset(6, y85), Offset(size.width - 6, y85), dashPaint);
  }

  @override
  bool shouldRepaint(covariant _TankPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.statusColor != statusColor;
  }
}
