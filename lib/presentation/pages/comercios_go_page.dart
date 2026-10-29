import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/comercio_entity.dart';
import '../components/comercio_card.dart';
import 'comercio_detalle_page.dart';
import '../components/servicios_taller_promociones_dialog.dart';
import '../providers/comercios_provider.dart';
import '../providers/auth_provider.dart';

const Color _comercioAccent = Color(0xFFC2410C);
const Color _comercioAccentOscuro = Color(0xFF9A3412);
// Fondo cálido de la hoja: las tarjetas blancas se despegan de él sin necesitar sombras fuertes.
const Color _fondoHoja = Color(0xFFF8F6F3);

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

  String? get _departamento => context.read<AuthProvider>().currentUser?.departamento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _comercioAccentOscuro,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_comercioAccent, _comercioAccentOscuro],
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
                    color: _fondoHoja,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Consumer<ComerciosProvider>(
                    builder: (context, provider, child) {
                      if (provider.loading && provider.comercios.isEmpty) {
                        return const Center(child: CircularProgressIndicator(color: _comercioAccent));
                      }

                      if (provider.error != null && provider.comercios.isEmpty) {
                        return _buildError(provider);
                      }

                      final grupos = provider.filteredGrupos;
                      final totalComercios = grupos.fold<int>(0, (suma, g) => suma + g.comercios.length);

                      return Column(
                        children: [
                          if (provider.loading) const LinearProgressIndicator(minHeight: 2, color: _comercioAccent, backgroundColor: Colors.transparent),
                          _buildBuscador(provider),
                          _buildFiltroCategorias(provider),
                          _buildResumen(provider, totalComercios),
                          Expanded(
                            child: grupos.isEmpty
                                ? _buildVacio(provider)
                                : RefreshIndicator(
                                    color: _comercioAccent,
                                    onRefresh: () => provider.cargarComercios(departamento: _departamento),
                                    child: ListView.builder(
                                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
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

  Widget _buildError(ComerciosProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los comercios',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(provider.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => provider.cargarComercios(departamento: _departamento),
              style: FilledButton.styleFrom(backgroundColor: _comercioAccent),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio(ComerciosProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'No se encontraron comercios',
              style: TextStyle(fontSize: 17, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            if (provider.hayFiltros) ...[
              const SizedBox(height: 6),
              Text('Prueba quitando algún filtro.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 14),
              OutlinedButton(
                key: const Key('comercios-limpiar-vacio'),
                onPressed: () => provider.limpiarFiltros(departamento: _departamento),
                style: OutlinedButton.styleFrom(foregroundColor: _comercioAccent, side: const BorderSide(color: _comercioAccent)),
                child: const Text('Quitar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezadoCiudad(ComercioGrupoEntity grupo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 18, color: _comercioAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              grupo.nombre,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(color: _comercioAccent.withAlpha((0.1 * 255).toInt()), borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${grupo.total}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _comercioAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Buscador y, a su lado, el botón de filtros (tipo de vehículo). La categoría tiene su propia fila de píldoras justo debajo.
  Widget _buildBuscador(ComerciosProvider provider) {
    final hayVehiculo = provider.tipoVehicularFiltro != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14.5),
              onChanged: (value) {
                setState(() {});
                provider.setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar comercio o rubro',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          provider.setSearchQuery('');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: _bordeBuscador(Colors.grey.shade200),
                enabledBorder: _bordeBuscador(Colors.grey.shade200),
                focusedBorder: _bordeBuscador(_comercioAccent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: hayVehiculo ? _comercioAccent : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const Key('comercios-filtros-boton'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => _abrirFiltros(provider),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hayVehiculo ? _comercioAccent : Colors.grey.shade200),
                ),
                child: Icon(Icons.tune_rounded, color: hayVehiculo ? Colors.white : Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _bordeBuscador(Color color) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color));

  /// Fila única de categorías: una sola píldora seleccionada a la vez, la primera quita el filtro.
  Widget _buildFiltroCategorias(ComerciosProvider provider) {
    if (provider.categorias.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.categorias.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final esTodos = index == 0;
          final categoria = esTodos ? null : provider.categorias[index - 1];

          return _PildoraFiltro(
            key: Key('comercios-categoria-${esTodos ? 'todas' : categoria!.id}'),
            texto: esTodos ? 'Todas' : categoria!.nombre,
            seleccionada: provider.categoriaFiltro == categoria?.id,
            onTap: () => provider.setCategoriaFiltro(categoria?.id, departamento: _departamento),
          );
        },
      ),
    );
  }

  /// «Mostrando N comercios», el filtro de vehículo activo (con su X) y «Limpiar» cuando hay algún filtro puesto.
  Widget _buildResumen(ComerciosProvider provider, int total) {
    final vehiculo = _etiquetaVehiculo(provider.tipoVehicularFiltro);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 2),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            Flexible(
              child: Text(
                total == 1 ? 'Mostrando 1 comercio' : 'Mostrando $total comercios',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (vehiculo != null) ...[
              const SizedBox(width: 8),
              InkWell(
                key: const Key('comercios-quitar-vehiculo'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => provider.setTipoVehicularFiltro(''),
                child: Container(
                  padding: const EdgeInsets.only(left: 10, right: 6, top: 4, bottom: 4),
                  decoration: BoxDecoration(color: _comercioAccent.withAlpha((0.1 * 255).toInt()), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vehiculo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _comercioAccent)),
                      const SizedBox(width: 2),
                      const Icon(Icons.close_rounded, size: 14, color: _comercioAccent),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (provider.hayFiltros)
              TextButton(
                key: const Key('comercios-limpiar-filtros'),
                onPressed: () => provider.limpiarFiltros(departamento: _departamento),
                style: TextButton.styleFrom(foregroundColor: _comercioAccent, padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  static const List<_OpcionVehiculo> _opcionesVehiculo = [
    _OpcionVehiculo('', 'Todos', Icons.apps_rounded),
    _OpcionVehiculo('vehiculo', 'Carro', Icons.directions_car_filled_rounded),
    _OpcionVehiculo('moto', 'Moto', Icons.two_wheeler_rounded),
    _OpcionVehiculo('tuktuk', 'TukTuk', Icons.electric_rickshaw_rounded),
  ];

  String? _etiquetaVehiculo(String? valor) {
    for (final opcion in _opcionesVehiculo) {
      if (opcion.valor.isNotEmpty && opcion.valor == valor) return opcion.etiqueta;
    }
    return null;
  }

  /// TK-0382: igual que en talleres. Con el tipo de vehículo el servidor deja solo los comercios con servicios para ese vehículo.
  Future<void> _abrirFiltros(ComerciosProvider provider) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        final actual = provider.tipoVehicularFiltro ?? '';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrar comercios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text(
                  'Mostrar solo los comercios con servicios para tu vehículo.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < _opcionesVehiculo.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _TarjetaVehiculo(
                          key: Key('comercios-vehiculo-${_opcionesVehiculo[i].valor.isEmpty ? 'todos' : _opcionesVehiculo[i].valor}'),
                          opcion: _opcionesVehiculo[i],
                          seleccionada: actual == _opcionesVehiculo[i].valor,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            provider.setTipoVehicularFiltro(_opcionesVehiculo[i].valor);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 18),
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white.withAlpha((0.22 * 255).toInt())),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comercios GO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 2),
                Text(
                  'Descuentos cerca de ti',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withAlpha((0.22 * 255).toInt()), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

class _OpcionVehiculo {
  final String valor;
  final String etiqueta;
  final IconData icono;

  const _OpcionVehiculo(this.valor, this.etiqueta, this.icono);
}

/// Píldora de la fila de categorías (reemplaza al ChoiceChip de Material, que dibujaba su propio check y borde).
class _PildoraFiltro extends StatelessWidget {
  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;

  const _PildoraFiltro({super.key, required this.texto, required this.seleccionada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionada ? _comercioAccent : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: seleccionada ? _comercioAccent : Colors.grey.shade300),
          ),
          child: Text(
            texto,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: seleccionada ? Colors.white : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

/// Opción de tipo de vehículo del panel de filtros: ícono grande y nombre, resaltada cuando es la elegida.
class _TarjetaVehiculo extends StatelessWidget {
  final _OpcionVehiculo opcion;
  final bool seleccionada;
  final VoidCallback onTap;

  const _TarjetaVehiculo({super.key, required this.opcion, required this.seleccionada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = seleccionada ? _comercioAccent : Colors.grey.shade700;
    return Material(
      color: seleccionada ? _comercioAccent.withAlpha((0.1 * 255).toInt()) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: seleccionada ? _comercioAccent : Colors.grey.shade200, width: seleccionada ? 1.5 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(opcion.icono, size: 26, color: color),
              const SizedBox(height: 6),
              Text(
                opcion.etiqueta,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
