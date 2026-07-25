import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../providers/beneficios_provider.dart';
import '../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../components/beneficios_components.dart';

class BeneficiosPage extends StatefulWidget {
  final bool isNav;
  const BeneficiosPage({super.key, this.isNav = false});

  @override
  State<BeneficiosPage> createState() => _BeneficiosPageState();
}

class _BeneficiosPageState extends State<BeneficiosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroCategoria = 'Todos';

  /// Categorias reales presentes en los beneficios cargados. Se arman solas,
  /// asi que si el negocio crea una categoria nueva aparece sin publicar app.
  List<String> _categoriasDisponibles(List<BeneficioComercialEntity> beneficios) {
    final nombres = beneficios
        .map((b) => b.categoriaNombre)
        .whereType<String>()
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final haySinCategoria = beneficios.any(
      (b) => b.categoriaNombre == null || b.categoriaNombre!.trim().isEmpty,
    );

    return ['Todos', ...nombres, if (haySinCategoria) 'Otros'];
  }

  @override
  void initState() {
    super.initState();
    // Cargar beneficios al inicializar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final beneficiosProvider = context.read<BeneficiosProvider>();
      
      // Configurar audiencia según tipo de usuario
      if (authProvider.currentUser != null) {
        beneficiosProvider.setAudiencia(authProvider.currentUser!.tipo);
      }
      
      beneficiosProvider.getBeneficios();
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

    if (categoria == 'Otros') {
      return beneficios
          .where((b) => b.categoriaNombre == null || b.categoriaNombre!.trim().isEmpty)
          .toList();
    }

    return beneficios.where((b) => b.categoriaNombre == categoria).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BeneficiosProvider>(
      builder: (context, provider, child) {
        final beneficios = provider.searchBeneficios(_searchQuery);
        final categorias = _categoriasDisponibles(beneficios);
        final filtroActivo = categorias.contains(_filtroCategoria) ? _filtroCategoria : 'Todos';
        final beneficiosFiltrados = _filtrarBeneficiosPorCategoria(beneficios, filtroActivo);
        
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
                  BeneficiosHeader(beneficiosFiltrados: beneficiosFiltrados, isNav: widget.isNav),
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
                          const SizedBox(height: 16),
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
                            filtroCategoria: filtroActivo,
                            categorias: categorias,
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