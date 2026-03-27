import '../../domain/entities/puntuacion_entity.dart';
import '../../domain/entities/historial_puntos_entity.dart';
import '../../domain/entities/beneficio_entity.dart';

class PuntuacionModel extends PuntuacionEntity {
  const PuntuacionModel({
    required super.id,
    required super.tipoCliente,
    super.idConductor,
    required super.puntajeActual,
    required super.totalFinanciamientos,
    required super.totalRetrasos,
    required super.fechaActualizacion,
    required super.fechaCreacion,
  });

  factory PuntuacionModel.fromJson(Map<String, dynamic> json) {
    // Extract nested puntaje if it exists
    Map<String, dynamic> puntajeData = {};
    if (json.containsKey('puntaje') && json['puntaje'] is Map) {
      puntajeData = json['puntaje'] as Map<String, dynamic>;
    }

    // Extract nested estadisticas if they exist
    Map<String, dynamic> estadisticas = {};
    if (json.containsKey('estadisticas') && json['estadisticas'] is Map) {
      estadisticas = json['estadisticas'] as Map<String, dynamic>;
    }

    // Extract nested fechas if they exist
    Map<String, dynamic> fechas = {};
    if (json.containsKey('fechas') && json['fechas'] is Map) {
      fechas = json['fechas'] as Map<String, dynamic>;
    }

    // Helper to safely get int from dynamic (int or double)
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    return PuntuacionModel(
      id: toInt(json['id']),
      tipoCliente: (json['tipo_cliente'] ?? json['tipo'] ?? '').toString(),
      idConductor: toInt(json['id_conductor'] ?? (json['persona'] != null ? json['persona']['id'] : null)),
      puntajeActual: toInt(puntajeData['actual'] ?? json['puntaje_actual']),
      totalFinanciamientos: toInt(estadisticas['total_financiamientos'] ?? json['total_financiamientos']),
      totalRetrasos: toInt(estadisticas['total_retrasos'] ?? json['total_retrasos']),
      fechaActualizacion: (fechas['actualizacion'] ?? json['fecha_actualizacion'] ?? json['fecha_actualizacion_puntaje']) != null
          ? DateTime.parse((fechas['actualizacion'] ?? json['fecha_actualizacion'] ?? json['fecha_actualizacion_puntaje']).toString())
          : DateTime.now(),
      fechaCreacion: (fechas['creacion'] ?? json['fecha_creacion'] ?? json['created_at']) != null
          ? DateTime.parse((fechas['creacion'] ?? json['fecha_creacion'] ?? json['created_at']).toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo_cliente': tipoCliente,
      'id_conductor': idConductor,
      'puntaje_actual': puntajeActual,
      'total_financiamientos': totalFinanciamientos,
      'total_retrasos': totalRetrasos,
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  PuntuacionEntity toEntity() => PuntuacionEntity(
        id: id,
        tipoCliente: tipoCliente,
        idConductor: idConductor,
        puntajeActual: puntajeActual,
        totalFinanciamientos: totalFinanciamientos,
        totalRetrasos: totalRetrasos,
        fechaActualizacion: fechaActualizacion,
        fechaCreacion: fechaCreacion,
      );

  PuntuacionModel copyWith({
    int? id,
    String? tipoCliente,
    int? idConductor,
    int? puntajeActual,
    int? totalFinanciamientos,
    int? totalRetrasos,
    DateTime? fechaActualizacion,
    DateTime? fechaCreacion,
  }) {
    return PuntuacionModel(
      id: id ?? this.id,
      tipoCliente: tipoCliente ?? this.tipoCliente,
      idConductor: idConductor ?? this.idConductor,
      puntajeActual: puntajeActual ?? this.puntajeActual,
      totalFinanciamientos: totalFinanciamientos ?? this.totalFinanciamientos,
      totalRetrasos: totalRetrasos ?? this.totalRetrasos,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

class HistorialPuntosModel extends HistorialPuntosEntity {
  const HistorialPuntosModel({
    super.id,
    super.puntajeAnterior,
    super.puntajeNuevo,
    required super.puntosPerdidos,
    required super.motivo,
    required super.fechaReferencia,
    super.numeroCuota,
    super.montoCuota,
    super.fechaVencimiento,
    super.fechaPago,
    super.idFinanciamiento,
    super.nombreProducto,
    required super.estadoCuota,
    required super.origen,
  });

  factory HistorialPuntosModel.fromJson(Map<String, dynamic> json) {
    final String fechaStr = (json['fecha_referencia'] ?? json['fecha_evento'] ?? json['created_at'] ?? '').toString();
    
    // Helper to safely get int from dynamic (int or double)
    int? toIntNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt();
      return null;
    }

    int toInt(dynamic value) => toIntNull(value) ?? 0;

    return HistorialPuntosModel(
      id: toIntNull(json['id']),
      puntajeAnterior: toIntNull(json['puntaje_anterior']),
      puntajeNuevo: toIntNull(json['puntaje_nuevo']),
      puntosPerdidos: toInt(json['puntos_perdidos']),
      motivo: json['motivo'] ?? '',
      fechaReferencia: fechaStr.isNotEmpty
          ? DateTime.parse(fechaStr)
          : DateTime.now(),
      numeroCuota: toIntNull(json['numero_cuota']),
      montoCuota: json['monto_cuota']?.toString(),
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.parse(json['fecha_vencimiento'].toString())
          : null,
      fechaPago: json['fecha_pago'] != null ? DateTime.parse(json['fecha_pago'].toString()) : null,
      idFinanciamiento: toIntNull(json['idfinanciamiento'] ?? json['financiamiento_id']),
      nombreProducto: json['nombre_producto'],
      estadoCuota: json['estado_cuota'] ?? '',
      origen: json['origen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puntaje_anterior': puntajeAnterior,
      'puntaje_nuevo': puntajeNuevo,
      'puntos_perdidos': puntosPerdidos,
      'motivo': motivo,
      'fecha_referencia': fechaReferencia.toIso8601String(),
      'numero_cuota': numeroCuota,
      'monto_cuota': montoCuota,
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'fecha_pago': fechaPago?.toIso8601String(),
      'idfinanciamiento': idFinanciamiento,
      'nombre_producto': nombreProducto,
      'estado_cuota': estadoCuota,
      'origen': origen,
    };
  }

  HistorialPuntosEntity toEntity() => HistorialPuntosEntity(
        id: id,
        puntajeAnterior: puntajeAnterior,
        puntajeNuevo: puntajeNuevo,
        puntosPerdidos: puntosPerdidos,
        motivo: motivo,
        fechaReferencia: fechaReferencia,
        numeroCuota: numeroCuota,
        montoCuota: montoCuota,
        fechaVencimiento: fechaVencimiento,
        fechaPago: fechaPago,
        idFinanciamiento: idFinanciamiento,
        nombreProducto: nombreProducto,
        estadoCuota: estadoCuota,
        origen: origen,
      );
}

class BeneficioModel extends BeneficioEntity {
  const BeneficioModel({
    required super.titulo,
    required super.descripcion,
    required super.icono,
    required super.activo,
  });

  factory BeneficioModel.fromJson(Map<String, dynamic> json) {
    return BeneficioModel(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'] ?? '',
      activo: json['activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'icono': icono,
      'activo': activo,
    };
  }

  BeneficioEntity toEntity() => BeneficioEntity(
        titulo: titulo,
        descripcion: descripcion,
        icono: icono,
        activo: activo,
      );
}
