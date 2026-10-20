class SimulationResult {
  final List<double> time;
  final List<double> hEmk;
  final List<double> hChem;
  final List<double> hDea;
  final List<double> qIn;
  final List<double> qZ1;
  final List<double> qPpn;
  final List<double> qPsv;
  final List<double> qNchov;
  final List<double> qReg1;
  final List<double> qReg2;
  final List<double> qOut;

  SimulationResult({
    required this.time,
    required this.hEmk,
    required this.hChem,
    required this.hDea,
    required this.qIn,
    required this.qZ1,
    required this.qPpn,
    required this.qPsv,
    required this.qNchov,
    required this.qReg1,
    required this.qReg2,
    required this.qOut,
  });
}

class SystemSimulation {
  // --- ПАРАМЕТРЫ СИСТЕМЫ ---
  static const double vEmk = 2000.0; // м3
  static const double hEmkMin = 2.5;
  static const double hEmkMax = 3.5;
  static final double sEmk = vEmk / hEmkMax; // ≈ 571 м²

  static const double vChem = 1000.0; // м3 (допущение)
  static const double hChemMin = 3.0;
  static const double hChemMax = 7.0;
  static final double sChem = vChem / hChemMax; // ≈ 143 м²

  static const double vDea = 100.0; // м3 (допущение)
  static const double hDeaMin = 1.0;
  static const double hDeaMax = 2.0;
  static final double sDea = vDea / hDeaMax; // = 50 м²

  static const double qDeaMaxT = 160.0; // т/ч — предел Рег 1
  static const double qPodpMaxT = 400.0; // т/ч — предел Рег 2

  // Время: 2 часа, шаг 10 с
  static const double dt = 10.0;
  static const double tEnd = 7200.0;

  // Пропускная способность при полном открытии (т/ч)
  static const double z1MaxT = 250.0;
  static const double psvMaxT = 200.0;

  // ППН: насос качает с фиксированной производительностью
  static const double qPpnSetT = 150.0; // т/ч

  // Рег 1: П-регулятор
  static const double kp = 80.0; // т/ч на метр ошибки

  static SimulationResult run({double kZ1 = 0.75, double kPsv = 0.70}) {
    final int n = (tEnd / dt).round();
    final List<double> time = List.generate(n, (i) => i * dt);

    final hEmk = List<double>.filled(n, 0);
    final hChem = List<double>.filled(n, 0);
    final hDea = List<double>.filled(n, 0);
    final qIn = List<double>.filled(n, 0);
    final qZ1 = List<double>.filled(n, 0);
    final qPpn = List<double>.filled(n, 0);
    final qPsv = List<double>.filled(n, 0);
    final qNchov = List<double>.filled(n, 0);
    final qReg1 = List<double>.filled(n, 0);
    final qReg2 = List<double>.filled(n, 0);
    final qOut = List<double>.filled(n, 0);

    // Начальные уровни — середина диапазона
    hEmk[0] = (hEmkMin + hEmkMax) / 2;
    hChem[0] = (hChemMin + hChemMax) / 2;
    hDea[0] = (hDeaMin + hDeaMax) / 2;

    // --- СЦЕНАРИЙ ---
    for (int i = 0; i < n; i++) {
      final t = time[i];
      if (t < 1200) {
        qIn[i] = 150.0;
      } else if (t < 3600) {
        qIn[i] = 220.0;
      } else if (t < 5400) {
        qIn[i] = 130.0;
      } else {
        qIn[i] = 180.0;
      }

      if (t < 1800) {
        qOut[i] = 120.0;
      } else if (t < 3600) {
        qOut[i] = 240.0;
      } else if (t < 5400) {
        qOut[i] = 80.0;
      } else {
        qOut[i] = 200.0;
      }
    }

    // --- МОДЕЛИРОВАНИЕ ---
    for (int i = 1; i < n; i++) {
      // 1. З1: расход пропорционален давлению (q_in) и открытию задвижки
      qZ1[i] = (kZ1 * qIn[i]).clamp(0.0, z1MaxT);

      // 2. ППН: качает фиксированно, но не больше, чем есть в ёмкости
      qPpn[i] = (hEmk[i - 1] <= hEmkMin) ? 0.0 : qPpnSetT;

      // 3. Ёмкость
      double dhEmk = (qZ1[i] - qPpn[i]) * dt / 3600.0 / sEmk;
      hEmk[i] = (hEmk[i - 1] + dhEmk).clamp(hEmkMin - 0.1, hEmkMax + 0.1);

      // 4. ПСВ: расход пропорционален открытию и напору
      qPsv[i] = (kPsv * qPpn[i]).clamp(0.0, psvMaxT);

      // 5. Рег 1 (авто): П-регулятор уровня деаэратора
      final hTarget = (hDeaMin + hDeaMax) / 2;
      final error = hTarget - hDea[i - 1];
      final qReg1Cmd = kp * error;
      qReg1[i] = qReg1Cmd.clamp(0.0, qDeaMaxT);

      // 6. НХОВ: качает столько, сколько просит Рег 1, но не больше, чем есть в химцехе
      qNchov[i] = (hChem[i - 1] <= hChemMin) ? 0.0 : qReg1[i];

      // 7. Химцех
      double dhChem = (qPsv[i] - qNchov[i]) * dt / 3600.0 / sChem;
      hChem[i] = (hChem[i - 1] + dhChem).clamp(hChemMin - 0.1, hChemMax + 0.1);

      // 8. Рег 2 (авто): отрабатывает подпитку
      qReg2[i] = qOut[i].clamp(0.0, qPodpMaxT);
      if (hDea[i - 1] <= hDeaMin && qNchov[i] < qReg2[i]) {
        qReg2[i] = qNchov[i].clamp(0.0, double.infinity);
      }

      // 9. Деаэратор
      double dhDea = (qNchov[i] - qReg2[i]) * dt / 3600.0 / sDea;
      hDea[i] = (hDea[i - 1] + dhDea).clamp(hDeaMin - 0.1, hDeaMax + 0.1);
    }

    return SimulationResult(
      time: time,
      hEmk: hEmk,
      hChem: hChem,
      hDea: hDea,
      qIn: qIn,
      qZ1: qZ1,
      qPpn: qPpn,
      qPsv: qPsv,
      qNchov: qNchov,
      qReg1: qReg1,
      qReg2: qReg2,
      qOut: qOut,
    );
  }
}