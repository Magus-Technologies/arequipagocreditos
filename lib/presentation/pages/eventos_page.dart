import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/evento_formato.dart';
import '../../data/models/evento_models.dart';
import '../../theme/app_theme.dart';
import '../providers/evento_provider.dart';
import 'evento_detalle_page.dart';
import 'evento_mis_tickets_page.dart';

/// «Eventos»: los próximos y los ya realizados, cada uno con su banner, fecha y lugar. Tocar uno abre su detalle (y ahí, si es el
/// evento en venta, se compra). Arriba a la derecha queda el acceso a «Mis tickets».
///
/// La lista es pública (no depende de la sesión). Jalar hacia abajo la vuelve a pedir.
class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EventoProvider>().cargarLista();
    });
  }

  Future<void> _recargar() => context.read<EventoProvider>().cargarLista();

  void _abrir(EventoModel evento, {required bool realizado}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventoDetallePage(evento: evento, realizado: realizado)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: AppTheme.brandYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('Eventos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              key: const Key('eventos_mis_tickets'),
              tooltip: 'Mis tickets',
              icon: const Icon(Icons.confirmation_number_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventoMisTicketsPage()),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(key: Key('eventos_tab_proximos'), text: 'Próximos'),
              Tab(key: Key('eventos_tab_realizados'), text: 'Realizados'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Consumer<EventoProvider>(
            builder: (context, provider, _) {
              final lista = provider.lista;
              if (lista == null) {
                if (provider.errorLista != null && !provider.cargandoLista) return _error(provider.errorLista!);
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(
                children: [
                  _pestana(
                    eventos: lista.proximos,
                    realizado: false,
                    vacio: const _Vacio(
                      key: Key('eventos_vacio_proximos'),
                      icono: Icons.event_available_outlined,
                      titulo: 'No hay próximos eventos por ahora',
                      detalle: 'Cuando haya uno nuevo lo verás aquí.',
                    ),
                  ),
                  _pestana(
                    eventos: lista.anteriores,
                    realizado: true,
                    vacio: const _Vacio(
                      key: Key('eventos_vacio_realizados'),
                      icono: Icons.history_rounded,
                      titulo: 'Aún no hay eventos realizados',
                      detalle: 'Los eventos que ya pasaron aparecerán aquí.',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pestana({required List<EventoModel> eventos, required bool realizado, required Widget vacio}) {
    return RefreshIndicator(
      onRefresh: _recargar,
      child: eventos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              children: [vacio],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: eventos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => EventoListaTarjeta(
                evento: eventos[index],
                realizado: realizado,
                onTap: () => _abrir(eventos[index], realizado: realizado),
              ),
            ),
    );
  }

  Widget _error(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(mensaje, key: const Key('eventos_error'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('eventos_reintentar'),
              onPressed: _recargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _Vacio({super.key, required this.icono, required this.titulo, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 16),
      child: Column(
        children: [
          Icon(icono, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(detalle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// Tarjeta de un evento en la lista: banner con la fecha en una insignia, nombre, fecha y hora, lugar y precio. Los ya realizados
/// se ven en gris y con la marca «Realizado».
class EventoListaTarjeta extends StatelessWidget {
  final EventoModel evento;
  final bool realizado;
  final VoidCallback onTap;

  const EventoListaTarjeta({super.key, required this.evento, required this.realizado, required this.onTap});

  static const ColorFilter _grises = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final fecha = EventoFormato.fechaHora(evento.fechaHora);

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('evento_lista_${evento.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _banner(),
                if (evento.fechaHora != null) Positioned(top: 12, left: 12, child: _insigniaFecha(evento.fechaHora!)),
                if (realizado)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                      child: const Text(
                        'REALIZADO',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2),
                        ),
                        if (fecha.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _linea(Icons.calendar_month_rounded, fecha),
                        ],
                        if (evento.lugar != null) ...[
                          const SizedBox(height: 3),
                          _linea(Icons.place_rounded, evento.lugar!),
                        ],
                        if (!realizado && evento.precioTicket > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${EventoFormato.monto(evento.precioTicket)} por ticket',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(IconData icono, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.25))),
      ],
    );
  }

  Widget _insigniaFecha(DateTime fecha) {
    final (:dia, :mes) = EventoFormato.diaYMes(fecha);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dia, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1)),
          Text(mes, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _banner() {
    final url = evento.bannerUrl;
    final Widget imagen = url == null
        ? _sinImagen()
        : CachedNetworkImage(
            imageUrl: url,
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: 900,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (context, url) => Container(height: 170, color: Colors.grey.shade200),
            errorWidget: (context, url, error) => _sinImagen(),
          );

    return SizedBox(
      height: 170,
      width: double.infinity,
      child: realizado ? ColorFiltered(colorFilter: _grises, child: imagen) : imagen,
    );
  }

  /// Sin banner (o si no carga) la tarjeta sigue siendo útil: un fondo de la marca con el ícono de fiesta.
  Widget _sinImagen() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE867), AppTheme.primary],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.celebration_rounded, size: 56, color: Colors.black87),
    );
  }
}
