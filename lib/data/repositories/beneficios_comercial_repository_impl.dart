import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../domain/entities/beneficio_servicio_entity.dart';
import '../../domain/repositories/beneficios_comercial_repository.dart';
import '../datasources/beneficios_comercial_remote_datasource.dart';
import '../models/taller_model.dart';

class BeneficiosComercialRepositoryImpl implements BeneficiosComercialRepository {
  final BeneficiosComercialRemoteDataSource remoteDataSource;

  BeneficiosComercialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<BeneficioComercialEntity>>> getBeneficiosComerciales({int? tipo, String? audiencia}) async {
    try {
      final beneficios = await remoteDataSource.getBeneficiosComerciales(tipo: tipo, audiencia: audiencia);
      return Either.right(beneficios);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BeneficioServicioEntity>>> getBeneficiosServicios({int? tallerId, String? audiencia}) async {
    try {
      final beneficios = await remoteDataSource.getBeneficiosServicios(tallerId: tallerId, audiencia: audiencia);
      return Either.right(beneficios);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TallerModel>>> getTalleres() async {
    try {
      final talleres = await remoteDataSource.getTalleres();
      return Either.right(talleres);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
