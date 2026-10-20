class SimulationResult {
  final List<double> time;
  final List<double> hEmk;    // м³
  final List<double> hChem;   // м³
  final List<double> qIn;
  final List<double> qValve1; // через Задвижку 1
  final List<double> qValve2; // через Задвижку 2
  final List<double> qOut;    // подпитка (задаётся сценарием)

  SimulationResult({
    required this.time,
    required this.hEmk,
    required this.hChem,
    required this.qIn,
    required this.qValve1,
    required this.qValve2,
    required this.qOut,
  });
}

/// Расчётная симуляция по схеме:
/// Ввод(300 т/ч) → ЗАДВИЖКА 1 → ЁМКОСТЬ 2000 м³ → ЗАДВИЖКА 2
/// → БАК ХИМЦЕХА 800 м³ → РЕГУЛЯТОР АВТОМАТИЧЕСКИЙ → ВЫХОД(подпитка) 50–250 т/ч
class SystemSimulation {
  // --- ПАРАМЕТРЫ СИСТЕМЫ ---
  static const double vEmk = 2000.0; // м³
  static const double vChem = 800.0; // м³

  // Рабочий диапазон: 10–90% от объёма
  static const double hEmkMin = 200.0;   // м³ (10%)
  static const double hEmkMax = 1800.0;  // м³ (90%)
  static const double hChemMin = 80.0;   // м³ (10%)
  static const double hChemMax = 720.0;  // м³ (90%)

  // Время: 2 часа, шаг 10 с
  static const double dt = 10.0;
  static const double tEnd = 7200.0;

  // Пропускная способность задвижек при полном открытии (т/ч)
  static const double valveMaxT = 300.0;

  // Подпитка: 50–250 т/ч
  static const double qOutMin = 50.0;
  static const double qOutMax = 250.0;

  static SimulationResult run({double kValve1 = 0.75, double kValve2 = 0.70}) {
    final int n = (tEnd / dt).round();
    final List<double> time = List.generate(n, (i) => i * dt);

    final hEmk = List<double>.filled(n, 0);
    final hChem = List<double>.filled(n, 0);
    final qIn = List<double>.filled(n, 0);
    final qValve1 = List<double>.filled(n, 0);
    final qValve2 = List<double>.filled(n, 0);
    final qOut = List<double>.filled(n, 0);

    // Начальные уровни — середина диапазона
    hEmk[0] = vEmk / 2;
    hChem[0] = vChem / 2;

    // --- СЦЕНАРИЙ (ввод и потребление меняются каждые 20 мин) ---
    for (int i = 0; i < n; i++) {
      final t = time[i];
      if (t < 1200) {
        qIn[i] = 300.0;
      } else if (t < 2400) {
        qIn[i] = 200.0;
      } else if (t < 3600) {
        qIn[i] = 300.0;
      } else if (t < 4800) {
        qIn[i] = 150.0;
      } else {
        qIn[i] = 300.0;
      }

      if (t < 1800) {
        qOut[i] = 100.0;
      } else if (t < 3600) {
        qOut[i] = 200.0;
      } else if (t < 5400) {
        qOut[i] = 80.0;
      } else {
        qOut[i] = 150.0;
      }
    }

    // --- МОДЕЛИРОВАНИЕ ---
    for (int i = 1; i < n; i++) {
      // 1. Задвижка 1: пропускает пропорционально открытию
      qValve1[i] = (kValve1 * qIn[i]).clamp(0.0, valveMaxT);

      // 2. Ёмкость: приток - отток через Задвижку 2
      qValve2[i] = (kValve2 * qIn[i]).clamp(0.0, valveMaxT);
      // Ограничение: не можем вылить больше, чем есть в ёмкости
      if (hEmk[i - 1] <= 0 && qValve2[i] > qValve1[i]) {
        qValve2[i] = qValve1[i];
      }

      double dhEmk = (qValve1[i] - qValve2[i]) * dt / 3600.0;
      hEmk[i] = (hEmk[i - 1] + dhEmk).clamp(0.0, vEmk);

      // 3. Химцех: приток через Задвижку 2, отток = подпитка
      double qRealOut = qOut[i].clamp(qOutMin, qOutMax);
      // Ограничение: не можем отдать больше, чем есть
      if (hChem[i - 1] <= 0 && qRealOut > qValve2[i]) {
        qRealOut = qValve2[i];
      }

      double dhChem = (qValve2[i] - qRealOut) * dt / 3600.0;
      hChem[i] = (hChem[i - 1] + dhChem).clamp(0.0, vChem);
    }

    return SimulationResult(
      time: time,
      hEmk: hEmk,
      hChem: hChem,
      qIn: qIn,
      qValve1: qValve1,
      qValve2: qValve2,
      qOut: qOut,
    );
  }
}