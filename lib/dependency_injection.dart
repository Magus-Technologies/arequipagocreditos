import 'package:arequipagocreditos/data/datasources/resumen_crediticio_datasource.dart';
import 'package:arequipagocreditos/domain/repositories/resumen_crediticio_repository.dart';
import 'package:arequipagocreditos/data/repositories/resumen_crediticio_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Data Layer
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/cupones_remote_datasource.dart';
import 'data/datasources/financiamiento_remote_datasource.dart';
import 'data/datasources/puntuacion_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/cupones_repository_impl.dart';
import 'data/repositories/financiamiento_repository_impl.dart';
import 'data/repositories/puntuacion_repository_impl.dart';

// Domain Layer
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/cupones_repository.dart';
import 'domain/repositories/financiamiento_repository.dart';
import 'domain/repositories/puntuacion_repository.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/cupones_usecases.dart';
import 'domain/usecases/financiamiento_usecases.dart';
import 'domain/usecases/puntuacion_usecases.dart';
import 'domain/usecases/get_resumen_crediticio_usecase.dart';

// Presentation Layer
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cupones_provider.dart';
import 'presentation/providers/financiamiento_provider.dart';
import 'presentation/providers/puntuacion_provider.dart';
import 'presentation/providers/resumen_crediticio_provider.dart';

class DependencyInjection {
  static List<ChangeNotifierProvider> get providers => [
    // Providers
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        loginUseCase: _getLoginUseCase(),
        logoutUseCase: _getLogoutUseCase(),
        getLoggedUserUseCase: _getLoggedUserUseCase(),
        changePasswordUseCase: _getChangePasswordUseCase(),
        validateDniForPasswordRecoveryUseCase: validateDniForPasswordRecoveryUseCase(),
      ),
    ),
    
    ChangeNotifierProvider<CuponesProvider>(
      create: (context) => CuponesProvider(
        getCuponesUseCase: _getCuponesUseCase(),
        usarCuponUseCase: _getUsarCuponUseCase(),
        filterCuponesByCategoria: _getFilterCuponesByCategoria(),
      ),
    ),

    ChangeNotifierProvider<FinanciamientoProvider>(
      create: (context) => FinanciamientoProvider(
        getFinanciamientosUseCase: getFinanciamientosUseCase(),
        getFinanciamientoByIdUseCase: getFinanciamientoByIdUseCase(),
        getCuotasFinanciamientoUseCase: getCuotasFinanciamientoUseCase(),
        pagarCuotaUseCase: getPagarCuotaUseCase(),
        generarReporteCuotaUseCase: getGenerarReporteCuotaUseCase(),
      ),
    ),

    ChangeNotifierProvider<PuntuacionProvider>(
      create: (context) => PuntuacionProvider(
        getPuntuacionUseCase: getPuntuacionUseCase(),
        getHistorialPuntosUseCase: getHistorialPuntosUseCase(),
        getBeneficiosUseCase: getBeneficiosUseCase(),
        actualizarPuntuacionUseCase: getActualizarPuntuacionUseCase(),

      ),
    ),

    ChangeNotifierProvider<ResumenCrediticioProvider>(
      create: (context) => ResumenCrediticioProvider(
        getResumenCrediticioUseCase: getResumenCrediticioUseCase(),
        
      ),
    ),
  ];

  // Repositories
  static AuthRepository get _authRepository => AuthRepositoryImpl(
    remoteDataSource: _authRemoteDataSource,
  );

  static CuponesRepository get _cuponesRepository => CuponesRepositoryImpl(
    remoteDataSource: _cuponesRemoteDataSource,
  );

  static FinanciamientoRepository get _financiamientoRepository => FinanciamientoRepositoryImpl(
    remoteDataSource: _financiamientoRemoteDataSource,
  );

  static PuntuacionRepository get _puntuacionRepository => PuntuacionRepositoryImpl(
    remoteDataSource: _puntuacionRemoteDataSource,
  );

  static ResumenCrediticioRepository get _resumenCrediticioRepository => ResumenCrediticioRepositoryImpl(
    remoteDataSource: _resumenCrediticioRemoteDataSource,
  );

  // DataSources
  static AuthRemoteDataSource get _authRemoteDataSource => 
      AuthRemoteDataSourceImpl(client: _httpClient);

  static CuponesRemoteDataSource get _cuponesRemoteDataSource => 
      CuponesRemoteDataSourceImpl(client: _httpClient);

  static FinanciamientoRemoteDataSource get _financiamientoRemoteDataSource => 
      FinanciamientoRemoteDataSourceImpl(client: _httpClient);

  static PuntuacionRemoteDataSource get _puntuacionRemoteDataSource => 
      PuntuacionRemoteDataSourceImpl(client: _httpClient);

  static ResumenCrediticioRemoteDataSource get _resumenCrediticioRemoteDataSource =>
      ResumenRemoteDataSourceImpl(client: _httpClient);

  // Network
  static http.Client get _httpClient => http.Client();

  // Use Cases - Auth
  static LoginUseCase _getLoginUseCase() => LoginUseCase(_authRepository);
  static LogoutUseCase _getLogoutUseCase() => LogoutUseCase(_authRepository);
  static GetLoggedUserUseCase _getLoggedUserUseCase() => GetLoggedUserUseCase(_authRepository);
  static ChangePasswordUseCase _getChangePasswordUseCase() => ChangePasswordUseCase(_authRepository);
  static RefreshUserDataUseCase refreshUserDataUseCase() => RefreshUserDataUseCase(_authRepository);
  static ValidateDniForPasswordRecoveryUseCase validateDniForPasswordRecoveryUseCase() => ValidateDniForPasswordRecoveryUseCase(_authRepository);
  static ResetPasswordUseCase resetPasswordUseCase() => ResetPasswordUseCase(_authRepository);
  static UploadProfilePictureUseCase uploadProfilePictureUseCase() => UploadProfilePictureUseCase(_authRepository);

  // Use Cases - Cupones
  static GetCuponesUseCase _getCuponesUseCase() => GetCuponesUseCase(_cuponesRepository);
  static UsarCuponUseCase _getUsarCuponUseCase() => UsarCuponUseCase(_cuponesRepository);
  static FilterCuponesByCategoria _getFilterCuponesByCategoria() => FilterCuponesByCategoria();

  // Use Cases - Financiamiento
  static GetFinanciamientosUseCase getFinanciamientosUseCase() => GetFinanciamientosUseCase(repository: _financiamientoRepository);
  static GetFinanciamientoByIdUseCase getFinanciamientoByIdUseCase() => GetFinanciamientoByIdUseCase(repository: _financiamientoRepository);
  static GetCuotasFinanciamientoUseCase getCuotasFinanciamientoUseCase() => GetCuotasFinanciamientoUseCase(repository: _financiamientoRepository);
  static PagarCuotaUseCase getPagarCuotaUseCase() => PagarCuotaUseCase(repository: _financiamientoRepository);
  static GenerarReporteCuotaUseCase getGenerarReporteCuotaUseCase() => GenerarReporteCuotaUseCase(repository: _financiamientoRepository);

  // Use Cases - Puntuación
  static GetPuntuacionUseCase getPuntuacionUseCase() => GetPuntuacionUseCase(repository: _puntuacionRepository);
  static GetHistorialPuntosUseCase getHistorialPuntosUseCase() => GetHistorialPuntosUseCase(repository: _puntuacionRepository);
  static GetBeneficiosUseCase getBeneficiosUseCase() => GetBeneficiosUseCase(repository: _puntuacionRepository);
  static ActualizarPuntuacionUseCase getActualizarPuntuacionUseCase() => ActualizarPuntuacionUseCase(repository: _puntuacionRepository);

  // Use Cases - Resumen Crediticio
  static GetResumenCrediticioUseCase getResumenCrediticioUseCase() => GetResumenCrediticioUseCase(repository: _resumenCrediticioRepository);
}
