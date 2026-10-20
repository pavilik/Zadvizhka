import 'package:flutter/material.dart';

/// Модель имитации — Ёмкость (2000 м³) → Химцех (800 м³)
/// Без деаэратора, без таймера — мгновенная визуализация при движении ручек.
class ImitationModel extends ChangeNotifier {
  // Ёмкость: 2000 м³, диапазон 0–2000
  double _hEmk = 1000.0;
  static const double vEmk = 2000.0;
  static const double hEmkMin = 0.0;
  static const double hEmkMax = 2000.0;

  // Химцех: 800 м³, диапазон 0–800
  double _hChem = 400.0;
  static const double vChem = 800.0;
  static const double hChemMin = 0.0;
  static const double hChemMax = 800.0;

  // Задвижки
  double _kZ1 = 0.5;  // З1 — в ёмкость
  double _kPsv = 0.5; // ПСВ — в химцех

  // Ввод: фиксированный 300 т/ч
  static const double qInMax = 300.0;

  // Подпитка (выход): 50–250 т/ч
  double _qOut = 100.0;

  // --- Getters ---
  double get hEmk => _hEmk;
  double get hChem => _hChem;
  double get kZ1 => _kZ1;
  double get kPsv => _kPsv;
  double get qOut => _qOut;

  // Расчёты
  double get qZ1 => _kZ1 * qInMax;          // через З1
  double get qPpn => qZ1 * 0.6;              // ППН качает 60% от З1
  double get qPsv => _kPsv * qPpn;           // через ПСВ
  double get qChem => qPsv * 0.85;           // в химцех
  double get qOutReal => _qOut;              // на выход

  void setKZ1(double v) {
    _kZ1 = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setKPsv(double v) {
    _kPsv = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setQOut(double v) {
    _qOut = v.clamp(50.0, 250.0);
    notifyListeners();
  }

  void reset() {
    _hEmk = 1000.0;
    _hChem = 400.0;
    _kZ1 = 0.5;
    _kPsv = 0.5;
    _qOut = 100.0;
    notifyListeners();
  }
}
