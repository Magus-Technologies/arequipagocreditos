import 'package:arequipagocreditos/data/models/puntuacion_model.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/presentation/components/historial_item.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class HistorialCompletoPage extends StatefulWidget {
  final List<HistorialPuntosModel> historial;

  const HistorialCompletoPage({super.key, required this.historial});

  @override
  State<HistorialCompletoPage> createState() => _HistorialCompletoPageState();
}

class _HistorialCompletoPageState extends State<HistorialCompletoPage> {
  String _filtroSeleccionado = 'todos';
  
  List<HistorialPuntosModel> get historialFiltrado {
    switch (_filtroSeleccionado) {
      case 'suma':
        return widget.historial.where((item) => item.tipo == 'suma').toList();
      case 'resta':
        return widget.historial.where((item) => item.tipo == 'resta').toList();
      case 'neutro':
        return widget.historial.where((item) => item.tipo == 'neutro').toList();
      default:
        return widget.historial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primary.withAlpha((0.8 * 255).toInt()),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Historial Completo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Consumer<AuthProvider>(
                    //   builder: (context, authProvider, child) {
                    //     return Container(
                    //       decoration: BoxDecoration(
                    //         color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       child: IconButton(
                    //         icon: authProvider.isLoading
                    //             ? const SizedBox(
                    //                 width: 20,
                    //                 height: 20,
                    //                 child: CircularProgressIndicator(
                    //                   strokeWidth: 2,
                    //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                    //                 ),
                    //               )
                    //             : const Icon(
                    //                 Icons.analytics_outlined,
                    //                 color: Colors.black87,
                    //                 size: 20,
                    //               ),
                    //         onPressed: authProvider.isLoading ? null : () {
                    //           // Aquí podrías agregar funcionalidad para exportar o compartir el historial
                    //           ScaffoldMessenger.of(context).showSnackBar(
                    //             const SnackBar(
                    //               content: Text('Funcionalidad de exportación próximamente'),
                    //             ),
                    //           );
                    //         },
                    //         tooltip: 'Exportar historial',
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
              // Contenido principal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Estadísticas
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildEstadistica(
                                'Total',
                                widget.historial.length.toString(),
                                Icons.list,
                                Colors.blue,
                              ),
                              _buildEstadistica(
                                'Puntuales',
                                widget.historial.where((item) => item.tipo == 'suma').length.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                              _buildEstadistica(
                                'Retrasos',
                                widget.historial.where((item) => item.tipo == 'resta').length.toString(),
                                Icons.warning,
                                Colors.red,
                              ),
                              _buildEstadistica(
                                'Pendientes',
                                widget.historial.where((item) => item.tipo == 'neutro').length.toString(),
                                Icons.schedule,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Filtros
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtrar por tipo:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFiltroChip('todos', 'Todos', Icons.list),
                                    const SizedBox(width: 8),
                                    _buildFiltroChip('suma', 'Puntuales', Icons.add, Colors.green),
                                    const SizedBox(width: 8),
                                    _buildFiltroChip('resta', 'Retrasos', Icons.remove, Colors.red),
                                    const SizedBox(width: 8),
                                    _buildFiltroChip('neutro', 'Pendientes', Icons.schedule, Colors.grey),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Lista de historial
                        Expanded(
                          child: historialFiltrado.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay registros para este filtro',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _filtroSeleccionado = 'todos';
                                          });
                                        },
                                        icon: const Icon(Icons.clear_all),
                                        label: const Text('Limpiar filtros'),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  itemCount: historialFiltrado.length,
                                  itemBuilder: (context, index) {
                                    final item = historialFiltrado[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: HistorialItem(item: item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadistica(String label, String valor, IconData icono, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icono,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String valor, String label, IconData icono, [Color? color]) {
    final isSelected = _filtroSeleccionado == valor;
    final chipColor = color ?? AppTheme.primary;
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroSeleccionado = valor;
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withAlpha((0.3 * 255).toInt()),
        ),
      ),
    );
  }
}
