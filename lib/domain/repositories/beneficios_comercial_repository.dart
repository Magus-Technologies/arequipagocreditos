import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/beneficio_entity.dart';

abstract class BeneficiosComercialRepository {
  Future<Either<Failure, List<BeneficioComercialEntity>>> getBeneficiosComerciales({int? tipo});
}