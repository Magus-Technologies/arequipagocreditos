import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../data/models/promo_taller_banner_model.dart';
import '../entities/comercio_entity.dart';

abstract class ComercioRepository {
  Future<Either<Failure, List<ComercioEntity>>> getComercios({int? categoriaId, String? departamento});
  Future<Either<Failure, List<ComercioCategoriaEntity>>> getCategorias();
  Future<Either<Failure, List<PromoTallerBannerModel>>> getPromocionesBanners();
}
