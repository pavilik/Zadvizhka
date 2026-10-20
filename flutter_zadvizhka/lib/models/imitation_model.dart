import 'package:flutter/material.dart';

/// Модель имитации по схеме:
/// Ввод(300 т/ч) → ЗАДВИЖКА 1 → ЁМКОСТЬ 2000 м³ → ЗАДВИЖКА 2 → БАК ХИМЦЕХА 800 м³
/// → РЕГУЛЯТОР АВТОМАТИЧЕСКИЙ → ВЫХОД(подпитка) 50–250 т/ч
class ImitationModel extends ChangeNotifier {
  // Ёмкость: 2000 м³
  double _hEmk = 1000.0;
  static const double vEmk = 2000.0;
  static const double hEmkMin = 0.0;
  static const double hEmkMax = 2000.0;

  // Химцех: 800 м³
  double _hChem = 400.0;
  static const double vChem = 800.0;
  static const double hChemMin = 0.0;
  static const double hChemMax = 800.0;

  // Задвижка 1 — на входе в ёмкость (0–100%)
  double _kValve1 = 0.5;

  // Задвижка 2 — между ёмкостью и химцехом (0–100%)
  double _kValve2 = 0.5;

  // Ввод: фиксированный 300 т/ч
  static const double qInMax = 300.0;

  // Подпитка (выход): автоматический регулятор, 50–250 т/ч
  double _qOut = 100.0;

  // --- Getters ---
  double get hEmk => _hEmk;
  double get hChem => _hChem;
  double get kValve1 => _kValve1;
  double get kValve2 => _kValve2;
  double get qOut => _qOut;

  // Расчёты потоков
  double get qThroughValve1 => _kValve1 * qInMax;  // через Задвижку 1
  double get qThroughValve2 => _kValve2 * qThroughValve1; // через Задвижку 2
  double get qOutReal => _qOut;                     // на выход (подпитка)

  // Баланс для Ёмкости: приток - отток
  double get emkBalance => qThroughValve1 - qThroughValve2;

  // Баланс для Химцеха: приток - отток
  double get chemBalance => qThroughValve2 - _qOut;

  void setKValve1(double v) {
    _kValve1 = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setKValve2(double v) {
    _kValve2 = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setQOut(double v) {
    _qOut = v.clamp(50.0, 250.0);
    notifyListeners();
  }

  void reset() {
    _hEmk = 1000.0;
    _hChem = 400.0;
    _kValve1 = 0.5;
    _kValve2 = 0.5;
    _qOut = 100.0;
    notifyListeners();
  }
}