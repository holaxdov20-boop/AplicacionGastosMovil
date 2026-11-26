import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart'; // [login]
import '../providers/gastos_provider.dart';
import 'gasto_form_screen.dart';
import 'gastos_tab.dart';
import 'presupuestos_tab.dart';
import 'resumen_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pestana = 0;

  static const _titulos = ['Gastos', 'Resumen', 'Presupuestos'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastosProvider>().inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sincronizando = context.select<GastosProvider, bool>(
      (p) => p.sincronizando,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_pestana]),
        actions: [
          if (sincronizando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Sincronizar',
              icon: const Icon(Icons.sync),
              onPressed: () => context.read<GastosProvider>().sincronizar(),
            ),
          IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () => context.read<AuthProvider>().cerrarSesion()), // [login]
        ],
      ),
      body: const [
        GastosTab(),
        ResumenTab(),
        PresupuestosTab(),
      ][_pestana],
      floatingActionButton: _pestana == 0
          ? FloatingActionButton(
              tooltip: 'Nuevo gasto',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GastoFormScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Gastos'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Resumen'),
          NavigationDestination(
              icon: Icon(Icons.savings), label: 'Presupuestos'),
        ],
      ),
    );
  }
}
