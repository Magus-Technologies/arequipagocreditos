import 'package:arequipagocreditos/models/financiamiento.dart';
import 'package:arequipagocreditos/screen/financiamiento_detalle_screen.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:flutter/material.dart';

class FinanciamientoList extends StatefulWidget {
  final int idConductor;
  final int tipo;

  const FinanciamientoList({
    super.key,
    required this.idConductor,
    required this.tipo,
  });

  @override
  State<FinanciamientoList> createState() => _FinanciamientoListState();
}

class _FinanciamientoListState extends State<FinanciamientoList> {
  late Future<List<Financiamiento>> _futureFinanciamientos;

  @override
  void initState() {
    super.initState();
    _loadFinanciamientos();
  }

  Future<void> _loadFinanciamientos() async {
    setState(() {
      _futureFinanciamientos = ApiService.fetchFinanciamientos(
        widget.idConductor,
        widget.tipo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Financiamiento>>(
      future: _futureFinanciamientos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No hay financiamientos disponibles.'),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadFinanciamientos,
          child: ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final financiamiento = snapshot.data![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código Asociado: ${financiamiento.codigoAsociado}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Grupo de Financiamiento: ${financiamiento.grupoFinanciamiento}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Estado: ${financiamiento.estado}',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.date_range, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Inicio: ${financiamiento.fechaInicio} - Fin: ${financiamiento.fechaFin}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.payment, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('N° Cuotas: ${financiamiento.cuotas}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DetalleFinanciamientoScreen(
                                    idFinanciamiento:
                                        financiamiento.idFinanciamiento,
                                    moneda: financiamiento.moneda
                                  ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Ver detalles',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
