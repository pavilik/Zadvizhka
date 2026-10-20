import 'dart:math';
import 'package:flutter/foundation.dart';

class ImitationModel extends ChangeNotifier {
  // Tank levels (0.0 = empty, 1.0 = full)
  double _hEmk = 0.5;
  double _hChem = 0.5;
  double _hDea = 0.5;

  // Gate valve positions (0.0 = closed, 1.0 = fully open)
  double _kZ1 = 0.5;
  double _kPsv = 0.5;
  double _kPpn = 0.5; // pump speed

  // Inflow / outflow rates (units per tick)
  double _qIn = 0.3;
  double _qOut = 0.2;

  bool _randomMode = false;
  bool _running = false;
  int _tickCount = 0;

  final Random _rng = Random();

  // Getters
  double get hEmk => _hEmk;
  double get hChem => _hChem;
  double get hDea => _hDea;
  double get kZ1 => _kZ1;
  double get kPsv => _kPsv;
  double get kPpn => _kPpn;
  double get qIn => _qIn;
  double get qOut => _qOut;
  bool get randomMode => _randomMode;
  bool get running => _running;
  int get tickCount => _tickCount;

  // Tank limits (for visual reference)
  static const double hEmkMin = 0.1;
  static const double hEmkMax = 0.9;
  static const double hChemMin = 0.1;
  static const double hChemMax = 0.9;
  static const double hDeaMin = 0.1;
  static const double hDeaMax = 0.9;

  void setKZ1(double v) {
    _kZ1 = v;
    notifyListeners();
  }

  void setKPsv(double v) {
    _kPsv = v;
    notifyListeners();
  }

  void setKPpn(double v) {
    _kPpn = v;
    notifyListeners();
  }

  void setQIn(double v) {
    _qIn = v;
    notifyListeners();
  }

  void setQOut(double v) {
    _qOut = v;
    notifyListeners();
  }

  void setRandomMode(bool v) {
    _randomMode = v;
    notifyListeners();
  }

  void reset() {
    _hEmk = 0.5;
    _hChem = 0.5;
    _hDea = 0.5;
    _tickCount = 0;
    notifyListeners();
  }

  void start() {
    _running = true;
    notifyListeners();
  }

  void stop() {
    _running = false;
    notifyListeners();
  }

  /// Perform one simulation step.
  void tick() {
    if (!_running) return;

    _tickCount++;

    // Flow through Z1: proportional to kZ1 and qIn
    final double qZ1 = _kZ1 * _qIn;

    // Flow through PPN: pump rate
    final double qPpn = _kPpn * 0.25;

    // Flow through PSV: proportional to kPsv and qPpn
    final double qPsv = _kPsv * qPpn;

    // Chemical treatment flow
    final double qChem = qPsv * 0.8;

    // Regulator 1: sends water to deaerator based on deaerator level error
    final double deaTarget = (hDeaMin + hDeaMax) / 2;
    final double deaError = deaTarget - _hDea;
    final double qReg1 = (0.1 + deaError * 0.3).clamp(0.0, 0.3);

    // Regulator 2: outflow from deaerator to consumer
    // Random mode adds noise only to outflow (consumption)
    final double outflowNoise = _randomMode ? (_rng.nextDouble() - 0.5) * 0.3 : 0.0;
    final double qReg2 = _qOut * (0.5 + outflowNoise);

    // --- Update tank levels ---
    // Емкость: receives from Z1, sends to PPN
    _hEmk += (qZ1 - qPpn) * 0.02;
    _hEmk = _hEmk.clamp(hEmkMin - 0.05, hEmkMax + 0.05);

    // Химцех: receives from PSV, sends to chemical treatment
    _hChem += (qPsv - qChem) * 0.015;
    _hChem = _hChem.clamp(hChemMin - 0.05, hChemMax + 0.05);

    // Деаэратор: receives from Reg1, sends to Reg2
    _hDea += (qReg1 - qReg2) * 0.01;
    _hDea = _hDea.clamp(hDeaMin - 0.05, hDeaMax + 0.05);

    notifyListeners();
  }
}