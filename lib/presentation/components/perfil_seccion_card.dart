import 'package:flutter/material.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

/// Tarjeta de una sección del perfil: título con su ícono (y un botón opcional a la derecha) y debajo las filas, separadas por una
/// línea fina. Todas las secciones del perfil (información personal, vehículo, pre-registro) usan esta misma tarjeta para verse igual.
class PerfilSeccionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;
  final Widget? trailing;

  /// Una línea pequeña bajo el título (p. ej. cómo funciona la sección).
  final String? subtitulo;

  const PerfilSeccionCard({
    super.key,
    required this.titulo,
    required this.icono,
    required this.children,
    this.trailing,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icono, size: 17, color: Colors.black87),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 8),
            Text(subtitulo!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.3)),
          ],
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// «2026-11-25» → «25/11/2026». Si no es una fecha reconocible se devuelve tal cual (y vacío → «No disponible»).
String fechaLegible(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'No disponible';

  final fecha = DateTime.tryParse(texto);
  if (fecha == null) return texto;

  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year.toString().padLeft(4, '0')}';
}

/// Estado de un documento del vehículo según su fecha de vencimiento.
enum EstadoVencimiento { vencido, porVencer, vigente }

/// `null` si la fecha no se puede leer (entonces no se muestra ningún aviso). «Por vencer» = vence dentro de los próximos 30 días.
EstadoVencimiento? estadoVencimiento(String? valor, {DateTime? hoy}) {
  final fecha = DateTime.tryParse(valor?.trim() ?? '');
  if (fecha == null) return null;

  final ahora = hoy ?? DateTime.now();
  final dias = DateTime(fecha.year, fecha.month, fecha.day).difference(DateTime(ahora.year, ahora.month, ahora.day)).inDays;

  if (dias < 0) return EstadoVencimiento.vencido;
  if (dias <= 30) return EstadoVencimiento.porVencer;
  return EstadoVencimiento.vigente;
}

/// Etiqueta de color del estado de un documento («Vencido», «Por vencer», «Vigente»).
class EtiquetaVencimiento extends StatelessWidget {
  final EstadoVencimiento estado;

  const EtiquetaVencimiento({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (texto, fondo, color) = switch (estado) {
      EstadoVencimiento.vencido => ('Vencido', Colors.red.shade50, Colors.red.shade700),
      EstadoVencimiento.porVencer => ('Por vencer', Colors.amber.shade50, Colors.amber.shade900),
      EstadoVencimiento.vigente => ('Vigente', Colors.green.shade50, Colors.green.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(texto, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
