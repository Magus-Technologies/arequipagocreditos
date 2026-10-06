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

  Future<Either<Failure, List<PromoTallerBannerModel>>> call() async {
    return await repository.getPromocionesBanners();
  }
}
