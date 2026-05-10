import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../domain/entities/cuota_financiamiento_entity.dart';
import '../../domain/entities/documento_firmado_entity.dart';
import '../../domain/repositories/financiamiento_repository.dart';
import '../datasources/financiamiento_remote_datasource.dart';

class FinanciamientoRepositoryImpl implements FinanciamientoRepository {
  final FinanciamientoRemoteDataSource remoteDataSource;
  
  FinanciamientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FinanciamientoEntity>>> getFinanciamientos(int idConductor, int tipo) async {
    try {
      final financiamientoModels = await remoteDataSource.getFinanciamientos(idConductor, tipo);
      final entities = financiamientoModels.map((model) => model.toEntity()).toList();
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
  Future<Either<Failure, FinanciamientoEntity>> getFinanciamientoById(int id) async {
    try {
      final financiamientoModel = await remoteDataSource.getFinanciamientoById(id);
      return Either.right(financiamientoModel.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CuotaFinanciamientoEntity>>> getCuotasFinanciamiento(int idFinanciamiento) async {
    try {
      final cuotaModels = await remoteDataSource.getCuotasFinanciamiento(idFinanciamiento);
      final entities = cuotaModels.map((model) => model.toEntity()).toList();
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
  Future<Either<Failure, CuotaFinanciamientoEntity>> pagarCuota(int idCuota, double monto) async {
    try {
      final cuotaModel = await remoteDataSource.pagarCuota(idCuota, monto);
      return Either.right(cuotaModel.toEntity());
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
  Future<Either<Failure, String>> generarReporteCuota(int idCuota) async {
    try {
      final reporteUrl = await remoteDataSource.generarReporteCuota(idCuota);
      return Either.right(reporteUrl);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, FinanciamientoEntity>> createFinanciamiento(Map<String, dynamic> data) async {
    try {
      final model = await remoteDataSource.createFinanciamiento(data);
      return Either.right(model.toEntity());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, ListadoDocumentosEntity>> getListadoDocumentosFirmados(int idConductor) async {
    try {
      final model = await remoteDataSource.getListadoDocumentosFirmados(idConductor);
      return Either.right(model);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }
}
