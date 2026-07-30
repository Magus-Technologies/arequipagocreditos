import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import 'conductor_estado_page.dart';

/// Confirmación del pre-registro enviado desde el app.
///
/// Todo el contenido tiene que entrar en una pantalla: si la persona tiene que
/// scrollear para encontrar los botones, la pantalla falló. Los tamaños se
/// escalan segun el alto disponible ([_escala]) en vez de ser fijos, asi entra
/// tanto en un equipo chico como en uno grande.
class ConductorRegisterSuccessPage extends StatelessWidget {
  final int? conductorId;

  const ConductorRegisterSuccessPage({super.key, this.conductorId});

  static const Color _verde = Color(0xFF22C55E);
  static const Color _verdeTexto = Color(0xFF16A34A);
  static const Color _navy = Color(0xFF16233C);

  /// Alto que necesita el diseño a tamaño natural.
  static const double _altoBase = 700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          const Positioned.fill(child: _FondoDecorativo()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final f = (constraints.maxHeight / _altoBase).clamp(0.68, 1.0);

                return Padding(
                  padding: EdgeInsets.fromLTRB(24, 8 * f, 24, 12 * f),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'images/credigo_logo.svg',
                        height: 58 * f,
                      ),
                      SizedBox(height: 5 * f),
                      Text(
                        'así fácil, así de rápido, así de go',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12 * f,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(flex: 2),
                      _CheckConDestellos(escala: f),
                      SizedBox(height: 18 * f),
                      Text(
                        '¡Se envió tu\nsolicitud de registro!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25 * f,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12 * f),
                      Text(
                        'Hemos recibido tu información\ncorrectamente. Nuestro equipo\nla está revisando.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14 * f,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 18 * f),
                      _buildTarjetaEstado(f),
                      const Spacer(flex: 3),
                      _buildBoton(
                        alto: 52 * f,
                        icono: Icons.home_rounded,
                        texto: 'Volver al inicio',
                        escala: f,
                        onTap: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                      ),
                      SizedBox(height: 10 * f),
                      _buildBoton(
                        alto: 52 * f,
                        icono: Icons.find_in_page_outlined,
                        texto: 'Ver el resultado',
                        escala: f,
                        primario: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ConductorEstadoPage(conductorId: conductorId),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoton({
    required double alto,
    required IconData icono,
    required String texto,
    required double escala,
    required VoidCallback onTap,
    bool primario = true,
  }) {
    final label = Text(
      texto,
      style: TextStyle(fontSize: 15 * escala, fontWeight: FontWeight.bold),
    );
    final icon = Icon(icono, size: 20 * escala);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return SizedBox(
      width: double.infinity,
      // Los botones nunca bajan del minimo tocable, por chica que sea la pantalla.
      height: math.max(alto, 46),
      child: primario
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: icon,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: forma,
              ),
              label: label,
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: icon,
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(color: _navy, width: 1.6),
                shape: forma,
              ),
              label: label,
            ),
    );
  }

  Widget _buildTarjetaEstado(double f) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * f),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 13 * f),
            child: Row(
              children: [
                _buildIconoCircular(
                  f,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 21 * f, color: Colors.grey.shade800),
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 12 * f,
                          height: 12 * f,
                          decoration: const BoxDecoration(
                            color: _verde,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded,
                              size: 8 * f, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12 * f),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de tu solicitud',
                        style: TextStyle(
                          fontSize: 14 * f,
                          fontWeight: FontWeight.bold,
                          color: _verdeTexto,
                        ),
                      ),
                      SizedBox(height: 6 * f),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9 * f,
                          vertical: 4 * f,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13 * f, color: const Color(0xFFB45309)),
                            SizedBox(width: 4 * f),
                            Text(
                              'En revisión',
                              style: TextStyle(
                                fontSize: 12 * f,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade700,
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
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 13 * f),
            child: Row(
              children: [
                _buildIconoCircular(
                  f,
                  child: Icon(Icons.schedule_rounded,
                      size: 21 * f, color: Colors.grey.shade800),
                ),
                SizedBox(width: 12 * f),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiempo estimado de revisión:',
                        style: TextStyle(
                          fontSize: 12 * f,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 2 * f),
                      Text(
                        '30 minutos a 2 horas.',
                        style: TextStyle(
                          fontSize: 14 * f,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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

  Widget _buildIconoCircular(double f, {required Widget child}) {
    return Container(
      width: 44 * f,
      height: 44 * f,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}

/// Check de confirmación: aro blanco con borde verde y destellos alrededor.
class _CheckConDestellos extends StatelessWidget {
  final double escala;

  const _CheckConDestellos({required this.escala});

  @override
  Widget build(BuildContext context) {
    final circulo = 126 * escala;

    return SizedBox(
      width: 200 * escala,
      height: 152 * escala,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DestellosPainter(escala: escala)),
          ),
          Container(
            width: circulo,
            height: circulo,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: ConductorRegisterSuccessPage._verde,
                width: 5 * escala,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.check_rounded,
                size: 72 * escala,
                color: ConductorRegisterSuccessPage._verde,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rayas cortas que irradian del círculo, tres por lado.
class _DestellosPainter extends CustomPainter {
  final double escala;

  const _DestellosPainter({required this.escala});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = ConductorRegisterSuccessPage._verde
      ..strokeWidth = 5 * escala
      ..strokeCap = StrokeCap.round;

    // Ángulos en grados: tres a cada lado del círculo.
    const angulos = <double>[148, 180, 212, 328, 0, 32];
    final radioInterno = 75 * escala;

    for (final grados in angulos) {
      final rad = grados * math.pi / 180;
      // Las rayas horizontales son más cortas que las diagonales.
      final largo = (grados == 180 || grados == 0) ? 14 * escala : 21 * escala;
      final dx = math.cos(rad);
      final dy = math.sin(rad);
      canvas.drawLine(
        centro + Offset(dx * radioInterno, dy * radioInterno),
        centro +
            Offset(dx * (radioInterno + largo), dy * (radioInterno + largo)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DestellosPainter oldDelegate) =>
      oldDelegate.escala != escala;
}

/// Círculos sutiles del fondo, como en el diseño de marca.
class _FondoDecorativo extends StatelessWidget {
  const _FondoDecorativo();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -60, right: -50, child: _aro(180, 14)),
          Positioned(top: 120, left: -70, child: _aro(140, 12)),
          Positioned(bottom: -40, right: -30, child: _aro(150, 12)),
        ],
      ),
    );
  }

  Widget _aro(double tamano, double grosor) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: grosor,
        ),
      ),
    );
  }
}
