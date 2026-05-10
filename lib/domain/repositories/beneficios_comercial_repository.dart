import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/beneficio_entity.dart';
import '../entities/beneficio_servicio_entity.dart';

abstract class BeneficiosComercialRepository {
  Future<Either<Failure, List<BeneficioComercialEntity>>> getBeneficiosComerciales({int? tipo});
  Future<Either<Failure, List<BeneficioServicioEntity>>> getBeneficiosServicios({int? tallerId});
}