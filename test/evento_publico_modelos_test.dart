import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arequipagocreditos/core/constants/app_constants.dart';
import 'package:arequipagocreditos/data/models/evento_invitado.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'helpers/evento_fakes.dart';

// TK-0450: eventos PÚBLICOS (los ve y los compra cualquiera, como invitado) y PRIVADOS (solo clientes GO con sesión). Aquí: cómo se lee la
// visibilidad, los datos del invitado (normalización y reglas del formulario) y su almacenamiento en el celular.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('visibilidad del evento', () {
    test('«privado» es privado, sin importar mayúsculas ni espacios', () {
      for (final valor in ['privado', 'PRIVADO', ' Privado ']) {
        final e = evento(visibilidad: valor);
        expect(e.visibilidad, EventoVisibilidad.privado, reason: valor);
        expect(e.esPrivado, isTrue);
      }
    });

    test('«publico», cualquier otra cosa o que no venga (servidor anterior) es público', () {
      for (final valor in ['publico', 'PÚBLICO', 'otra-cosa', '']) {
        expect(evento(visibilidad: valor).esPrivado, isFalse, reason: valor);
      }
      expect(evento().visibilidad, EventoVisibilidad.publico);
      expect(EventoModel.fromJson({'id': 1, 'nombre': 'Sin dato', 'visibilidad': null}).esPrivado, isFalse);
    });

    test('al actualizar su cupo (copyWith) el evento conserva su visibilidad', () {
      final privado = evento(visibilidad: 'privado', comprados: 0);

      final conCupo = privado.copyWith(misTickets: const MisTicketsModel(comprados: 2, disponibles: 2));

      expect(conCupo.esPrivado, isTrue);
      expect(conCupo.misTickets?.disponibles, 2);
    });

    test('la lista lee la visibilidad de cada evento', () {
      final lista = EventosListaModel.fromJson({
        'proximos': [
          {'id': 1, 'nombre': 'Abierto', 'visibilidad': 'publico'},
          {'id': 2, 'nombre': 'Solo GO', 'visibilidad': 'privado'},
        ],
        'anteriores': [
          {'id': 3, 'nombre': 'Pasado privado', 'visibilidad': 'privado'},
        ],
      });

      expect(lista.proximos.map((e) => e.esPrivado), [false, true]);
      expect(lista.anteriores.single.esPrivado, isTrue);
    });
  });

  group('datos del invitado', () {
    test('se normalizan: espacios de más fuera, documento en mayúsculas, teléfono solo con dígitos y correo vacío = sin correo', () {
      final i = EventoInvitado.normalizado(
        nombre: '  Ana   María  Pérez ',
        documento: ' ab12345c ',
        telefono: '(054) 123-456',
        correo: '   ',
      );

      expect(i.nombre, 'Ana María Pérez');
      expect(i.documento, 'AB12345C');
      expect(i.telefono, '054123456');
      expect(i.correo, isNull);
    });

    test('un teléfono con «+» lo conserva solo al inicio', () {
      expect(EventoInvitadoValidador.limpiarTelefono('+51 959 123 456'), '+51959123456');
      expect(EventoInvitadoValidador.limpiarTelefono('959-123-456'), '959123456');
    });

    test('va y viene del JSON que se guarda en el celular', () {
      const original = EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456', correo: 'ana@correo.pe');

      expect(EventoInvitado.fromJson(original.toJson()), original);
      expect(EventoInvitado.fromJson({'documento': '43373493', 'telefono': '959123456'}).correo, isNull);
    });

    test('con nombre, documento y teléfono válidos puede comprar; con solo documento y teléfono, consultar', () {
      expect(const EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456').puedeComprar, isTrue);

      const soloConsulta = EventoInvitado(nombre: '', documento: '43373493', telefono: '959123456');
      expect(soloConsulta.puedeComprar, isFalse);
      expect(soloConsulta.puedeConsultar, isTrue);

      expect(const EventoInvitado(nombre: 'Ana', documento: '123', telefono: '959123456').puedeConsultar, isFalse);
    });
  });

  group('reglas del formulario (las mismas del servidor)', () {
    test('nombre: obligatorio, de 3 a 200 caracteres', () {
      expect(EventoInvitadoValidador.nombre(null), 'Escribe tu nombre completo.');
      expect(EventoInvitadoValidador.nombre('   '), 'Escribe tu nombre completo.');
      expect(EventoInvitadoValidador.nombre('Al'), contains('muy corto'));
      expect(EventoInvitadoValidador.nombre('A' * 201), contains('muy largo'));
      expect(EventoInvitadoValidador.nombre('Ana Pérez'), isNull);
    });

    test('documento: obligatorio, de 6 a 15 letras o números sin espacios', () {
      expect(EventoInvitadoValidador.documento(''), contains('DNI'));
      expect(EventoInvitadoValidador.documento('12345'), contains('entre 6 y 15'));
      expect(EventoInvitadoValidador.documento('1234567890123456'), contains('entre 6 y 15'));
      expect(EventoInvitadoValidador.documento('4337 3493'), contains('entre 6 y 15'));
      expect(EventoInvitadoValidador.documento('43373493'), isNull);
      expect(EventoInvitadoValidador.documento('CE123456'), isNull);
    });

    test('celular: obligatorio, de 7 a 15 dígitos (admite +, espacios y guiones)', () {
      expect(EventoInvitadoValidador.telefono(''), contains('celular'));
      expect(EventoInvitadoValidador.telefono('12345'), contains('entre 7 y 15'));
      expect(EventoInvitadoValidador.telefono('1234567890123456'), contains('entre 7 y 15'));
      expect(EventoInvitadoValidador.telefono('959123456'), isNull);
      expect(EventoInvitadoValidador.telefono('+51 959-123-456'), isNull);
    });

    test('correo: opcional; si lo escribe tiene que ser válido', () {
      expect(EventoInvitadoValidador.correo(null), isNull);
      expect(EventoInvitadoValidador.correo('  '), isNull);
      expect(EventoInvitadoValidador.correo('ana@correo'), contains('correo válido'));
      expect(EventoInvitadoValidador.correo('ana correo.pe'), contains('correo válido'));
      expect(EventoInvitadoValidador.correo('ana@correo.pe'), isNull);
    });
  });

  group('almacenamiento en el celular', () {
    const almacen = EventoInvitadoAlmacenLocal();

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('guarda, lee y borra los datos', () async {
      expect(await almacen.leer(), isNull);

      const datos = EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456', correo: 'ana@correo.pe');
      await almacen.guardar(datos);
      expect(await almacen.leer(), datos);

      await almacen.borrar();
      expect(await almacen.leer(), isNull);
    });

    test('quien solo consultó sus tickets (sin nombre) también queda guardado', () async {
      const soloConsulta = EventoInvitado(nombre: '', documento: '43373493', telefono: '959123456');
      await almacen.guardar(soloConsulta);

      expect(await almacen.leer(), soloConsulta);
    });

    test('un dato guardado ilegible o incompleto se trata como «no hay datos», sin lanzar', () async {
      SharedPreferences.setMockInitialValues({AppConstants.eventoInvitadoKey: '{esto no es json'});
      expect(await almacen.leer(), isNull);

      SharedPreferences.setMockInitialValues({AppConstants.eventoInvitadoKey: '{"nombre":"Ana","documento":"1","telefono":"2"}'});
      expect(await almacen.leer(), isNull);
    });
  });
}
