import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/beneficio_entity.dart';
import '../repositories/beneficios_comercial_repository.dart';

class GetBeneficiosComercialUseCase {
  final BeneficiosComercialRepository repository;

  GetBeneficiosComercialUseCase(this.repository);

  Future<Either<Failure, List<BeneficioComercialEntity>>> call({int? tipo, String? audiencia}) async {
    return await repository.getBeneficiosComerciales(tipo: tipo, audiencia: audiencia);
  }
}