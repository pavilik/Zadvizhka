import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Модель имитации по схеме:
/// Ввод(300 т/ч) → ЗАДВИЖКА 1 → ЁМКОСТЬ 2000 м³ → ЗАДВИЖКА 2 → БАК ХИМЦЕХА 800 м³
/// → РЕГУЛЯТОР АВТОМАТИЧЕСКИЙ → ВЫХОД(подпитка) 50–250 т/ч
///
/// Расчёт ускорения:
///   - Ёмкость 2000 м³, макс дисбаланс 300 т/ч → реальное заполнение ~6.67 ч
///   - Speed 1x  = реальное время
///   - Speed 100x ≈ 4 мин на заполнение
///   - Speed 1000x ≈ 24 с на заполнение
///   - Speed 5000x ≈ 4.8 с на заполнение
class ImitationModel extends ChangeNotifier {
  // Ёмкость: 2000 м³
  double _hEmk = 1000.0;
  static const double vEmk = 2000.0;

  // Химцех: 800 м³
  double _hChem = 400.0;
  static const double vChem = 800.0;

  // Задвижка 1 — на входе в ёмкость (0–100%), макс 300 т/ч
  double _kValve1 = 0.5;

  // Задвижка 2 — между ёмкостью и химцехом (0–100%), макс 300 т/ч
  double _kValve2 = 0.5;

  // Ввод: фиксированный 300 т/ч
  static const double qInMax = 300.0;

  // Подпитка (выход): автоматический регулятор, 50–250 т/ч
  double _qOut = 100.0;
  double _qOutTarget = 100.0;
  bool _randomQOut = true; // true = случайные возмущения, false = фиксированное значение
  static const double qOutMin = 50.0;
  static const double qOutMax = 250.0;

  // --- Управление симуляцией ---
  bool _running = false;
  double _speedSlider = 0.3; // 0..1, маппится в 1x..5000x
  Timer? _timer;
  int _tickCount = 0;
  final Random _rng = Random();

  // --- Getters ---
  double get hEmk => _hEmk;
  double get hChem => _hChem;
  double get kValve1 => _kValve1;
  double get kValve2 => _kValve2;
  double get qOut => _qOut;
  bool get randomQOut => _randomQOut;
  bool get running => _running;
  double get speedSlider => _speedSlider;
  int get tickCount => _tickCount;

  /// Симулированное время в часах
  double get simulatedTimeHours => _tickCount * 0.05 * speed / 3600.0;

  /// Форматированное время симуляции (ЧЧ:ММ)
  String get simulatedTimeFormatted {
    final hours = simulatedTimeHours.toInt();
    final minutes = ((simulatedTimeHours - hours) * 60).toInt();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Прогноз времени до аварийного уровня для Ёмкости
  /// Возвращает null если уровень безопасен или ёмкость уже пуста/полна
  String? get emkTimeToAlarm {
    final balance = emkBalance; // т/ч (положительный = наполнение, отрицательный = опорожнение)
    if (balance > 0) {
      // Наполнение — считаем время до 95% (авария)
      final remaining = vEmk * 0.95 - _hEmk;
      if (remaining > 0) {
        final hours = remaining / balance;
        return _formatDuration(hours);
      }
    } else if (balance < 0) {
      // Опорожнение — считаем время до 5% (авария)
      final remaining = _hEmk - vEmk * 0.05;
      if (remaining > 0) {
        final hours = remaining / (-balance);
        return _formatDuration(hours);
      }
    }
    return null; // Баланс 0 или уже аварийный уровень
  }

  /// Прогноз времени до аварийного уровня для Химцеха
  String? get chemTimeToAlarm {
    final balance = chemBalance;
    if (balance > 0) {
      final remaining = vChem * 0.95 - _hChem;
      if (remaining > 0) {
        final hours = remaining / balance;
        return _formatDuration(hours);
      }
    } else if (balance < 0) {
      final remaining = _hChem - vChem * 0.05;
      if (remaining > 0) {
        final hours = remaining / (-balance);
        return _formatDuration(hours);
      }
    }
    return null;
  }

  /// Форматирование длительности в ЧЧ:ММ
  static String _formatDuration(double hours) {
    if (hours < 1 / 60) {
      final minutes = (hours * 60).toInt();
      if (minutes < 1) return '<1 мин';
      return '${minutes} мин';
    }
    final h = hours.toInt();
    final m = ((hours - h) * 60).toInt();
    if (h > 0) return '${h}ч ${m}м';
    return '${m} мин';
  }

  /// Направление изменения уровня Ёмкости: 1=растёт, -1=падает, 0=стабильно
  int get emkDirection => emkBalance > 0.1 ? 1 : (emkBalance < -0.1 ? -1 : 0);

  /// Направление изменения уровня Химцеха
  int get chemDirection => chemBalance > 0.1 ? 1 : (chemBalance < -0.1 ? -1 : 0);

  /// Реальная скорость симуляции (1x..5000x)
  double get speed {
    // Нелинейное отображение: 0→1x, 0.3→10x, 0.5→100x, 0.7→500x, 1.0→5000x
    return pow(5000, _speedSlider).clamp(1.0, 5000.0).toDouble();
  }

  /// Отображаемый множитель скорости
  String get speedLabel {
    final s = speed;
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(0)}k×';
    return '${s.toStringAsFixed(0)}×';
  }

  // Расчёты потоков
  double get qThroughValve1 => _kValve1 * qInMax;       // через Задвижку 1 (0–300 т/ч)
  double get qThroughValve2 => _kValve2 * qInMax;       // через Задвижку 2 (0–300 т/ч)

  // Баланс для Ёмкости: приток - отток (т/ч)
  double get emkBalance => qThroughValve1 - qThroughValve2;

  // Баланс для Химцеха: приток - отток (т/ч)
  double get chemBalance => qThroughValve2 - _qOut;

  // Статусы для сигнализации (0=норма, 1=предупреждение, 2=авария)
  int get emkStatus {
    if (_hEmk >= vEmk * 0.95 || _hEmk <= vEmk * 0.05) return 2;
    if (_hEmk >= vEmk * 0.85 || _hEmk <= vEmk * 0.15) return 1;
    return 0;
  }

  int get chemStatus {
    if (_hChem >= vChem * 0.95 || _hChem <= vChem * 0.05) return 2;
    if (_hChem >= vChem * 0.85 || _hChem <= vChem * 0.15) return 1;
    return 0;
  }

  void setKValve1(double v) {
    _kValve1 = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setKValve2(double v) {
    _kValve2 = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setQOut(double v) {
    _qOutTarget = v.clamp(qOutMin, qOutMax);
    notifyListeners();
  }

  /// Изменить поток через Задвижку 1 напрямую (в т/ч)
  void setQValve1(double q) {
    _kValve1 = (q / qInMax).clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Изменить поток через Задвижку 2 напрямую (в т/ч)
  void setQValve2(double q) {
    _kValve2 = (q / qInMax).clamp(0.0, 1.0);
    notifyListeners();
  }

  void setRandomQOut(bool v) {
    _randomQOut = v;
    notifyListeners();
  }

  void setSpeed(double v) {
    _speedSlider = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    notifyListeners();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reset() {
    stop();
    _hEmk = 1000.0;
    _hChem = 400.0;
    _kValve1 = 0.5;
    _kValve2 = 0.5;
    _qOut = 100.0;
    _qOutTarget = 100.0;
    _randomQOut = true;
    _tickCount = 0;
    notifyListeners();
  }

  /// Один шаг симуляции (каждые 50 мс)
  void tick() {
    if (!_running) return;
    _tickCount++;

    // dt — эффективный шаг времени в часах
    // 50 мс * speed / 3600 = часы реального времени за один тик
    final double dt = 0.05 * speed / 3600.0;

    // --- Регулятор: каждые ~2 сек реального времени меняет уставку ---
    // При ускорении регулятор дёргается чаще
    final int regulatorInterval = (40 / speed.clamp(1, 5000) * 40).round().clamp(1, 100);
    if (_randomQOut && _tickCount % regulatorInterval == 0) {
      // Случайный скачок: -80..+80 т/ч
      _qOutTarget = (_qOutTarget + (_rng.nextDouble() - 0.5) * 160)
          .clamp(qOutMin, qOutMax);
    }

    // Плавное движение регулятора к цели (быстрее при ускорении)
    _qOut += (_qOutTarget - _qOut) * (0.1 * speed.clamp(1, 100)).clamp(0.01, 1.0);
    _qOut = _qOut.clamp(qOutMin, qOutMax);

    // Изменение объёма Ёмкости: balance * dt (тонны = м³)
    final double demk = emkBalance * dt;
    _hEmk = (_hEmk + demk).clamp(0.0, vEmk);

    // Изменение объёма Химцеха
    final double dchem = chemBalance * dt;
    _hChem = (_hChem + dchem).clamp(0.0, vChem);

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}