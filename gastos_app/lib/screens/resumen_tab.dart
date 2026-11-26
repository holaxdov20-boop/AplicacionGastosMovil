import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gastos_provider.dart';
import '../utils/formato.dart';

/// Gráfica de pastel con el gasto del mes por categoría (fl_chart).
class ResumenTab extends StatelessWidget {
  const ResumenTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GastosProvider>();
    final total = p.totalMes;

    if (p.cargando && p.gastos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (total <= 0) {
      return const Center(child: Text('Sin gastos este mes.'));
    }

    final entradas = p.totalesMes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Gasto del mes', style: Theme.of(context).textTheme.titleMedium),
        Text(
          dinero(total),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                for (final e in entradas)
                  PieChartSectionData(
                    value: e.value,
                    color: Color(p.categoriaPorId(e.key)?.color ?? 0xFF90A4AE),
                    radius: 58,
                    title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final e in entradas)
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 8,
              backgroundColor:
                  Color(p.categoriaPorId(e.key)?.color ?? 0xFF90A4AE),
            ),
            title: Text(p.categoriaPorId(e.key)?.nombre ?? 'Otros'),
            trailing: Text(dinero(e.value)),
          ),
      ],
    );
  }
}
