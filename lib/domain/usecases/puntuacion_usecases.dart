import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/puntuacion_entity.dart';
import '../entities/historial_puntos_entity.dart';
import '../entities/beneficio_entity.dart';
import '../repositories/puntuacion_repository.dart';

class GetPuntuacionUseCase {
  final PuntuacionRepository repository;

  GetPuntuacionUseCase({required this.repository});

  Future<Either<Failure, PuntuacionEntity>> call(int idConductor) async {
    return await repository.getPuntuacion(idConductor);
  }
}

class GetHistorialPuntosUseCase {
  final PuntuacionRepository repository;

  GetHistorialPuntosUseCase({required this.repository});

  Future<Either<Failure, List<HistorialPuntosEntity>>> call(int idConductor) async {
    return await repository.getHistorialPuntos(idConductor);
  }
}

class GetBeneficiosUseCase {
  final PuntuacionRepository repository;

  GetBeneficiosUseCase({required this.repository});

  Future<Either<Failure, List<BeneficioEntity>>> call(int puntaje) async {
    return await repository.getBeneficios(puntaje);
  }
}

class ActualizarPuntuacionUseCase {
  final PuntuacionRepository repository;

  ActualizarPuntuacionUseCase({required this.repository});

  Future<Either<Failure, void>> call(int idConductor, int nuevoPuntaje) async {
    // Validaciones de negocio
    if (nuevoPuntaje < 0 || nuevoPuntaje > 100) {
      return Either.left(const ValidationFailure('El puntaje debe estar entre 0 y 100'));
    }
    
    return await repository.actualizarPuntuacion(idConductor, nuevoPuntaje);
  }
}
