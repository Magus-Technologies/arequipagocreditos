import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/repositories/catalogos_repository.dart';
import '../datasources/catalogos_remote_datasource.dart';
import '../models/catalogo_models.dart';
import '../models/conductor_estado_model.dart';

class CatalogosRepositoryImpl implements CatalogosRepository {
  final CatalogosRemoteDataSource remoteDataSource;

  CatalogosRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDepartamentos() async {
    try {
      final result = await remoteDataSource.getDepartamentos();
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getProvincias(String codigoDepartamento) async {
    try {
      final result = await remoteDataSource.getProvincias(codigoDepartamento);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDistritos(String codigoProvincia) async {
    try {
      final result = await remoteDataSource.getDistritos(codigoProvincia);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlataformaItemModel>>> getPlataformas() async {
    try {
      final result = await remoteDataSource.getPlataformas();
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId) async {
    try {
      final result = await remoteDataSource.getConductorEstado(conductorId);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
