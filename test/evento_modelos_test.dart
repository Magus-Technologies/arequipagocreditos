import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/core/utils/evento_formato.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'helpers/evento_fakes.dart';

// Eventos (tickets del 3er Aniversario): el servidor manda el evento activo y las compras de la persona. Los decimales pueden llegar
// como número o como texto ("50.00") y cualquier campo opcional como null: el app lee con tolerancia y no se cae por un dato ausente.

void main() {
  group('EventoModel.fromJson', () {
    test('lee todos los campos del contrato', () {
      final e = EventoModel.fromJson(eventoJson());

      expect(e.id, 7);
      expect(e.nombre, '3er Aniversario Arequipa Go');
      expect(e.lugar, 'Local de la empresa');
      expect(e.bannerUrl, 'https://credigo.test/storage/eventos/banners/aniversario.webp');
      expect(e.precioTicket, 50.0);
      expect(e.maxTicketsPorPersona, 4);
      expect(e.terminos, contains('\n')); // los saltos de línea se conservan
      expect(e.politicaPrivacidad, startsWith('Tus datos'));
      expect(e.misTickets?.comprados, 1);
      expect(e.misTickets?.disponibles, 3);
      expect(e.fechaHora!.isAtSameMomentAs(DateTime.utc(2026, 11, 14, 19)), isTrue); // 2:00 p. m. en Lima = 19:00 UTC
    });

    test('el precio llega como número o como texto', () {
      expect(EventoModel.fromJson(eventoJson(precio: 50)).precioTicket, 50.0);
      expect(EventoModel.fromJson(eventoJson(precio: 49.9)).precioTicket, 49.9);
      expect(EventoModel.fromJson(eventoJson(precio: '35.50')).precioTicket, 35.5);
    });

    test('un precio ausente o ilegible queda en 0 sin lanzar', () {
      expect(EventoModel.fromJson(eventoJson(precio: null)).precioTicket, 0);
      expect(EventoModel.fromJson(eventoJson(precio: 'abc')).precioTicket, 0);
    });

    test('sin mis_tickets (id y DNI no coinciden) el campo queda en null', () {
      expect(EventoModel.fromJson(eventoJson(mis: null)).misTickets, isNull);
    });

    test('tolera todos los opcionales en null', () {
      final e = EventoModel.fromJson({
        'id': 9,
        'nombre': 'Evento',
        'descripcion': null,
        'lugar': null,
        'fecha_hora': null,
        'banner_url': null,
        'precio_ticket': null,
        'max_tickets_por_persona': null,
        'terminos': null,
        'politica_privacidad': null,
        'mis_tickets': null,
      });

      expect(e.id, 9);
      expect(e.lugar, isNull);
      expect(e.fechaHora, isNull);
      expect(e.bannerUrl, isNull);
      expect(e.terminos, isNull);
      expect(e.maxTicketsPorPersona, 0);
    });

    test('un banner relativo se completa con el host del backend', () {
      final e = EventoModel.fromJson({...eventoJson(), 'banner_url': '/storage/eventos/banners/a.webp'});

      expect(e.bannerUrl, endsWith('/storage/eventos/banners/a.webp'));
      expect(e.bannerUrl, startsWith('http'));
    });
  });

  group('EventoCompraModel.fromJson', () {
    test('lee todos los campos del contrato', () {
      final c = EventoCompraModel.fromJson(compraJson());

      expect(c.id, 31);
      expect(c.codigo, 'EV-K7M2QX');
      expect(c.eventoId, 7);
      expect(c.eventoNombre, '3er Aniversario Arequipa Go');
      expect(c.cantidad, 2);
      expect(c.precioUnitario, 50.0);
      expect(c.montoTotal, 100.0);
      expect(c.qrUrl, 'https://credigo.test/storage/eventos/qr/qr.png');
      expect(c.puedeSubirCaptura, isTrue);
      expect(c.puedeCancelar, isTrue);
      expect(c.creadoEn, isNotNull);
    });

    test('precios como texto o como número dan el mismo resultado', () {
      final texto = EventoCompraModel.fromJson(compraJson(precioUnitario: '25.50', montoTotal: '51.00'));
      final numero = EventoCompraModel.fromJson(compraJson(precioUnitario: 25.5, montoTotal: 51));

      expect(texto.precioUnitario, 25.5);
      expect(texto.montoTotal, 51.0);
      expect(numero.precioUnitario, texto.precioUnitario);
      expect(numero.montoTotal, texto.montoTotal);
    });

    test('los booleanos tolerantes: 1/0, "1"/"0", true/false', () {
      final c1 = EventoCompraModel.fromJson(compraJson(puedeSubir: 1, puedeCancelar: '1'));
      final c0 = EventoCompraModel.fromJson(compraJson(puedeSubir: 0, puedeCancelar: false));
      final nulos = EventoCompraModel.fromJson(compraJson(puedeSubir: null, puedeCancelar: null));

      expect(c1.puedeSubirCaptura, isTrue);
      expect(c1.puedeCancelar, isTrue);
      expect(c0.puedeSubirCaptura, isFalse);
      expect(c0.puedeCancelar, isFalse);
      expect(nulos.puedeSubirCaptura, isFalse);
      expect(nulos.puedeCancelar, isFalse);
    });

    test('tolera captura, motivo y fechas en null', () {
      final c = EventoCompraModel.fromJson({
        'id': 1,
        'codigo': null,
        'evento_id': 7,
        'evento_nombre': null,
        'fecha_hora_evento': null,
        'cantidad': 1,
        'precio_unitario': null,
        'monto_total': null,
        'estado': 'pendiente',
        'motivo_rechazo': null,
        'captura_url': null,
        'qr_url': null,
        'puede_subir_captura': true,
        'puede_cancelar': true,
        'creado_en': null,
      });

      expect(c.codigo, '');
      expect(c.capturaUrl, isNull);
      expect(c.qrUrl, isNull);
      expect(c.tieneCaptura, isFalse);
      expect(c.motivoRechazo, isNull);
      expect(c.fechaHoraEvento, isNull);
      expect(c.montoTotal, 0);
    });
  });

  group('estado de la compra', () {
    test('cada estado del contrato se reconoce, sin importar mayúsculas', () {
      expect(EventoCompraModel.fromJson(compraJson(estado: 'pendiente')).estadoCompra, EstadoCompra.pendiente);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'confirmado')).estadoCompra, EstadoCompra.confirmado);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'rechazado')).estadoCompra, EstadoCompra.rechazado);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'anulado')).estadoCompra, EstadoCompra.anulado);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'CONFIRMADO')).estadoCompra, EstadoCompra.confirmado);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'algo-nuevo')).estadoCompra, EstadoCompra.desconocido);
    });

    test('pendiente sin captura dice «Falta subir captura»; con captura, «En revisión»', () {
      final sin = EventoCompraModel.fromJson(compraJson());
      final con = EventoCompraModel.fromJson(compraJson(capturaUrl: 'https://credigo.test/storage/eventos/capturas/c.jpg'));

      expect(sin.etiquetaEstado, 'Falta subir captura');
      expect(con.etiquetaEstado, 'En revisión');
    });

    test('las etiquetas de los estados finales', () {
      expect(EventoCompraModel.fromJson(compraJson(estado: 'confirmado')).etiquetaEstado, 'Confirmado');
      expect(EventoCompraModel.fromJson(compraJson(estado: 'rechazado')).etiquetaEstado, 'Rechazado');
      expect(EventoCompraModel.fromJson(compraJson(estado: 'anulado')).etiquetaEstado, 'Anulado');
      expect(EventoCompraModel.fromJson(compraJson(estado: 'nuevo')).etiquetaEstado, 'Nuevo'); // estado que este app no conoce
    });

    test('pendiente y confirmado ocupan cupo; rechazado y anulado lo liberan', () {
      expect(EventoCompraModel.fromJson(compraJson(estado: 'pendiente')).ocupaCupo, isTrue);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'confirmado')).ocupaCupo, isTrue);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'rechazado')).ocupaCupo, isFalse);
      expect(EventoCompraModel.fromJson(compraJson(estado: 'anulado')).ocupaCupo, isFalse);
    });

    test('el motivo de rechazo se conserva', () {
      final c = EventoCompraModel.fromJson(compraJson(estado: 'rechazado', motivo: 'El monto no coincide'));

      expect(c.motivoRechazo, 'El monto no coincide');
    });
  });

  group('formato', () {
    // Instantes en UTC: nada de lo de abajo depende de la zona horaria de la máquina que corre las pruebas.
    test('fecha y hora en español, en hora de Lima (UTC-5)', () {
      expect(EventoFormato.fechaHora(DateTime.utc(2026, 11, 14, 19)), 'Sábado 14 de noviembre · 2:00 p. m.');
      expect(EventoFormato.fechaHora(DateTime.utc(2026, 11, 14, 5, 5)), 'Sábado 14 de noviembre · 12:05 a. m.');
      expect(EventoFormato.fechaHora(DateTime.utc(2026, 12, 1, 17, 30)), 'Martes 1 de diciembre · 12:30 p. m.');
      expect(EventoFormato.fechaHora(null), '');
    });

    test('un instante cerca de la medianoche cae en el día de Lima, no en el del servidor', () {
      // 02:00 UTC del domingo 15 = 9:00 p. m. del sábado 14 en Lima.
      expect(EventoFormato.fechaHora(DateTime.utc(2026, 11, 15, 2)), 'Sábado 14 de noviembre · 9:00 p. m.');
    });

    test('el mismo instante se ve igual venga con el offset de Lima, con «Z» o con el de otro país', () {
      const esperado = 'Sábado 14 de noviembre · 2:00 p. m.';

      for (final texto in ['2026-11-14T14:00:00-05:00', '2026-11-14T19:00:00Z', '2026-11-15T04:00:00+09:00']) {
        final e = EventoModel.fromJson({...eventoJson(), 'fecha_hora': texto});
        expect(EventoFormato.fechaHora(e.fechaHora), esperado, reason: texto);
      }
    });

    test('una fecha sin offset se entiende como hora de Lima', () {
      final e = EventoModel.fromJson({...eventoJson(), 'fecha_hora': '2026-11-14 14:00:00'});

      expect(EventoFormato.fechaHora(e.fechaHora), 'Sábado 14 de noviembre · 2:00 p. m.');
      expect(e.fechaHora!.isAtSameMomentAs(DateTime.utc(2026, 11, 14, 19)), isTrue);
    });

    test('una fecha local (no UTC) también se convierte con el instante correcto', () {
      // `DateTime.utc(...).toLocal()` es el mismo instante visto desde la zona del teléfono: da igual cuál sea.
      final local = DateTime.utc(2026, 11, 14, 19).toLocal();

      expect(EventoFormato.fechaHora(local), 'Sábado 14 de noviembre · 2:00 p. m.');
    });

    test('monto y cantidad de tickets', () {
      expect(EventoFormato.monto(50), 'S/ 50.00');
      expect(EventoFormato.monto(35.5), 'S/ 35.50');
      expect(EventoFormato.tickets(1), '1 ticket');
      expect(EventoFormato.tickets(3), '3 tickets');
    });
  });
}
