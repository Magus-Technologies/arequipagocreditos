import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../providers/beneficios_provider.dart';
import '../../theme/app_theme.dart';
import '../components/beneficios_components.dart';

class BeneficiosPage extends StatefulWidget {
  const BeneficiosPage({super.key});

  @override
  State<BeneficiosPage> createState() => _BeneficiosPageState();
}

class _BeneficiosPageState extends State<BeneficiosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroCategoria = 'Todos';
  final List<String> _categorias = [
    'Todos',
    'Electrónicos',
    'Hogar',
    'Vehículos',
    'Servicios'
  ];

  @override
  void initState() {
    super.initState();
    // Cargar beneficios al inicializar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BeneficiosProvider>().getBeneficios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BeneficioComercialEntity> _filtrarBeneficiosPorCategoria(
    List<BeneficioComercialEntity> beneficios, 
    String categoria
  ) {
    if (categoria == 'Todos') {
      return beneficios;
    }
    // Aquí puedes implementar la lógica de filtrado específica según tus categorías
    return beneficios;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BeneficiosProvider>(
      builder: (context, provider, child) {
        final beneficios = provider.searchBeneficios(_searchQuery);
        final beneficiosFiltrados = _filtrarBeneficiosPorCategoria(beneficios, _filtroCategoria);
        
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
              bottom: false,
              child: Column(
                children: [
                  BeneficiosHeader(beneficiosFiltrados: beneficiosFiltrados),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          BeneficiosSearchBar(
                            controller: _searchController,
                            searchQuery: _searchQuery,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            onClear: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                          BeneficiosCategoryFilter(
                            filtroCategoria: _filtroCategoria,
                            categorias: _categorias,
                            onCategoryChanged: (categoria) {
                              setState(() {
                                _filtroCategoria = categoria;
                              });
                            },
                          ),
                          Expanded(
                            child: _buildContent(provider, beneficiosFiltrados),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BeneficiosProvider provider, List<BeneficioComercialEntity> beneficiosFiltrados) {
    // Mostrar estados de error, loading o vacío
    if (provider.isLoading || provider.hasError || beneficiosFiltrados.isEmpty) {
      return BeneficiosContentStates(
        provider: provider,
        searchQuery: _searchQuery,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: beneficiosFiltrados.length,
        itemBuilder: (context, index) {
          final beneficio = beneficiosFiltrados[index];
          return BeneficioCard(
            beneficio: beneficio,
            onTap: () => BeneficioDetailsModal.show(context, beneficio),
          );
        },
      ),
    );
  }
}