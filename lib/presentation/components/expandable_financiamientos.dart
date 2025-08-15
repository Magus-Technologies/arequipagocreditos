import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/presentation/pages/financiamiento_page.dart';
import 'package:flutter/material.dart';

class ExpandableFinanciamientos extends StatefulWidget {
  final ConductorModel conductor;

  const ExpandableFinanciamientos({super.key, required this.conductor});

  @override
  State<ExpandableFinanciamientos> createState() =>
      _ExpandableFinanciamientosState();
}

class _ExpandableFinanciamientosState extends State<ExpandableFinanciamientos> {
  bool _isFinanciamientosExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del módulo - clickeable
          GestureDetector(
            onTap: () {
              setState(() {
                _isFinanciamientosExpanded = !_isFinanciamientosExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius:
                    _isFinanciamientosExpanded
                        ? const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )
                        : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Financiamientos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Gestiona tus créditos activos',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedRotation(
                      turns: _isFinanciamientosExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.expand_more,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido de financiamientos - expandible con altura dinámica
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child:
                _isFinanciamientosExpanded
                    ? Container(
                      constraints: BoxConstraints(
                        minHeight: 200,
                        maxHeight:
                            MediaQuery.of(context).size.height *
                            0.4, // Máximo 40% de la pantalla
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child:
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            child: SizedBox(
                              height: 300, // Altura fija pero más razonable
                              child: FinanciamientoPage(
                                idConductor: widget.conductor.idConductor,
                                tipo: widget.conductor.tipo,
                              ),
                            ),
                          ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
