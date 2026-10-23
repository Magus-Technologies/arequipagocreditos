import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/comercio_entity.dart';
import '../../domain/repositories/comercio_repository.dart';
import '../datasources/comercio_remote_datasource.dart';
import '../models/promo_taller_banner_model.dart';

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
  Future<Either<Failure, List<ComercioGrupoEntity>>> getComerciosAgrupados({
    int? categoriaId,
    String? departamento,
    String? audiencia,
    String? tipoVehicular,
  }) async {
    try {
      final grupos = await remoteDataSource.getComerciosAgrupados(
        categoriaId: categoriaId,
        departamento: departamento,
        audiencia: audiencia,
        tipoVehicular: tipoVehicular,
      );
      return Either.right(grupos);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> calificarComercio({
    required int comercioId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
  }) async {
    try {
      final resultado = await remoteDataSource.calificarComercio(
        comercioId: comercioId,
        clienteConductorId: clienteConductorId,
        puntuacion: puntuacion,
        comentario: comentario,
      );
      return Either.right(resultado);
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

  @override
  Future<Either<Failure, List<PromoTallerBannerModel>>> getPromocionesBanners({String? departamento}) async {
    try {
      final banners = await remoteDataSource.getPromocionesBanners(departamento: departamento);
      return Either.right(banners);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
