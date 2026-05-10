import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/beneficio_servicio_entity.dart';
import '../repositories/beneficios_comercial_repository.dart';

class GetBeneficiosServiciosUseCase {
  final BeneficiosComercialRepository repository;

  GetBeneficiosServiciosUseCase(this.repository);

  Future<Either<Failure, List<BeneficioServicioEntity>>> call({int? tallerId}) async {
    return await repository.getBeneficiosServicios(tallerId: tallerId);
  }
}
