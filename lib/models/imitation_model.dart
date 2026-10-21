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

  // Потоки в т/ч (а не проценты!)
  double _qValve1 = 150.0; // через Задвижку 1 (0–300 т/ч)
  double _qValve2 = 150.0; // через Задвижку 2 (0–300 т/ч)

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
  double get qValve1 => _qValve1;
  double get qValve2 => _qValve2;
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
  String? get emkTimeToAlarm {
    final balance = emkBalance;
    if (balance > 0) {
      final remaining = vEmk * 0.95 - _hEmk;
      if (remaining > 0) {
        final hours = remaining / balance;
        return _formatDuration(hours);
      }
    } else if (balance < 0) {
      final remaining = _hEmk - vEmk * 0.05;
      if (remaining > 0) {
        final hours = remaining / (-balance);
        return _formatDuration(hours);
      }
    }
    return null;
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

  /// Направление изменения уровня Ёмкости
  int get emkDirection => emkBalance > 0.1 ? 1 : (emkBalance < -0.1 ? -1 : 0);

  /// Направление изменения уровня Химцеха
  int get chemDirection => chemBalance > 0.1 ? 1 : (chemBalance < -0.1 ? -1 : 0);

  /// Реальная скорость симуляции (1x..5000x)
  double get speed {
    return pow(5000, _speedSlider).clamp(1.0, 5000.0).toDouble();
  }

  /// Отображаемый множитель скорости
  String get speedLabel {
    final s = speed;
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(0)}k×';
    return '${s.toStringAsFixed(0)}×';
  }

  // Процент открытия задвижек (для отображения)
  double get kValve1 => _qValve1 / qInMax;
  double get kValve2 => _qValve2 / qInMax;

  // Баланс для Ёмкости: приток - отток (т/ч)
  double get emkBalance => _qValve1 - _qValve2;

  // Баланс для Химцеха: приток - отток (т/ч)
  double get chemBalance => _qValve2 - _qOut;

  // Статусы для сигнализации
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

  // Изменить поток через Задвижку 1 (в т/ч, шаг 1)
  void setQValve1(double q) {
    _qValve1 = q.clamp(0.0, qInMax);
    notifyListeners();
  }

  // Изменить поток через Задвижку 2 (в т/ч, шаг 1)
  void setQValve2(double q) {
    _qValve2 = q.clamp(0.0, qInMax);
    notifyListeners();
  }

  // Изменить процент открытия Задвижки 1 (0..1) — для верхних слайдеров
  void setKValve1(double k) {
    _qValve1 = (k * qInMax).clamp(0.0, qInMax);
    notifyListeners();
  }

  // Изменить процент открытия Задвижки 2 (0..1) — для верхних слайдеров
  void setKValve2(double k) {
    _qValve2 = (k * qInMax).clamp(0.0, qInMax);
    notifyListeners();
  }

  // Изменить подпитку (в т/ч, шаг 1)
  void setQOut(double v) {
    _qOut = v.clamp(qOutMin, qOutMax);
    _qOutTarget = _qOut;
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
    _qValve1 = 150.0;
    _qValve2 = 150.0;
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
    final double dt = 0.05 * speed / 3600.0;

    // --- Регулятор: каждые ~2 сек реального времени меняет уставку ---
    final int regulatorInterval = (40 / speed.clamp(1, 5000) * 40).round().clamp(1, 100);
    if (_randomQOut && _tickCount % regulatorInterval == 0) {
      _qOutTarget = (_qOutTarget + (_rng.nextDouble() - 0.5) * 160)
          .clamp(qOutMin, qOutMax);
    }

    // Плавное движение регулятора к цели
    _qOut += (_qOutTarget - _qOut) * (0.1 * speed.clamp(1, 100)).clamp(0.01, 1.0);
    _qOut = _qOut.clamp(qOutMin, qOutMax);

    // Изменение объёма Ёмкости
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
