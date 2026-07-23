import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/models/conductor_estado_model.dart';

abstract class CatalogosRepository {
  Future<Either<Failure, List<UbigeoItemModel>>> getDepartamentos();
  Future<Either<Failure, List<UbigeoItemModel>>> getProvincias(String codigoDepartamento);
  Future<Either<Failure, List<UbigeoItemModel>>> getDistritos(String codigoProvincia);
  Future<Either<Failure, List<PlataformaItemModel>>> getPlataformas();
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId);
}
