import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/presupuesto.dart';
import '../providers/gastos_provider.dart';
import '../utils/formato.dart';
import '../utils/validators.dart';

/// Presupuestos por categoría y periodo, con barra de avance.
class PresupuestosTab extends StatelessWidget {
  const PresupuestosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GastosProvider>();

    return Column(
      children: [
        Expanded(
          child: p.presupuestos.isEmpty
              ? const Center(child: Text('Aún no hay presupuestos.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: p.presupuestos.length,
                  itemBuilder: (context, i) {
                    final pres = p.presupuestos[i];
                    final gastado = p.gastadoPorPresupuesto[pres.id] ?? 0;
                    final avance = gastado / pres.monto;
                    final color = avance >= 1
                        ? Colors.red
                        : avance >= 0.8
                            ? Colors.orange
                            : Colors.green;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p.categoriaPorId(pres.categoriaId)?.nombre ?? '—'}'
                                    ' · ${pres.periodo.etiqueta}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => context
                                      .read<GastosProvider>()
                                      .eliminarPresupuesto(pres.id),
                                ),
                              ],
                            ),
                            LinearProgressIndicator(
                              value: avance.clamp(0.0, 1.0),
                              color: color,
                              minHeight: 8,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${dinero(gastado)} de ${dinero(pres.monto)} '
                              '(${(avance * 100).toStringAsFixed(0)} %)',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: p.categorias.isEmpty
                  ? null
                  : () => showDialog<void>(
                        context: context,
                        builder: (_) => const _PresupuestoDialog(),
                      ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar presupuesto'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresupuestoDialog extends StatefulWidget {
  const _PresupuestoDialog();

  @override
  State<_PresupuestoDialog> createState() => _PresupuestoDialogState();
}

class _PresupuestoDialogState extends State<_PresupuestoDialog> {
  final _form = GlobalKey<FormState>();
  final _monto = TextEditingController();
  String? _categoriaId;
  Periodo _periodo = Periodo.semanal;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.read<GastosProvider>().categorias;

    return AlertDialog(
      title: const Text('Nuevo presupuesto'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _categoriaId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in categorias)
                  DropdownMenuItem(value: c.id, child: Text(c.nombre)),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
              validator: (v) => v == null ? 'Elige una categoría' : null,
            ),
            TextFormField(
              controller: _monto,
              decoration:
                  const InputDecoration(labelText: 'Monto límite', prefixText: '\$ '),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.monto,
            ),
            const SizedBox(height: 16),
            SegmentedButton<Periodo>(
              segments: const [
                ButtonSegment(value: Periodo.semanal, label: Text('Semanal')),
                ButtonSegment(value: Periodo.mensual, label: Text('Mensual')),
              ],
              selected: {_periodo},
              onSelectionChanged: (s) => setState(() => _periodo = s.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            context.read<GastosProvider>().guardarPresupuesto(
                  categoriaId: _categoriaId!,
                  monto: Validators.parseMonto(_monto.text)!,
                  periodo: _periodo,
                );
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
