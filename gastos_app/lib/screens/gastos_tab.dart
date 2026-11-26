import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gastos_provider.dart';
import '../utils/formato.dart';
import 'gasto_form_screen.dart';

/// Lista de gastos: toca para editar, desliza para eliminar,
/// jala hacia abajo para sincronizar.
class GastosTab extends StatelessWidget {
  const GastosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GastosProvider>();

    if (p.cargando && p.gastos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (p.error != null)
          MaterialBanner(
            content: Text(p.error!),
            leading: const Icon(Icons.error_outline),
            actions: [
              TextButton(
                onPressed: () => context.read<GastosProvider>().inicializar(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<GastosProvider>().sincronizar(),
            child: p.gastos.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: Text(
                          'Aún no tienes gastos.\nToca + para agregar el primero.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: p.gastos.length,
                    itemBuilder: (context, i) {
                      final g = p.gastos[i];
                      final cat = p.categoriaPorId(g.categoriaId);
                      return Dismissible(
                        key: ValueKey(g.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _confirmar(context),
                        onDismissed: (_) => context
                            .read<GastosProvider>()
                            .eliminarGasto(g.id),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(cat?.color ?? 0xFF90A4AE),
                            child: const Icon(Icons.receipt_long,
                                color: Colors.white, size: 20),
                          ),
                          title: Text(g.descripcion.isEmpty
                              ? (cat?.nombre ?? 'Gasto')
                              : g.descripcion),
                          subtitle:
                              Text('${cat?.nombre ?? '—'} · ${fechaCorta(g.fecha)}'),
                          trailing: Text(
                            dinero(g.monto),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GastoFormScreen(gasto: g),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _confirmar(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar gasto?'),
          content: const Text('Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
}
