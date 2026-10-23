import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/comercio_entity.dart';
import '../components/comercio_card.dart';
import 'comercio_detalle_page.dart';
import '../components/beneficios_search_bar.dart';
import '../components/servicios_taller_promociones_dialog.dart';
import '../providers/comercios_provider.dart';
import '../providers/auth_provider.dart';

const Color _comercioAccent = Color(0xFFC2410C);

/// Pantalla "Comercios GO" (K-0314): listado de establecimientos afiliados
/// (comida, tiendas, etc.) con descuentos para el cliente/conductor.
class ComerciosGoPage extends StatefulWidget {
  const ComerciosGoPage({super.key});

  @override
  State<ComerciosGoPage> createState() => _ComerciosGoPageState();
}

class _ComerciosGoPageState extends State<ComerciosGoPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ComerciosProvider>();
      final authProvider = context.read<AuthProvider>();
      // TK-0382: el servidor solo manda los comercios con servicios para la audiencia del conductor (conductores, clientes, pasajeros).
      if (authProvider.currentUser != null) provider.setAudiencia(authProvider.currentUser!.tipo);
      provider.cargarCategorias();
      provider.cargarComercios(departamento: authProvider.currentUser?.departamento);
      _mostrarPromociones(provider, authProvider.currentUser?.departamento);
    });
  }

  /// Igual que en Servicios de Taller: al entrar sale un diálogo flotante con los flyers de la web (Promociones > Comercios),
  /// que se desliza y se cierra para ver el listado. Sin flyers o con el interruptor apagado no sale nada.
  Future<void> _mostrarPromociones(ComerciosProvider provider, String? departamento) async {
    final banners = await provider.cargarPromocionesBanners(departamento: departamento);
    if (!mounted || banners.isEmpty) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ServiciosTallerPromocionesDialog(banners: banners),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_comercioAccent, Color(0xFF9A3412)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Consumer<ComerciosProvider>(
                    builder: (context, provider, child) {
                      if (provider.loading && provider.comercios.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null && provider.comercios.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar comercios',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.error!,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.cargarComercios(departamento: authProvider.currentUser?.departamento),
                                style: ElevatedButton.styleFrom(backgroundColor: _comercioAccent, foregroundColor: Colors.white),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      final grupos = provider.filteredGrupos;
                      final totalComercios = grupos.fold<int>(0, (suma, g) => suma + g.comercios.length);

                      return Column(
                        children: [
                          if (provider.loading) const LinearProgressIndicator(minHeight: 2, color: _comercioAccent),
                          BeneficiosSearchBar(
                            controller: _searchController,
                            searchQuery: _searchController.text,
                            onChanged: (value) {
                              setState(() {});
                              provider.setSearchQuery(value);
                            },
                            onClear: () {
                              _searchController.clear();
                              setState(() {});
                              provider.setSearchQuery('');
                            },
                          ),
                          _buildFiltroCategorias(provider),
                          _buildFiltroTipoVehicular(provider),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Mostrando $totalComercios comercios',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: grupos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No se encontraron comercios',
                                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => provider.cargarComercios(departamento: authProvider.currentUser?.departamento),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      itemCount: grupos.length,
                                      // TK-0382: agrupados por ciudad (Lima por distrito, el resto por provincia), como los talleres.
                                      itemBuilder: (context, gi) {
                                        final grupo = grupos[gi];
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildEncabezadoCiudad(grupo),
                                            // TK-0314: tocar el comercio abre sus servicios.
                                            ...grupo.comercios.map(
                                              (comercio) => ComercioCard(
                                                comercio: comercio,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => ComercioDetallePage(comercio: comercio)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezadoCiudad(ComercioGrupoEntity grupo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          const Icon(Icons.location_city, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              grupo.nombre,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${grupo.total}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _tiposVehicular = [
    {'value': '', 'label': 'Todos'},
    {'value': 'vehiculo', 'label': 'Carro'},
    {'value': 'moto', 'label': 'Moto'},
    {'value': 'tuktuk', 'label': 'TukTuk'},
  ];

  /// TK-0382: igual que en talleres. Con el tipo de vehículo el servidor deja solo los comercios con servicios para ese vehículo.
  Widget _buildFiltroTipoVehicular(ComerciosProvider provider) {
    final actual = provider.tipoVehicularFiltro ?? '';
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: _tiposVehicular.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tipo = _tiposVehicular[index];
          final seleccionado = actual == tipo['value'];
          return ChoiceChip(
            key: Key('comercios-vehiculo-${tipo['value']!.isEmpty ? 'todos' : tipo['value']}'),
            label: Text(tipo['label']!),
            selected: seleccionado,
            onSelected: (_) => provider.setTipoVehicularFiltro(tipo['value']),
            selectedColor: _comercioAccent,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: seleccionado ? Colors.white : Colors.grey.shade700,
            ),
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(color: seleccionado ? _comercioAccent : Colors.grey.shade300),
          );
        },
      ),
    );
  }

  Widget _buildFiltroCategorias(ComerciosProvider provider) {
    if (provider.categorias.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: provider.categorias.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final esTodos = index == 0;
          final categoria = esTodos ? null : provider.categorias[index - 1];
          final seleccionado = provider.categoriaFiltro == categoria?.id;

          return ChoiceChip(
            label: Text(esTodos ? 'Todos' : categoria!.nombre),
            selected: seleccionado,
            onSelected: (_) {
              final authProvider = context.read<AuthProvider>();
              provider.setCategoriaFiltro(categoria?.id, departamento: authProvider.currentUser?.departamento);
            },
            selectedColor: _comercioAccent,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: seleccionado ? Colors.white : Colors.grey.shade700,
            ),
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(color: seleccionado ? _comercioAccent : Colors.grey.shade300),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Expanded(
                child: Text(
                  'Comercios GO',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt()), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descuentos cerca de ti',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Restaurantes, tiendas y más establecimientos afiliados',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
}
