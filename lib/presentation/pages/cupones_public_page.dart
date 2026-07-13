import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/entities/cupon_entity.dart';
import '../widgets/cupon_public_card.dart';
import '../pages/cupon_public_detail_page.dart';
import '../providers/auth_provider.dart';
import '../providers/cupones_public_provider.dart';

class CuponesPublicPage extends StatefulWidget {
  const CuponesPublicPage({super.key});

  @override
  State<CuponesPublicPage> createState() => _CuponesPublicPageState();
}

class _CuponesPublicPageState extends State<CuponesPublicPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final provider = context.read<CuponesPublicProvider>();
      if (authProvider.currentUser != null) {
        provider.setAudiencia(authProvider.currentUser!.tipo);
      }
      provider.loadPublicCupones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CuponesPublicProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primary.withAlpha((0.8 * 255).toInt())],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(provider),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: _buildBody(provider),
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

  Widget _buildHeader(CuponesPublicProvider provider) {
    final cupones = provider.cupones;
    final disponibles = cupones.where((c) => c.puedeUsarse).length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // AppBar personalizado
          Row(
            children: [
              
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
                        '$disponibles disponibles',
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

  Widget _buildBody(CuponesPublicProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.status == PublicCuponesStatus.error) return _buildError(provider.errorMessage);
    if (provider.cupones.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: () => provider.loadPublicCupones(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.cupones.length,
        itemBuilder: (context, index) {
          final CuponEntity c = provider.cupones[index];
          return CuponPublicCard(
            cupon: c,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CuponPublicDetailPage(cupon: c))),
          );
        },
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(message ?? 'Error', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => context.read<CuponesPublicProvider>().loadPublicCupones(), child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No hay cupones disponibles'),
        ],
      ),
    );
  }
}
