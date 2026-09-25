import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/comercio_entity.dart';
import '../../domain/repositories/comercio_repository.dart';
import '../datasources/comercio_remote_datasource.dart';

class ComercioRepositoryImpl implements ComercioRepository {
  final ComercioRemoteDataSource remoteDataSource;

  ComercioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ComercioEntity>>> getComercios({int? categoriaId, String? departamento}) async {
    try {
      final comercios = await remoteDataSource.getComercios(categoriaId: categoriaId, departamento: departamento);
      return Either.right(comercios);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ComercioCategoriaEntity>>> getCategorias() async {
    try {
      final categorias = await remoteDataSource.getCategorias();
      return Either.right(categorias);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
