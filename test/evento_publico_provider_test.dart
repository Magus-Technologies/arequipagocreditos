import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/evento_invitado.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// TK-0450: la lógica de quien compra un evento PÚBLICO sin cuenta (invitado), sin servidor: sus datos, el tope, el bloqueo de los
// eventos privados, el olvido de datos y que no se mezcle con la persona que sí inició sesión.

final File _captura = File('captura.jpg');

const _ana = EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456', correo: 'ana@correo.pe');
const _luis = EventoInvitado(nombre: 'Luis Ramos', documento: '70112233', telefono: '987654321');

EventoProvider _provider(FakeEventoRepository repo, [AlmacenInvitadoEnMemoria? almacen]) =>
    EventoProvider(repository: repo, ahora: () => ahoraDePrueba, almacenInvitado: almacen ?? AlmacenInvitadoEnMemoria());

/// Un invitado que ya abrió el evento público y dio sus datos: listo para comprar.
Future<EventoProvider> _listoParaComprar(
  FakeEventoRepository repo, {
  AlmacenInvitadoEnMemoria? almacen,
  EventoInvitado datos = _ana,
}) async {
  final provider = _provider(repo, almacen);
  await provider.cargarEventoPublico(7);
  await provider.identificarInvitado(datos);
  return provider;
}

void main() {
  group('datos del invitado', () {
    test('al identificarlo se quedan guardados en el celular y el provider pasa a modo invitado', () async {
      final almacen = AlmacenInvitadoEnMemoria();
      final provider = _provider(FakeEventoRepository(), almacen);

      await provider.identificarInvitado(_ana);

      expect(provider.invitado, _ana);
      expect(provider.modoInvitado, isTrue);
      expect(almacen.guardado, _ana);
    });

    test('con guardar:false se usan en esta compra pero no se recuerdan', () async {
      final almacen = AlmacenInvitadoEnMemoria();
      final provider = _provider(FakeEventoRepository(), almacen);

      await provider.identificarInvitado(_ana, guardar: false);

      expect(provider.invitado, _ana);
      expect(almacen.guardado, isNull);
    });

    test('al abrir el app se restauran los datos guardados (una sola vez) y se avisa a las pantallas', () async {
      final almacen = AlmacenInvitadoEnMemoria(_ana);
      final provider = _provider(FakeEventoRepository(), almacen);
      var avisos = 0;
      provider.addListener(() => avisos++);

      await provider.restaurarInvitado();
      await provider.restaurarInvitado();

      expect(provider.invitado, _ana);
      expect(avisos, 1);
      // Restaurar los datos no lo mete en modo invitado: eso pasa solo al abrir un evento o sus tickets.
      expect(provider.modoInvitado, isFalse);
    });

    test('restaurar no pisa a un invitado que ya escribió sus datos mientras tanto', () async {
      final almacen = AlmacenInvitadoEnMemoria(_ana);
      final provider = _provider(FakeEventoRepository(), almacen);

      await provider.identificarInvitado(_luis, guardar: false);
      await provider.restaurarInvitado();

      expect(provider.invitado, _luis);
    });

    test('«No soy yo · borrar mis datos» los quita del celular y deja de mostrar sus compras', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra()]);
      final almacen = AlmacenInvitadoEnMemoria();
      final provider = await _listoParaComprar(repo, almacen: almacen);
      await provider.cargarMisComprasInvitado();
      expect(provider.compras, hasLength(1));

      await provider.olvidarInvitado();

      expect(provider.invitado, isNull);
      expect(provider.compras, isEmpty);
      expect(almacen.guardado, isNull);
      expect(almacen.borrados, 1);
    });

    test('si el celular no puede guardar o leer, no se rompe nada', () async {
      final provider = EventoProvider(
        repository: FakeEventoRepository(),
        almacenInvitado: _AlmacenQueFalla(),
      );

      await provider.restaurarInvitado();
      await provider.identificarInvitado(_ana);
      await provider.olvidarInvitado();

      expect(provider.invitado, isNull);
    });

    test('cambiar a otra persona descarta las compras de la anterior', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra()]);
      final provider = await _listoParaComprar(repo);
      await provider.cargarMisComprasInvitado();
      expect(provider.compras, hasLength(1));

      await provider.identificarInvitado(_luis);

      expect(provider.compras, isEmpty);
    });

    test('volver a dar los mismos datos conserva sus compras', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra()]);
      final provider = await _listoParaComprar(repo);
      await provider.cargarMisComprasInvitado();

      await provider.identificarInvitado(_ana);

      expect(provider.compras, hasLength(1));
    });
  });

  group('evento público', () {
    test('carga el evento completo (QR de pago incluido) sin identificar a nadie', () async {
      final repo = FakeEventoRepository()..publico = [Either.right(evento())];
      final provider = _provider(repo);

      await provider.cargarEventoPublico(7);

      expect(repo.ultimoEventoPublico, 7);
      expect(provider.evento?.qrUrl, isNotNull);
      expect(provider.modoInvitado, isTrue);
      expect(provider.puedeComprar, isTrue);
      expect(provider.ticketsDisponibles, 4);
    });

    test('un error de red deja el evento que ya se tenía; «no disponible» (null) lo quita', () async {
      final repo = FakeEventoRepository()
        ..publico = [
          Either.right(evento()),
          Either.left(const ServerFailure('sin conexión')),
          Either.right(null),
        ];
      final provider = _provider(repo);

      await provider.cargarEventoPublico(7);
      await provider.cargarEventoPublico(7);
      expect(provider.evento, isNotNull);

      await provider.cargarEventoPublico(7);
      expect(provider.evento, isNull);
      expect(provider.puedeComprar, isFalse);
    });

    test('el aviso de la bienvenida pide el evento activo SIN persona (el servidor devuelve solo públicos)', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento())];
      final provider = _provider(repo);

      await provider.cargarActivoPublico();

      expect(provider.eventoPublico?.id, 7);
      expect(repo.ultimaPersonaId, isNull);
      expect(repo.ultimoDocumento, isNull);
    });
  });

  group('comprar como invitado', () {
    test('manda sus datos, la cantidad y la captura; la compra entra a la lista y gasta cupo', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..compraInvitado = Either.right(compra(cantidad: 2));
      final provider = await _listoParaComprar(repo);

      final r = await provider.registrarCompra(2, _captura);

      expect(r.ok, isTrue);
      expect(repo.llamadasRegistrarInvitado, 1);
      expect(repo.llamadasRegistrar, 0); // nunca por el camino de la persona con cuenta
      expect(repo.ultimoInvitado, _ana);
      expect(repo.ultimaCantidadInvitado, 2);
      expect(repo.ultimaCapturaInvitado, _captura);
      expect(provider.compras.map((c) => c.id), [31]);
      expect(provider.enviando, isFalse);
    });

    test('sin sus datos (o con datos incompletos) pide completarlos y no llama al servidor', () async {
      final repo = FakeEventoRepository()..publico = [Either.right(evento())];
      final provider = _provider(repo);
      await provider.cargarEventoPublico(7);

      final sinDatos = await provider.registrarCompra(1, _captura);
      expect(sinDatos.mensaje, 'Completa tus datos para continuar.');

      // Quien solo consultó sus tickets (sin nombre) no puede comprar hasta dar su nombre.
      await provider.identificarInvitado(const EventoInvitado(nombre: '', documento: '43373493', telefono: '959123456'));
      final sinNombre = await provider.registrarCompra(1, _captura);
      expect(sinNombre.mensaje, 'Completa tus datos para continuar.');

      expect(repo.llamadasRegistrarInvitado, 0);
    });

    test('un evento PRIVADO no se compra como invitado: pide iniciar sesión y no llama al servidor', () async {
      final repo = FakeEventoRepository()..publico = [Either.right(evento(visibilidad: 'privado'))];
      final provider = await _listoParaComprar(repo);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isFalse);
      expect(r.mensaje, contains('solo para clientes de Arequipa Go'));
      expect(r.mensaje, contains('Inicia sesión'));
      expect(repo.llamadasRegistrarInvitado, 0);
    });

    test('no deja pedir más tickets que los que le quedan, ni 0', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento(max: 4))]
        ..compraInvitado = Either.right(compra());
      final provider = await _listoParaComprar(repo);

      final demasiados = await provider.registrarCompra(5, _captura);
      expect(demasiados.mensaje, 'Solo puedes comprar 4 tickets más.');

      final ninguno = await provider.registrarCompra(0, _captura);
      expect(ninguno.mensaje, 'Elige al menos 1 ticket.');

      expect(repo.llamadasRegistrarInvitado, 0);
    });

    test('con sus compras ya cargadas, el tope se calcula por documento (lo que ya compró cuenta)', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento(max: 4))]
        ..misComprasInvitado = Either.right([compra(cantidad: 3), compra(id: 32, cantidad: 1, estado: 'rechazado')])
        ..compraInvitado = Either.right(compra(id: 40, cantidad: 1));
      final provider = await _listoParaComprar(repo);
      await provider.cargarMisComprasInvitado();

      // 3 pendientes ocupan cupo; el rechazado lo libera → le queda 1.
      expect(provider.ticketsDisponibles, 1);
      expect((await provider.registrarCompra(2, _captura)).mensaje, 'Solo puedes comprar 1 ticket más.');
      expect((await provider.registrarCompra(1, _captura)).ok, isTrue);

      // Ya llegó al tope.
      expect(provider.puedeComprar, isFalse);
      expect((await provider.registrarCompra(1, _captura)).mensaje, provider.mensajeTope);
    });

    test('si el servidor dice que NO (422: tope por DNI, evento vencido) muestra su mensaje y vuelve a pedir el evento', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento(max: 4)), Either.right(evento(max: 4, comprados: 4))]
        ..compraInvitado = Either.left(const ValidationFailure('Ese documento ya compró el máximo de tickets.'));
      final provider = await _listoParaComprar(repo);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isFalse);
      expect(r.incierto, isFalse);
      expect(r.mensaje, 'Ese documento ya compró el máximo de tickets.');
      expect(repo.llamadasPublico, 2);
      expect(provider.ticketsDisponibles, 0);
    });

    test('si se perdió la respuesta (red) avisa que no se sabe y revisa SUS compras, sin duplicar', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..compraInvitado = Either.left(const NetworkFailure('sin conexión'))
        ..misComprasInvitado = Either.right([compra(cantidad: 2)]);
      final provider = await _listoParaComprar(repo);

      final r = await provider.registrarCompra(2, _captura);

      expect(r.ok, isFalse);
      expect(r.incierto, isTrue);
      expect(r.mensaje, contains('Revisa «Mis tickets»'));
      // La compra sí había llegado: queda en la lista de este invitado (leída con su documento y celular).
      expect(provider.compras, hasLength(1));
      expect(repo.ultimoDocumentoInvitado, '43373493');
      expect(repo.ultimoTelefonoInvitado, '959123456');
      expect(repo.llamadasRegistrarInvitado, 1);
    });

    test('un segundo toque mientras se envía se rechaza (no se duplica la compra)', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..compraInvitado = Either.right(compra());
      final provider = await _listoParaComprar(repo);

      final primera = provider.registrarCompra(1, _captura);
      final segunda = await provider.registrarCompra(1, _captura);
      await primera;

      expect(segunda.mensaje, contains('Ya estamos procesando'));
      expect(repo.llamadasRegistrarInvitado, 1);
    });
  });

  group('sus tickets', () {
    test('cargarMisComprasInvitado usa el documento y el celular guardados', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra(), compra(id: 32, estado: 'confirmado')]);
      final provider = await _listoParaComprar(repo);

      await provider.cargarMisComprasInvitado();

      expect(repo.ultimoDocumentoInvitado, '43373493');
      expect(repo.ultimoTelefonoInvitado, '959123456');
      expect(provider.compras, hasLength(2));
      expect(provider.cargandoCompras, isFalse);
      expect(provider.errorCompras, isNull);
    });

    test('sin datos guardados no hace nada (no llama al servidor)', () async {
      final repo = FakeEventoRepository();
      final provider = _provider(repo);

      await provider.cargarMisComprasInvitado();

      expect(repo.llamadasMisComprasInvitado, 0);
      expect(provider.modoInvitado, isFalse);
    });

    test('un error al cargar deja el mensaje y conserva lo que ya se veía', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra()]);
      final provider = await _listoParaComprar(repo);
      await provider.cargarMisComprasInvitado();

      repo.misComprasInvitado = Either.left(const NetworkFailure('Revisa tu conexión'));
      await provider.cargarMisComprasInvitado();

      expect(provider.errorCompras, 'Revisa tu conexión');
      expect(provider.compras, hasLength(1));
    });

    group('consultar con documento y celular (quien compró en otro celular o borró sus datos)', () {
      test('con tickets: los muestra y deja esos datos guardados (sin nombre)', () async {
        final repo = FakeEventoRepository()..misComprasInvitado = Either.right([compra(), compra(id: 32)]);
        final almacen = AlmacenInvitadoEnMemoria();
        final provider = _provider(repo, almacen);

        final r = await provider.consultarTicketsDeInvitado(documento: ' 43373493 ', telefono: '959-123-456');

        expect(r.ok, isTrue);
        expect(r.data, 2);
        expect(repo.ultimoDocumentoInvitado, '43373493');
        expect(repo.ultimoTelefonoInvitado, '959123456');
        expect(provider.compras, hasLength(2));
        expect(provider.invitado?.documento, '43373493');
        expect(provider.invitado?.nombre, '');
        expect(almacen.guardado?.telefono, '959123456');
      });

      test('si ya tenía sus datos completos (con nombre) no se los pisa', () async {
        final repo = FakeEventoRepository()..misComprasInvitado = Either.right([compra()]);
        final provider = _provider(repo);
        await provider.identificarInvitado(_ana);

        await provider.consultarTicketsDeInvitado(documento: '43373493', telefono: '959123456');

        expect(provider.invitado, _ana);
      });

      test('sin tickets con esos datos: lo dice y NO guarda nada', () async {
        final repo = FakeEventoRepository()..misComprasInvitado = Either.right(const []);
        final almacen = AlmacenInvitadoEnMemoria();
        final provider = _provider(repo, almacen);

        final r = await provider.consultarTicketsDeInvitado(documento: '43373493', telefono: '959123456');

        expect(r.ok, isFalse);
        expect(r.mensaje, contains('No encontramos tickets'));
        expect(provider.invitado, isNull);
        expect(almacen.guardado, isNull);
      });

      test('documento o celular mal escritos se corrigen antes de llamar al servidor', () async {
        final repo = FakeEventoRepository();
        final provider = _provider(repo);

        final documento = await provider.consultarTicketsDeInvitado(documento: '123', telefono: '959123456');
        expect(documento.mensaje, contains('entre 6 y 15'));

        final telefono = await provider.consultarTicketsDeInvitado(documento: '43373493', telefono: '12');
        expect(telefono.mensaje, contains('entre 7 y 15'));

        expect(repo.llamadasMisComprasInvitado, 0);
      });

      test('un error del servidor sale con su mensaje', () async {
        final repo = FakeEventoRepository()..misComprasInvitado = Either.left(const ValidationFailure('Demasiados intentos.'));
        final provider = _provider(repo);

        final r = await provider.consultarTicketsDeInvitado(documento: '43373493', telefono: '959123456');

        expect(r.mensaje, 'Demasiados intentos.');
        expect(provider.enviando, isFalse);
      });
    });
  });

  group('captura, ticket y cancelación del invitado', () {
    test('subir la captura de una compra va por el camino del invitado con su documento y celular', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra()])
        ..capturaInvitado = Either.right(compra(captura: 'https://credigo.test/storage/c.jpg', puedeSubir: false));
      final provider = await _listoParaComprar(repo);
      await provider.cargarMisComprasInvitado();

      final r = await provider.subirCaptura(31, _captura);

      expect(r.ok, isTrue);
      expect(repo.llamadasCapturaInvitado, 1);
      expect(repo.ultimoDocumentoInvitado, '43373493');
      expect(provider.compraPorId(31)?.capturaUrl, 'https://credigo.test/storage/c.jpg');
    });

    test('subir captura sin datos de invitado pide completarlos', () async {
      final repo = FakeEventoRepository()..publico = [Either.right(evento())];
      final provider = _provider(repo);
      await provider.cargarEventoPublico(7);

      final r = await provider.subirCaptura(31, _captura);

      expect(r.mensaje, 'Completa tus datos para continuar.');
      expect(repo.llamadasCapturaInvitado, 0);
    });

    test('el ticket PDF se pide con su documento y celular', () async {
      final repo = FakeEventoRepository()..publico = [Either.right(evento())];
      final provider = await _listoParaComprar(repo);

      final r = await provider.descargarTicketPdf(31);

      expect(r.ok, isTrue);
      expect(repo.llamadasTicketPdfInvitado, 1);
      expect(repo.llamadasTicketPdf, 0);
      expect(repo.ultimaCompraDelTicket, 31);
      expect(repo.ultimoDocumentoInvitado, '43373493');
    });

    test('un error al bajar el ticket (aún sin confirmar) sale con el mensaje del servidor', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..ticketPdf = Either.left(const ValidationFailure('El ticket se habilita cuando confirmemos tu pago.'));
      final provider = await _listoParaComprar(repo);

      final r = await provider.descargarTicketPdf(31);

      expect(r.ok, isFalse);
      expect(r.mensaje, contains('cuando confirmemos tu pago'));
    });

    test('un invitado NO cancela desde el app (se le dice a quién acudir) y no se llama al servidor', () async {
      final repo = FakeEventoRepository()..publico = [Either.right(evento())];
      final provider = await _listoParaComprar(repo);

      final r = await provider.cancelarCompra(31);

      expect(r.ok, isFalse);
      expect(r.mensaje, contains('Comunícate con Arequipa Go'));
      expect(repo.llamadasCancelar, 0);
    });
  });

  group('invitado y persona con sesión no se mezclan', () {
    test('la persona que inicia sesión no hereda el evento ni las compras del invitado', () async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento())]
        ..misComprasInvitado = Either.right([compra()])
        ..activo = [activo(evento(comprados: 0))];
      final provider = await _listoParaComprar(repo);
      await provider.cargarMisComprasInvitado();
      expect(provider.compras, hasLength(1));

      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.modoInvitado, isFalse);
      expect(provider.compras, isEmpty);
      expect(repo.ultimaPersonaId, 601);
      expect(provider.evento, isNotNull);
    });

    test('con sesión las compras van por el camino normal (con cliente_conductor_id), no por el del invitado', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0))]
        ..compra = Either.right(compra());
      final provider = _provider(repo);
      await provider.identificarInvitado(_ana); // el invitado dejó sus datos antes de iniciar sesión
      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isTrue);
      expect(repo.llamadasRegistrar, 1);
      expect(repo.llamadasRegistrarInvitado, 0);
    });

    test('al volver a ver un evento público como invitado se descarta lo de la persona con sesión', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 1))]
        ..misCompras = Either.right([compra(id: 90)])
        ..publico = [Either.right(evento())];
      final provider = _provider(repo);
      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.compras, hasLength(1));

      await provider.cargarEventoPublico(7);

      expect(provider.modoInvitado, isTrue);
      expect(provider.compras, isEmpty);
    });

    test('cerrar sesión (limpiar) saca de la lista los eventos PRIVADOS que había visto la persona', () async {
      final repo = FakeEventoRepository()
        ..lista = Either.right(
          EventosListaModel(
            proximos: [evento(id: 1, visibilidad: 'publico'), evento(id: 2, visibilidad: 'privado')],
            anteriores: [evento(id: 3, visibilidad: 'privado'), evento(id: 4)],
          ),
        );
      final provider = _provider(repo);
      await provider.cargarLista(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.lista?.proximos, hasLength(2));

      provider.limpiar();

      expect(provider.lista?.proximos.map((e) => e.id), [1]);
      expect(provider.lista?.anteriores.map((e) => e.id), [4]);
    });

    test('la lista sin sesión se pide sin persona; con sesión, con su id y documento', () async {
      final repo = FakeEventoRepository();
      final provider = _provider(repo);

      await provider.cargarLista();
      expect(repo.ultimaListaPersonaId, isNull);
      expect(repo.ultimaListaDocumento, isNull);

      await provider.cargarLista(clienteConductorId: 601, nroDocumento: '43373493');
      expect(repo.ultimaListaPersonaId, 601);
      expect(repo.ultimaListaDocumento, '43373493');
    });
  });
}

/// Un celular donde no se puede leer ni escribir el almacenamiento.
class _AlmacenQueFalla implements EventoInvitadoAlmacen {
  @override
  Future<EventoInvitado?> leer() async => throw Exception('sin acceso');

  @override
  Future<void> guardar(EventoInvitado invitado) async => throw Exception('sin acceso');

  @override
  Future<void> borrar() async => throw Exception('sin acceso');
}
