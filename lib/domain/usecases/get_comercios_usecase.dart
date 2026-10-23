import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../data/models/promo_taller_banner_model.dart';
import '../entities/comercio_entity.dart';
import '../repositories/comercio_repository.dart';

class GetComerciosUseCase {
  final ComercioRepository repository;

  GetComerciosUseCase(this.repository);

  Future<Either<Failure, List<ComercioEntity>>> call({int? categoriaId, String? departamento}) async {
    return await repository.getComercios(categoriaId: categoriaId, departamento: departamento);
  }
}

/// TK-0382: comercios agrupados por ciudad, con la audiencia del conductor y su tipo de vehículo (igual que los talleres).
class GetComerciosAgrupadosUseCase {
  final ComercioRepository repository;

  GetComerciosAgrupadosUseCase(this.repository);

  Future<Either<Failure, List<ComercioGrupoEntity>>> call({
    int? categoriaId,
    String? departamento,
    String? audiencia,
    String? tipoVehicular,
  }) async {
    return await repository.getComerciosAgrupados(
      categoriaId: categoriaId,
      departamento: departamento,
      audiencia: audiencia,
      tipoVehicular: tipoVehicular,
    );
  }
}

/// TK-0382: el conductor califica un comercio.
class CalificarComercioUseCase {
  final ComercioRepository repository;

  CalificarComercioUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required int comercioId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
  }) async {
    return await repository.calificarComercio(
      comercioId: comercioId,
      clienteConductorId: clienteConductorId,
      puntuacion: puntuacion,
      comentario: comentario,
    );
  }
}

class GetComercioCategoriasUseCase {
  final ComercioRepository repository;

  GetComercioCategoriasUseCase(this.repository);

  Future<Either<Failure, List<ComercioCategoriaEntity>>> call() async {
    return await repository.getCategorias();
  }
}

class GetComercioPromocionesBannersUseCase {
  final ComercioRepository repository;

  GetComercioPromocionesBannersUseCase(this.repository);

  Future<Either<Failure, List<PromoTallerBannerModel>>> call({String? departamento}) async {
    return await repository.getPromocionesBanners(departamento: departamento);
  }
}
