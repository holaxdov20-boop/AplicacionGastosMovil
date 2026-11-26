import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gasto.dart';
import '../providers/gastos_provider.dart';
import '../utils/formato.dart';
import '../utils/validators.dart';

/// Crear (gasto == null) o editar un gasto.
class GastoFormScreen extends StatefulWidget {
  const GastoFormScreen({super.key, this.gasto});

  final Gasto? gasto;

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;
  late DateTime _fecha;
  String? _categoriaId;
  bool _guardando = false;

  bool get _editando => widget.gasto != null;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    _monto = TextEditingController(text: g == null ? '' : g.monto.toString());
    _descripcion = TextEditingController(text: g?.descripcion ?? '');
    _fecha = g?.fecha ?? DateTime.now();
    _categoriaId = g?.categoriaId;
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final proveedor = context.read<GastosProvider>();
    final navegador = Navigator.of(context);
    final monto = Validators.parseMonto(_monto.text)!;
    final descripcion = Validators.sanitizar(_descripcion.text);

    setState(() => _guardando = true);
    final ok = _editando
        ? await proveedor.actualizarGasto(widget.gasto!.copyWith(
            monto: monto,
            descripcion: descripcion,
            fecha: _fecha,
            categoriaId: _categoriaId,
          ))
        : await proveedor.crearGasto(
            monto: monto,
            descripcion: descripcion,
            fecha: _fecha,
            categoriaId: _categoriaId!,
          );
    if (!mounted) return;
    if (ok) {
      navegador.pop();
    } else {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(proveedor.error ?? 'No se pudo guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<GastosProvider>().categorias;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar gasto' : 'Nuevo gasto')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _monto,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.monto,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in categorias)
                    DropdownMenuItem(
                      value: c.id,
                      child: Row(children: [
                        CircleAvatar(radius: 6, backgroundColor: Color(c.color)),
                        const SizedBox(width: 8),
                        Text(c.nombre),
                      ]),
                    ),
                ],
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) => v == null ? 'Elige una categoría' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  helperText: 'Se guarda cifrada',
                  border: OutlineInputBorder(),
                ),
                maxLength: Validators.maxDescripcion,
                validator: Validators.descripcion,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.event),
                label: Text('Fecha: ${fechaCorta(_fecha)}'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editando ? 'Guardar cambios' : 'Agregar gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
