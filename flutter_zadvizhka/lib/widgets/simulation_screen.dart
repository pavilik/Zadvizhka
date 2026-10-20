import 'package:flutter/material.dart';
import '../models/simulation.dart';
import 'flow_chart.dart';
import 'level_chart.dart';
import 'regulator_chart.dart';
import 'tank_visualizer.dart';
import 'imitation_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late SimulationResult _data;
  double _kValve1 = 0.75;
  double _kValve2 = 0.70;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _data = SystemSimulation.run(kValve1: _kValve1, kValve2: _kValve2);
  }

  void _rerunSimulation() {
    setState(() {
      _data = SystemSimulation.run(kValve1: _kValve1, kValve2: _kValve2);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text(
          'Моделирование системы водоподготовки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF282840),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rerunSimulation,
            tooltip: 'Перезапустить симуляцию',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sliders for Valve 1 and Valve 2
          _buildSliders(),
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF2D2D44),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ручные задвижки работают фиксированно — регулятор подпитки (50–250 т/ч) '
                    'создаёт возмущения, нужно удерживать уровни в диапазоне',
                    style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                  ),
                ),
              ],
            ),
          ),
          // Charts
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _buildChartPage(
                  FlowChart(data: _data),
                  'Расходы, т/ч',
                  Icons.show_chart,
                ),
                _buildChartPage(
                  LevelChart(data: _data),
                  'Уровни, м',
                  Icons.water_drop,
                ),
                _buildChartPage(
                  RegulatorChart(data: _data),
                  'Регулятор',
                  Icons.tune,
                ),
                _buildChartPage(
                  TankVisualizer(data: _data),
                  'Ёмкости',
                  Icons.storage,
                ),
                _buildChartPage(
                  ImitationScreen(),
                  'Имитация',
                  Icons.tune,
                ),
              ],
            ),
          ),
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFF282840),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageDot(0, Icons.show_chart),
                const SizedBox(width: 8),
                _pageDot(1, Icons.water_drop),
                const SizedBox(width: 8),
                _pageDot(2, Icons.opacity),
                const SizedBox(width: 8),
                _pageDot(3, Icons.storage),
                const SizedBox(width: 8),
                _pageDot(4, Icons.tune),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF252540),
      child: Row(
        children: [
          // Valve 1 slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.toll, size: 14, color: Colors.cyan),
                    const SizedBox(width: 4),
                    Text(
                      'Задвижка 1: ${(_kValve1 * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _kValve1,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: Colors.cyan,
                  inactiveColor: Colors.cyan.withOpacity(0.2),
                  onChanged: (v) {
                    setState(() => _kValve1 = v);
                  },
                  onChangeEnd: (_) => _rerunSimulation(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Valve 2 slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.toll, size: 14, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(
                      'Задвижка 2: ${(_kValve2 * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _kValve2,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: Colors.teal,
                  inactiveColor: Colors.teal.withOpacity(0.2),
                  onChanged: (v) {
                    setState(() => _kValve2 = v);
                  },
                  onChangeEnd: (_) => _rerunSimulation(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPage(Widget chart, String title, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: chart),
      ],
    );
  }

  Widget _pageDot(int index, IconData icon) {
    final isActive = index == _currentPage;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF5C5C8C)
              : const Color(0xFF3D3D5C),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.white38, width: 1)
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: 16,
        ),
      ),
    );
  }
}