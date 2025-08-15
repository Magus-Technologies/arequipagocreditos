import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/puntuacion_entity.dart';
import '../../domain/entities/historial_puntos_entity.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../domain/repositories/puntuacion_repository.dart';
import '../datasources/puntuacion_remote_datasource.dart';

class PuntuacionRepositoryImpl implements PuntuacionRepository {
  final PuntuacionRemoteDataSource remoteDataSource;
  
  PuntuacionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PuntuacionEntity>> getPuntuacion(int idConductor) async {
    try {
      final puntuacionModel = await remoteDataSource.getPuntuacion(idConductor);
      return Either.right(puntuacionModel.toEntity());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HistorialPuntosEntity>>> getHistorialPuntos(int idConductor) async {
    try {
      final historialModels = await remoteDataSource.getHistorialPuntos(idConductor);
      final entities = historialModels.map((model) => model.toEntity()).toList();
      return Either.right(entities);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BeneficioEntity>>> getBeneficios(int puntaje) async {
    try {
      // Los beneficios se generan localmente basados en el puntaje
      final beneficios = BeneficioEntity.fromPuntaje(puntaje);
      return Either.right(beneficios);
    } catch (e) {
      return Either.left(UnknownFailure('Error al generar beneficios: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> actualizarPuntuacion(int idConductor, int nuevoPuntaje) async {
    try {
      await remoteDataSource.actualizarPuntuacion(idConductor, nuevoPuntaje);
      return Either.right(());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }
}
