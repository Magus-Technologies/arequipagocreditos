import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/puntuacion_entity.dart';
import '../entities/historial_puntos_entity.dart';
import '../entities/beneficio_entity.dart';

abstract class PuntuacionRepository {
  Future<Either<Failure, PuntuacionEntity>> getPuntuacion(int idConductor);
  Future<Either<Failure, List<HistorialPuntosEntity>>> getHistorialPuntos(int idConductor);
  Future<Either<Failure, List<BeneficioEntity>>> getBeneficios(int puntaje);
  Future<Either<Failure, void>> actualizarPuntuacion(int idConductor, int nuevoPuntaje);
}
