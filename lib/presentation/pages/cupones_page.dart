import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cupones_provider.dart';
import '../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/model_adapters.dart';
import '../widgets/cupon_card.dart';
import '../widgets/confirmacion_uso_cupon_dialog.dart';
import '../widgets/dialogs.dart';

class CuponesPage extends StatefulWidget {
  const CuponesPage({super.key});

  @override
  State<CuponesPage> createState() => _CuponesPageState();
}

class _CuponesPageState extends State<CuponesPage> {
  String _filtroCategoria = 'Todos';
  final List<String> _categorias = [
    'Todos',
    'Restaurantes',
    'Tiendas',
    'Servicios',
    'Entretenimiento'
  ];

  @override
  void initState() {
    super.initState();
    // Cargar cupones al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final cuponesProvider = context.read<CuponesProvider>();
      
      // Configurar audiencia según tipo de usuario
      if (authProvider.currentUser != null) {
        cuponesProvider.setAudiencia(authProvider.currentUser!.tipo);
      }
      
      cuponesProvider.loadCupones();
    });
  }

  List<CuponModel> _filtrarCuponesPorCategoria(List<CuponModel> cupones, String categoria) {
    if (categoria == 'Todos') {
      return cupones;
    }
    return cupones.where((cupon) => cupon.categoria == categoria).toList();
  }

  void _usarCupon(CuponModel cupon) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmacionUsoCuponDialog(
        cupon: cupon,
        onConfirm: () => _confirmarUsoCupon(cupon),
      ),
    );
  }

  void _confirmarUsoCupon(CuponModel cupon) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CargaDialog(),
    );

    try {
      final cuponesProvider = context.read<CuponesProvider>();
      final success = await cuponesProvider.usarCupon(cupon.id);
      
      // Cerrar el diálogo de carga
      if (mounted) Navigator.pop(context);

      if (success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const ExitoDialog(
              mensaje: 'Cupón usado exitosamente',
            ),
          );
        }
      } else {
        // Mostrar mensaje de error
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => ErrorDialog(
              mensaje: cuponesProvider.errorMessage ?? 'Error al usar el cupón',
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar el diálogo de carga si aún está abierto
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensaje de error
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const ErrorDialog(
            mensaje: 'Error de conexión. Verifica tu internet e intenta nuevamente.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CuponesProvider>(
      builder: (context, cuponesProvider, child) {
        final cuponesEntities = cuponesProvider.cupones;
        final cupones = ModelAdapters.cuponEntitiesToModels(cuponesEntities);
        final cuponesFiltrados = _filtrarCuponesPorCategoria(cupones, _filtroCategoria);
        
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
                  _buildHeader(cuponesFiltrados),
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
                          _buildCategoryFilter(),
                          Expanded(
                            child: _buildContent(cuponesProvider, cuponesFiltrados),
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

  Widget _buildHeader(List<CuponModel> cuponesFiltrados) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // AppBar personalizado
          Row(
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
                  'Cupones y Beneficios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Espacio para balancear el título
            ],
          ),
          const SizedBox(height: 20),
          // Información de cupones disponibles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.5 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cupones',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cuponesFiltrados.where((c) => c.puedeUsarse).length} disponibles',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          final isSelected = categoria == _filtroCategoria;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(categoria),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroCategoria = categoria;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppTheme.primary.withAlpha((0.2 * 255).toInt()),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(CuponesProvider cuponesProvider, List<CuponModel> cuponesFiltrados) {
    if (cuponesProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cuponesProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar cupones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cuponesProvider.errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cuponesProvider.loadCupones(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (cuponesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay cupones disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente tendremos ofertas especiales para ti',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => cuponesProvider.loadCupones(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cuponesFiltrados.length,
        itemBuilder: (context, index) {
          return CuponCard(
            cupon: cuponesFiltrados[index],
            onUsar: () => _usarCupon(cuponesFiltrados[index]),
          );
        },
      ),
    );
  }
}
