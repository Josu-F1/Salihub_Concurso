import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Dirección del API de demo. Cámbiela al correr la app:
/// `flutter run --dart-define=API_URL=http://10.0.2.2:8000` (emulador de Android).
const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

class ApiError implements Exception {
  ApiError(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Cliente del API. Todo es de una sola persona de ejemplo: no hay inicio de sesión.
class Api {
  Api._();
  static final Api instancia = Api._();

  /// Días que se adelanta el reloj de la demo. Sirve para probar «volver mañana».
  final ValueNotifier<int> diasAdelante = ValueNotifier(0);

  String get _fecha {
    final dia = DateTime.now().add(Duration(days: diasAdelante.value));
    return '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
  }

  Uri _uri(String ruta) {
    final base = Uri.parse('$apiUrl/api/$ruta');
    if (diasAdelante.value == 0) return base;
    return base.replace(queryParameters: {...base.queryParameters, 'fecha': _fecha});
  }

  Future<dynamic> get(String ruta) async => _leer(await http.get(_uri(ruta)));

  Future<dynamic> post(String ruta, Map<String, dynamic> cuerpo) async => _leer(
        await http.post(_uri(ruta), headers: {'Content-Type': 'application/json'}, body: jsonEncode(cuerpo)),
      );

  Future<dynamic> put(String ruta, Map<String, dynamic> cuerpo) async => _leer(
        await http.put(_uri(ruta), headers: {'Content-Type': 'application/json'}, body: jsonEncode(cuerpo)),
      );

  Future<dynamic> delete(String ruta) async => _leer(await http.delete(_uri(ruta)));

  dynamic _leer(http.Response respuesta) {
    final datos = respuesta.body.isEmpty ? null : jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode >= 400) {
      final detalle = datos is Map && datos['detalle'] != null ? datos['detalle'] : 'Error ${respuesta.statusCode}';
      throw ApiError('$detalle');
    }
    return datos;
  }
}

/// Convierte "#3B82F6" en un color.
int colorDesdeHex(String hex) => int.parse('FF${hex.replaceFirst('#', '')}', radix: 16);
