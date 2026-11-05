import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// Lógica del módulo «Eventos» sin servidor: el cupo por persona, el tope, los estados y los errores de negocio. El repositorio es un
// falso con respuestas fijas; el servidor real decide el tope, el app solo evita mandar lo que ya sabe que va a fallar.

/// La sesión del app (AuthProvider) reducida a lo que el provider escucha: quién está en sesión y el aviso de que cambió.
class _Sesion extends ChangeNotifier {
  _Sesion(this.id);
  int? id;

  void cambiar(int? nuevo) {
    id = nuevo;
    notifyListeners();
  }
}

Future<EventoProvider> cargado(FakeEventoRepository repo, {int persona = 601}) async {
  final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);
  await provider.cargarActivo(clienteConductorId: persona, nroDocumento: '43373493');
  return provider;
}

/// La compra exige captura; el repositorio falso no la lee, solo la recibe.
final File _captura = File('captura.jpg');

void main() {
  group('evento activo', () {
    test('guarda el evento y manda id + DNI al servidor', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 1))];
      final provider = await cargado(repo);

      expect(provider.evento?.nombre, '3er Aniversario Arequipa Go');
      expect(repo.ultimaPersonaId, 601);
      expect(repo.ultimoDocumento, '43373493');
      expect(provider.cargandoActivo, isFalse);
    });

    test('sin evento activo (data:null) no hay evento ni se puede comprar', () async {
      final repo = FakeEventoRepository()..activo = [activo(null)];
      final provider = await cargado(repo);

      expect(provider.evento, isNull);
      expect(provider.puedeComprar, isFalse);
      expect(provider.ticketsDisponibles, 0);
    });

    test('un error de red no borra el evento que ya se tenía', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0)), Either.left(const ServerFailure('sin conexión'))];
      final provider = await cargado(repo);
      expect(provider.evento, isNotNull);

      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.evento, isNotNull);
    });

    test('si el servidor responde «ya no hay evento», se quita', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0)), activo(null)];
      final provider = await cargado(repo);

      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.evento, isNull);
    });

    test('dos cargas a la vez comparten la misma petición', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      final provider = EventoProvider(repository: repo);

      await Future.wait([
        provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493'),
        provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493'),
      ]);

      expect(repo.llamadasActivo, 1);
    });

    test('otra persona en el mismo teléfono no hereda el evento de la anterior', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 3))];
      final provider = await cargado(repo, persona: 601);
      expect(provider.ticketsDisponibles, 1);

      repo.activo = [Either.left(const ServerFailure('sin conexión'))];
      repo.llamadasActivo = 0;
      await provider.cargarActivo(clienteConductorId: 999, nroDocumento: '11111111');

      expect(provider.evento, isNull); // falló la carga de la nueva persona y la vieja no se arrastra
    });
  });

  group('cupo por persona', () {
    test('disponibles sale de mis_tickets del servidor', () async {
      final provider = await cargado(FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 1))]);

      expect(provider.ticketsDisponibles, 3);
      expect(provider.puedeComprar, isTrue);
      expect(provider.textoCupo, 'Máximo 4 por persona · te quedan 3');
    });

    test('con el tope alcanzado no puede comprar y dice el máximo', () async {
      final provider = await cargado(FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 4))]);

      expect(provider.ticketsDisponibles, 0);
      expect(provider.puedeComprar, isFalse);
      expect(provider.mensajeTope, 'Ya tienes el máximo de 4 tickets por persona');
    });

    test('con un máximo de 1 el mensaje va en singular', () async {
      final provider = await cargado(FakeEventoRepository()..activo = [activo(evento(max: 1, comprados: 1))]);

      expect(provider.mensajeTope, 'Ya tienes el máximo de 1 ticket por persona');
    });

    test('sin mis_tickets se calcula con las compras: pendiente y confirmado ocupan, rechazado y anulado no', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 5))]
        ..misCompras = Either.right([
          compra(id: 1, estado: 'pendiente', cantidad: 1),
          compra(id: 2, estado: 'confirmado', cantidad: 2),
          compra(id: 3, estado: 'rechazado', cantidad: 4),
          compra(id: 4, estado: 'anulado', cantidad: 4),
        ]);
      final provider = await cargado(repo);
      expect(provider.ticketsDisponibles, 5); // todavía sin compras cargadas

      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.ticketsDisponibles, 2); // 5 - (1 + 2)
      expect(provider.evento!.misTickets!.comprados, 3);
    });

    test('al cargar «mis compras» un rechazado libera su cupo aunque el evento viniera desactualizado', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 4))]
        ..misCompras = Either.right([compra(id: 1, estado: 'rechazado', cantidad: 2), compra(id: 2, estado: 'confirmado', cantidad: 2)]);
      final provider = await cargado(repo);
      expect(provider.puedeComprar, isFalse);

      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.ticketsDisponibles, 2);
      expect(provider.puedeComprar, isTrue);
    });

    test('un error al cargar «mis compras» deja el mensaje y conserva lo anterior', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0))]
        ..misCompras = Either.right([compra()]);
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      repo.misCompras = Either.left(const ServerFailure('Sin conexión'));
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.errorCompras, 'Sin conexión');
      expect(provider.compras, hasLength(1));
    });
  });

  group('registrar compra', () {
    test('no llama al servidor con cantidad 0 ni con más de lo que le queda', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 3))];
      final provider = await cargado(repo);

      final cero = await provider.registrarCompra(0, _captura);
      final demasiado = await provider.registrarCompra(2, _captura);

      expect(cero.ok, isFalse);
      expect(demasiado.ok, isFalse);
      expect(demasiado.mensaje, 'Solo puedes comprar 1 ticket más.');
      expect(repo.llamadasRegistrar, 0);
    });

    test('con el tope alcanzado responde con el mensaje del máximo y no llama al servidor', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 4))];
      final provider = await cargado(repo);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isFalse);
      expect(r.mensaje, 'Ya tienes el máximo de 4 tickets por persona');
      expect(repo.llamadasRegistrar, 0);
    });

    test('sin evento no compra', () async {
      final repo = FakeEventoRepository()..activo = [activo(null)];
      final provider = await cargado(repo);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isFalse);
      expect(repo.llamadasRegistrar, 0);
    });

    test('compra bien: la deja primera en la lista y el servidor corrige el cupo', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1)), activo(evento(max: 4, comprados: 3))]
        ..compra = Either.right(compra(id: 50, cantidad: 2));
      final provider = await cargado(repo);

      final r = await provider.registrarCompra(2, _captura);

      expect(r.ok, isTrue);
      expect(r.data!.id, 50);
      expect(repo.ultimaCantidad, 2);
      expect(provider.compras.first.id, 50);
      expect(provider.ticketsDisponibles, 1); // 4 - 3, lo que dijo el servidor al refrescar
      expect(provider.enviando, isFalse);
    });

    test('si no se puede refrescar el evento, el cupo igual baja con lo comprado', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1)), Either.left(const ServerFailure('sin conexión'))]
        ..compra = Either.right(compra(id: 50, cantidad: 2));
      final provider = await cargado(repo);

      await provider.registrarCompra(2, _captura);

      expect(provider.ticketsDisponibles, 1);
    });

    test('un 422 del servidor (tope excedido) se devuelve tal cual y se refresca el cupo', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1)), activo(evento(max: 4, comprados: 4))]
        ..compra = Either.left(const ValidationFailure('Ya tienes 4 de 4 tickets para este evento.'));
      final provider = await cargado(repo);
      expect(provider.puedeComprar, isTrue); // el app creía que le quedaban 3

      final r = await provider.registrarCompra(2, _captura);

      expect(r.ok, isFalse);
      expect(r.mensaje, 'Ya tienes 4 de 4 tickets para este evento.');
      expect(provider.puedeComprar, isFalse); // ahora sí sabe que no
      expect(provider.compras, isEmpty);
      expect(provider.enviando, isFalse);
    });

    test('se pierde la respuesta (red, tiempo agotado): avisa que no se sabe si se registró y revisa «mis compras»', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1))]
        ..misCompras = Either.right([compra(id: 20, cantidad: 1, estado: 'confirmado', puedeCancelar: false)])
        ..compra = Either.left(const ServerFailure('No pudimos conectar con el servidor.'));
      final provider = await cargado(repo);
      expect(repo.llamadasMisCompras, 0);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isFalse);
      expect(r.incierto, isTrue);
      expect(r.mensaje, 'No pudimos confirmar si tu compra se registró. Revisa «Mis tickets» antes de intentar de nuevo.');
      expect(repo.llamadasMisCompras, 1); // dejó la lista como está en el servidor, sin que nadie se lo pida
      expect(provider.compras.single.id, 20);
      expect(provider.ticketsDisponibles, 3);
      expect(provider.enviando, isFalse);
    });

    test('si el servidor sí había registrado la compra, tras el error ya aparece en la lista y baja el cupo', () async {
      final registrada = compra(id: 55, cantidad: 2);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0)), activo(evento(max: 4, comprados: 2))]
        ..misCompras = Either.right([registrada])
        ..compra = Either.left(const ServerFailure('Tiempo de espera agotado'));
      final provider = await cargado(repo);

      final r = await provider.registrarCompra(2, _captura);

      expect(r.incierto, isTrue);
      expect(provider.compraPorId(55), isNotNull);
      expect(provider.ticketsDisponibles, 2);
    });

    test('un error de validación NO es incierto: el servidor dijo que no', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..compra = Either.left(const ValidationFailure('El evento ya no está disponible.'));
      final provider = await cargado(repo);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.incierto, isFalse);
      expect(r.mensaje, 'El evento ya no está disponible.');
      expect(repo.llamadasMisCompras, 0);
    });

    test('si algo inesperado falla, suelta el botón y avisa en vez de quedarse girando', () async {
      // `compra` sin definir: el falso lanza al responder, como lo haría un fallo que ninguna capa previó.
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      final provider = await cargado(repo);

      final r = await provider.registrarCompra(1, _captura);

      expect(r.ok, isFalse);
      expect(r.mensaje, contains('error inesperado'));
      expect(provider.enviando, isFalse);
    });

    test('dos toques seguidos no mandan dos compras', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..compra = Either.right(compra(id: 50, cantidad: 1));
      final provider = await cargado(repo);

      final primera = provider.registrarCompra(1, _captura);
      final segunda = await provider.registrarCompra(1, _captura); // llega mientras la primera sigue en camino
      await primera;

      expect(segunda.ok, isFalse);
      expect(repo.llamadasRegistrar, 1);
    });
  });

  group('captura y cancelación', () {
    test('subir la captura reemplaza la compra en la lista y no cambia el cupo', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 2))]
        ..misCompras = Either.right([compra(id: 31, cantidad: 2)])
        ..captura = Either.right(compra(id: 31, cantidad: 2, captura: 'https://credigo.test/storage/eventos/capturas/c.jpg'));
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.compraPorId(31)!.tieneCaptura, isFalse);

      final r = await provider.subirCaptura(31, File('captura.jpg'));

      expect(r.ok, isTrue);
      expect(provider.compraPorId(31)!.tieneCaptura, isTrue);
      expect(provider.compraPorId(31)!.etiquetaEstado, 'En revisión');
      expect(provider.ticketsDisponibles, 2);
    });

    test('un error al subir la captura devuelve el mensaje del servidor', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0))]
        ..captura = Either.left(const ValidationFailure('La compra ya no admite captura.'));
      final provider = await cargado(repo);

      final r = await provider.subirCaptura(31, File('captura.jpg'));

      expect(r.ok, isFalse);
      expect(r.mensaje, 'La compra ya no admite captura.');
    });

    test('cancelar anula la compra y libera su cupo', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 4)), Either.left(const ServerFailure('sin conexión'))]
        ..misCompras = Either.right([compra(id: 31, cantidad: 3), compra(id: 32, cantidad: 1)])
        ..cancelar = Either.right(compra(id: 31, estado: 'anulado', cantidad: 3, puedeCancelar: false));
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.puedeComprar, isFalse);

      final r = await provider.cancelarCompra(31);

      expect(r.ok, isTrue);
      expect(provider.compraPorId(31)!.estadoCompra, EstadoCompra.anulado);
      expect(provider.ticketsDisponibles, 3);
      expect(provider.puedeComprar, isTrue);
    });

    test('sin persona identificada no hace nada', () async {
      final provider = EventoProvider(repository: FakeEventoRepository());

      final r = await provider.cancelarCompra(31);

      expect(r.ok, isFalse);
    });

    test('si el personal ya resolvió la compra, un 422 al subir captura deja la lista como está en el servidor', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 2))]
        ..misCompras = Either.right([compra(id: 31, cantidad: 2)]) // el app la ve pendiente, con «Subir captura»
        ..captura = Either.left(const ValidationFailure('La compra ya no admite captura.'));
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.compraPorId(31)!.puedeSubirCaptura, isTrue);

      // Mientras tanto el personal la confirmó.
      repo.misCompras = Either.right([compra(id: 31, cantidad: 2, estado: 'confirmado', puedeSubir: false, puedeCancelar: false)]);
      final r = await provider.subirCaptura(31, File('captura.jpg'));

      expect(r.ok, isFalse);
      expect(r.mensaje, 'La compra ya no admite captura.');
      expect(provider.compraPorId(31)!.estadoCompra, EstadoCompra.confirmado);
      expect(provider.compraPorId(31)!.puedeSubirCaptura, isFalse); // ya no queda el botón obsoleto
    });

    test('un 422 al cancelar (ya la rechazaron) también actualiza la compra y libera el cupo', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 4)), activo(evento(max: 4, comprados: 2))]
        ..misCompras = Either.right([compra(id: 31, cantidad: 2), compra(id: 32, cantidad: 2)])
        ..cancelar = Either.left(const ValidationFailure('Solo se puede cancelar una compra pendiente.'));
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.puedeComprar, isFalse);

      repo.misCompras = Either.right([
        compra(id: 31, cantidad: 2, estado: 'rechazado', motivo: 'Monto incorrecto', puedeCancelar: false, puedeSubir: false),
        compra(id: 32, cantidad: 2),
      ]);
      final r = await provider.cancelarCompra(31);

      expect(r.ok, isFalse);
      expect(provider.compraPorId(31)!.estadoCompra, EstadoCompra.rechazado);
      expect(provider.ticketsDisponibles, 2);
    });
  });

  group('entrada fija del inicio sin evento activo', () {
    EventoProvider nuevo(FakeEventoRepository repo) => EventoProvider(repository: repo, ahora: () => ahoraDePrueba);

    Future<EventoProvider> conCompras(List<EventoCompraModel> compras) async {
      // El evento ya empezó: el servidor responde «no hay evento activo».
      final repo = FakeEventoRepository()
        ..activo = [activo(null)]
        ..misCompras = Either.right(compras);
      final provider = nuevo(repo);
      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      return provider;
    }

    test('con una compra confirmada hay acceso, con el nombre del evento y sin ofrecer comprar', () async {
      final provider = await conCompras([compra(estado: 'confirmado', puedeCancelar: false)]);

      expect(provider.evento, isNull);
      expect(provider.hayAccesoFijo, isTrue);
      expect(provider.accesoSoloPorCompra, isTrue);
      expect(provider.nombreAccesoFijo, '3er Aniversario Arequipa Go');
      expect(provider.puedeComprar, isFalse);
    });

    test('con una compra pendiente también (le falta subir la captura)', () async {
      final provider = await conCompras([compra()]);

      expect(provider.hayAccesoFijo, isTrue);
    });

    test('solo rechazadas o anuladas: no hay acceso', () async {
      final provider = await conCompras([
        compra(id: 1, estado: 'rechazado', motivo: 'Monto incorrecto', puedeCancelar: false),
        compra(id: 2, estado: 'anulado', puedeCancelar: false),
      ]);

      expect(provider.hayAccesoFijo, isFalse);
      expect(provider.nombreAccesoFijo, isNull);
    });

    test('sin compras: no hay acceso', () async {
      expect((await conCompras(const [])).hayAccesoFijo, isFalse);
    });

    test('una compra de un evento de hace más de un día ya no da acceso', () async {
      final provider = await conCompras([
        compra(estado: 'confirmado', puedeCancelar: false, fechaHoraEvento: '2026-11-12T14:00:00-05:00'),
      ]);

      expect(provider.hayAccesoFijo, isFalse);
    });

    test('el mismo día del evento (y hasta un día después) sí', () async {
      final provider = await conCompras([
        compra(estado: 'confirmado', puedeCancelar: false, fechaHoraEvento: '2026-11-13T15:00:00-05:00'),
      ]);

      expect(provider.hayAccesoFijo, isTrue);
    });

    test('con evento activo hay acceso y se ofrece comprar (no es «solo por compra»)', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      final provider = nuevo(repo);
      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');

      expect(provider.hayAccesoFijo, isTrue);
      expect(provider.accesoSoloPorCompra, isFalse);
      expect(provider.nombreAccesoFijo, '3er Aniversario Arequipa Go');
    });
  });

  group('sesión', () {
    test('limpiar() olvida evento, compras y persona', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1))]
        ..misCompras = Either.right([compra()]);
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.hayAccesoFijo, isTrue);

      provider.limpiar();

      expect(provider.evento, isNull);
      expect(provider.compras, isEmpty);
      expect(provider.hayAccesoFijo, isFalse);
      expect((await provider.registrarCompra(1, _captura)).ok, isFalse); // sin persona identificada
    });

    test('la respuesta que venía en camino para la persona anterior se descarta', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1))]
        ..misCompras = Either.right([compra(cantidad: 1)]);
      final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);

      // A pide su evento y sus compras, y antes de que lleguen las respuestas cierra sesión.
      final activoDeA = provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');
      final comprasDeA = provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      provider.limpiar();
      await Future.wait([activoDeA, comprasDeA]);

      expect(provider.evento, isNull);
      expect(provider.compras, isEmpty);
      expect(provider.cargandoActivo, isFalse);
      expect(provider.cargandoCompras, isFalse);
    });

    test('si entra otra persona mientras llega la respuesta de la anterior, no se mezcla', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 3))]
        ..misCompras = Either.right([compra(id: 90, cantidad: 3)]);
      final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);

      final deA = provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      repo.misCompras = Either.right([compra(id: 91, cantidad: 1)]);
      final deB = provider.cargarMisCompras(clienteConductorId: 999, nroDocumento: '11111111');
      await Future.wait([deA, deB]);

      expect(provider.compras.map((c) => c.id), [91]); // solo lo de B
    });

    test('vincularSesion limpia al cerrar sesión y al entrar otra persona, y no toca a la misma', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 1))]
        ..misCompras = Either.right([compra()]);
      final sesion = _Sesion(601);
      final provider = await cargado(repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');
      provider.vincularSesion(sesion, () => sesion.id);

      // Un aviso de la sesión con la misma persona (p. ej. se refrescó su perfil) no borra nada.
      sesion.cambiar(601);
      expect(provider.evento, isNotNull);

      sesion.cambiar(null); // cerró sesión
      expect(provider.evento, isNull);
      expect(provider.compras, isEmpty);

      await provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493');
      expect(provider.evento, isNotNull);
      sesion.cambiar(999); // entró otra persona sin pasar por «sin sesión»
      expect(provider.evento, isNull);
    });

    test('dispose se desengancha de la sesión', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 1))];
      final sesion = _Sesion(601);
      final provider = await cargado(repo); // ya identificado: sin esto el aviso de sesión no haría nada de todos modos
      provider.vincularSesion(sesion, () => sesion.id);

      provider.dispose();

      // Si siguiera enganchado, limpiaría y avisaría a un provider ya descartado, y eso falla.
      expect(() => sesion.cambiar(null), returnsNormally);
    });
  });

  group('ticket en PDF', () {
    test('baja el PDF del servidor con la persona de la sesión', () async {
      final repo = FakeEventoRepository()..misCompras = Either.right([compra(estado: 'confirmado')]);
      final provider = EventoProvider(repository: repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      final r = await provider.descargarTicketPdf(31);

      expect(r.ok, isTrue);
      expect(r.data, isA<Uint8List>());
      expect(repo.ultimaCompraDelTicket, 31);
      expect(repo.llamadasTicketPdf, 1);
    });

    test('si el servidor dice que no (todavía no está confirmado), devuelve su mensaje', () async {
      final repo = FakeEventoRepository()
        ..misCompras = Either.right(const [])
        ..ticketPdf = Either.left(const ValidationFailure('El ticket se habilita cuando confirmemos tu pago.'));
      final provider = EventoProvider(repository: repo);
      await provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      final r = await provider.descargarTicketPdf(31);

      expect(r.ok, isFalse);
      expect(r.mensaje, 'El ticket se habilita cuando confirmemos tu pago.');
    });

    test('sin persona identificada no pide nada', () async {
      final repo = FakeEventoRepository();
      final provider = EventoProvider(repository: repo);

      final r = await provider.descargarTicketPdf(31);

      expect(r.ok, isFalse);
      expect(repo.llamadasTicketPdf, 0);
    });
  });
}
