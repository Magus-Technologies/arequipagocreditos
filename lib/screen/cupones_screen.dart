import 'package:flutter/material.dart';
import '../models/cupon.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CuponesScreen extends StatefulWidget {
  const CuponesScreen({super.key});

  @override
  State<CuponesScreen> createState() => _CuponesScreenState();
}

class _CuponesScreenState extends State<CuponesScreen> {
  List<Cupon> _cupones = [];
  bool _isLoading = true;
  String _filtroCategoria = 'Todos';
  final List<String> _categorias = ['Todos', 'Restaurantes', 'Tiendas', 'Servicios', 'Entretenimiento'];

  @override
  void initState() {
    super.initState();
    _loadCupones();
  }

  Future<void> _loadCupones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cupones = await ApiService.getCupones();
      setState(() {
        _cupones = cupones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cupones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Cupon> get _cuponesFiltrados {
    if (_filtroCategoria == 'Todos') {
      return _cupones;
    }
    return _cupones.where((cupon) => cupon.categoria == _filtroCategoria).toList();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
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
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                        '${_cuponesFiltrados.where((c) => c.puedeUsarse).length} disponibles',
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_cuponesFiltrados.isEmpty) {
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
      onRefresh: _loadCupones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cuponesFiltrados.length,
        itemBuilder: (context, index) {
          return _buildCuponCard(_cuponesFiltrados[index]);
        },
      ),
    );
  }

  Widget _buildCuponCard(Cupon cupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(cupon.categoria),
            ),
          ),
          child: Stack(
            children: [
              // Patrón de fondo
              Positioned.fill(
                child: CustomPaint(
                  painter: CuponPatternPainter(),
                ),
              ),
              // Contenido del cupón
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icono de la categoría
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(cupon.categoria),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Información principal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cupon.empresa,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                cupon.titulo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Descuento
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary, // Amarillo corporativo para destacar
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cupon.descuentoFormateado,
                            style: const TextStyle(
                              color: Colors.black87, // Texto negro sobre amarillo
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Descripción
                    Text(
                      cupon.descripcion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Footer con código y fecha
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.code, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  cupon.codigo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Válido hasta:',
                              style: TextStyle(
                                color: Colors.white.withAlpha((0.8 * 255).toInt()),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDate(cupon.fechaVencimiento),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Estado del cupón
                    if (!cupon.puedeUsarse) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              cupon.estaVencido ? 'Vencido' : 'No disponible',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Botón de usar cupón
              if (cupon.puedeUsarse)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () => _usarCupon(cupon),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary, // Amarillo corporativo
                      foregroundColor: Colors.black87, // Texto negro
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Usar Cupón',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String categoria) {
    // Paleta uniforme y sobria para todas las categorías
    return [const Color(0xFF1F2937), const Color(0xFF374151)]; // Negro elegante para todas
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria) {
      case 'Restaurantes':
        return Icons.restaurant;
      case 'Tiendas':
        return Icons.shopping_bag;
      case 'Servicios':
        return Icons.build;
      case 'Entretenimiento':
        return Icons.movie;
      default:
        return Icons.local_offer;
    }
  }

  void _usarCupon(Cupon cupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usar Cupón'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas usar el cupón "${cupon.titulo}"?'),
            const SizedBox(height: 8),
            Text(
              'Código: ${cupon.codigo}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (cupon.condiciones != null) ...[
              const SizedBox(height: 8),
              Text(
                'Condiciones: ${cupon.condiciones}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmarUsoCupon(cupon);
            },
            child: const Text('Usar'),
          ),
        ],
      ),
    );
  }

  void _confirmarUsoCupon(Cupon cupon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cupón "${cupon.codigo}" usado exitosamente'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ver detalles',
          textColor: Colors.white,
          onPressed: () {
            // Implementar vista de detalles del uso del cupón
          },
        ),
      ),
    );
    
    // Aquí puedes implementar la lógica para marcar el cupón como usado en el backend
    _loadCupones(); // Recargar la lista
  }
}

// Painter para el patrón de fondo del cupón
class CuponPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.1 * 255).toInt())
      ..style = PaintingStyle.fill;

    // Crear un patrón de círculos
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
