# Arquitectura Clean - Arequipa Créditos

## 📋 Descripción

Este proyecto implementa **Clean Architecture** con **Provider** para el state management en Flutter. La arquitectura separa claramente las responsabilidades y facilita el mantenimiento, testing y escalabilidad del código.

## 🏗️ Estructura del Proyecto

```
lib/
├── core/                           # Configuraciones y utilidades centrales
│   ├── constants/                  # Constantes de la aplicación
│   │   ├── api_constants.dart      # URLs y configuración de API
│   │   └── app_constants.dart      # Constantes generales
│   ├── errors/                     # Manejo de errores
│   │   ├── exceptions.dart         # Excepciones personalizadas
│   │   └── failures.dart           # Fallos del dominio
│   ├── network/                    # Cliente HTTP y configuración de red
│   │   └── api_client.dart         # Cliente HTTP con manejo de errores
│   ├── utils/                      # Utilidades generales
│   │   ├── either.dart             # Implementación del patrón Either
│   │   └── validators.dart         # Validadores comunes
│   └── constants.dart              # Exportación de constantes
│
├── data/                           # Capa de datos (Data Layer)
│   ├── datasources/                # Fuentes de datos
│   │   ├── auth_remote_datasource.dart        # API de autenticación
│   │   └── cupones_remote_datasource.dart     # API de cupones
│   ├── models/                     # Modelos de datos (JSON ↔ Objeto)
│   │   ├── conductor_model.dart    # Modelo del conductor
│   │   └── cupon_model.dart        # Modelo del cupón
│   └── repositories/               # Implementaciones de repositorios
│       ├── auth_repository_impl.dart          # Implementación auth
│       └── cupones_repository_impl.dart       # Implementación cupones
│
├── domain/                         # Capa de dominio (Domain Layer)
│   ├── entities/                   # Entidades de negocio
│   │   ├── conductor_entity.dart   # Entidad del conductor
│   │   └── cupon_entity.dart       # Entidad del cupón
│   ├── repositories/               # Interfaces de repositorios
│   │   ├── auth_repository.dart    # Interfaz auth
│   │   └── cupones_repository.dart # Interfaz cupones
│   └── usecases/                   # Casos de uso
│       ├── auth_usecases.dart      # Casos de uso de autenticación
│       └── cupones_usecases.dart   # Casos de uso de cupones
│
├── presentation/                   # Capa de presentación (Presentation Layer)
│   ├── providers/                  # State management con Provider
│   │   ├── auth_provider.dart      # Estado de autenticación
│   │   └── cupones_provider.dart   # Estado de cupones
│   ├── pages/                      # Páginas de la aplicación
│   └── widgets/                    # Widgets reutilizables
│
├── dependency_injection.dart       # Configuración de dependencias
└── main.dart                       # Punto de entrada de la aplicación
```

## 🔧 Principios de Clean Architecture

### 1. **Separación de Responsabilidades**
- **Core**: Utilidades y configuraciones centrales
- **Data**: Acceso a datos externos (APIs, Base de datos)
- **Domain**: Lógica de negocio pura (sin dependencias de framework)
- **Presentation**: UI y state management

### 2. **Dependency Rule**
Las dependencias apuntan hacia adentro:
- `Presentation` → `Domain`
- `Data` → `Domain`
- `Core` ← Todas las capas

### 3. **Inversión de Dependencias**
- Los repositorios son **interfaces** en `Domain`
- Las **implementaciones** están en `Data`
- Se inyectan las dependencias desde `Presentation`

## 🚀 Flujo de Datos

```
UI (Widget) → Provider → UseCase → Repository Interface → Repository Implementation → DataSource → API
```

### Ejemplo: Login de Usuario
1. **UI**: Usuario presiona botón de login
2. **Provider**: `AuthProvider.login()` se ejecuta
3. **UseCase**: `LoginUseCase` valida datos y ejecuta lógica
4. **Repository**: `AuthRepository` define el contrato
5. **Implementation**: `AuthRepositoryImpl` implementa la lógica
6. **DataSource**: `AuthRemoteDataSource` hace llamada a API
7. **Response**: Datos regresan por el mismo flujo

## 📦 Dependencias Principales

```yaml
dependencies:
  # Estado
  provider: ^6.0.5
  
  # Red
  http: ^1.1.0
  
  # Utilidades
  intl: ^0.18.1
  
  # UI
  flutter:
    sdk: flutter
```

## 🎯 Beneficios de esta Arquitectura

### ✅ **Mantenibilidad**
- Código organizado y fácil de encontrar
- Separación clara de responsabilidades
- Cambios en una capa no afectan otras

### ✅ **Testabilidad**
- Lógica de negocio independiente de Framework
- Interfaces permiten crear mocks fácilmente
- Testing unitario de cada capa por separado

### ✅ **Escalabilidad**
- Fácil agregar nuevas funcionalidades
- Modularización natural del código
- Reutilización de componentes

### ✅ **Independencia de Framework**
- Lógica de negocio no depende de Flutter
- Fácil migración a otros frameworks
- Core business logic reutilizable

## 🔄 Cómo Usar la Nueva Arquitectura

### 1. **Agregar una Nueva Feature**

#### Paso 1: Crear Entity en Domain
```dart
// lib/domain/entities/nueva_entity.dart
class NuevaEntity {
  final int id;
  final String nombre;
  
  const NuevaEntity({required this.id, required this.nombre});
}
```

#### Paso 2: Crear Repository Interface
```dart
// lib/domain/repositories/nueva_repository.dart
abstract class NuevaRepository {
  Future<Either<Failure, List<NuevaEntity>>> getItems();
}
```

#### Paso 3: Crear UseCase
```dart
// lib/domain/usecases/nueva_usecases.dart
class GetItemsUseCase {
  final NuevaRepository repository;
  
  GetItemsUseCase(this.repository);
  
  Future<Either<Failure, List<NuevaEntity>>> call() async {
    return await repository.getItems();
  }
}
```

#### Paso 4: Implementar Data Layer
```dart
// lib/data/models/nueva_model.dart
class NuevaModel extends NuevaEntity {
  // Implementación con fromJson/toJson
}

// lib/data/datasources/nueva_remote_datasource.dart
abstract class NuevaRemoteDataSource {
  Future<List<NuevaModel>> getItems();
}

// lib/data/repositories/nueva_repository_impl.dart
class NuevaRepositoryImpl implements NuevaRepository {
  // Implementación usando DataSource
}
```

#### Paso 5: Crear Provider
```dart
// lib/presentation/providers/nueva_provider.dart
class NuevaProvider extends ChangeNotifier {
  // State management logic
}
```

#### Paso 6: Actualizar Dependency Injection
```dart
// lib/dependency_injection.dart
// Agregar el nuevo provider a la lista
```

### 2. **Manejo de Estados con Provider**

```dart
// En tu Widget
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    switch (authProvider.status) {
      case AuthStatus.loading:
        return CircularProgressIndicator();
      case AuthStatus.authenticated:
        return HomeScreen();
      case AuthStatus.error:
        return ErrorWidget(authProvider.errorMessage);
      default:
        return LoginScreen();
    }
  },
)
```

### 3. **Llamadas a API con Either**

```dart
// En tu UseCase
Future<Either<Failure, ConductorEntity>> login(String dni, String password) async {
  try {
    final result = await repository.login(dni, password);
    return Either.right(result);
  } catch (e) {
    return Either.left(ServerFailure('Error de conexión'));
  }
}

// En tu Provider
final result = await loginUseCase(dni, password);
result.fold(
  (failure) => _handleError(failure),
  (conductor) => _handleSuccess(conductor),
);
```

## 🛠️ Herramientas de Desarrollo

### Testing
```bash
# Tests unitarios
flutter test

# Tests de integración
flutter test integration_test/
```

### Análisis de código
```bash
# Análisis estático
flutter analyze

# Formateo
flutter format .
```

### Build
```bash
# Debug
flutter run

# Release
flutter build apk --release
```

## 📚 Recursos Adicionales

- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)
- [Either Pattern in Dart](https://pub.dev/packages/dartz)

## 🤝 Contribución

1. Sigue los principios de Clean Architecture
2. Mantén la separación de responsabilidades
3. Agrega tests para nuevas funcionalidades
4. Documenta los cambios importantes

---

**Esta arquitectura está diseñada para crecer con tu aplicación y mantener la calidad del código a lo largo del tiempo.**
