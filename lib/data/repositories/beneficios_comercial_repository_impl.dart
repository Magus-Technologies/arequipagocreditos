import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../domain/repositories/beneficios_comercial_repository.dart';
import '../datasources/beneficios_comercial_remote_datasource.dart';

class BeneficiosComercialRepositoryImpl implements BeneficiosComercialRepository {
  final BeneficiosComercialRemoteDataSource remoteDataSource;

  BeneficiosComercialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<BeneficioComercialEntity>>> getBeneficiosComerciales() async {
    try {
      final beneficios = await remoteDataSource.getBeneficiosComerciales();
      return Either.right(beneficios);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}