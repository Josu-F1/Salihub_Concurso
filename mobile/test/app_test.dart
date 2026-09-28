import 'package:flutter_test/flutter_test.dart';
import 'package:salihub_reto/api.dart';
import 'package:salihub_reto/modelos.dart';

void main() {
  test('convierte el color del nivel', () {
    expect(colorDesdeHex('#3B82F6'), 0xFF3B82F6);
  });

  test('el reloj de la demo empieza en hoy', () {
    expect(Api.instancia.diasAdelante.value, 0);
  });

  test('CartaModel mapea correctamente desde json', () {
    final json = {
      'codigo': 'runner_optima_1',
      'disciplina': 'runner',
      'nivel': 'optima',
      'titulo': 'Cadencia Fluida',
      'frase': 'Mantén tu zancada ligera.',
      'insight': 'Día perfecto para cambios de ritmo.',
      'categoria': 'Biomecánica',
      'icono': '🏃',
      'es_dorada': true,
      'fecha': '2026-09-28',
    };

    final carta = CartaModel.fromJson(json);
    expect(carta.codigo, 'runner_optima_1');
    expect(carta.disciplina, 'runner');
    expect(carta.esDorada, isTrue);
    expect(carta.icono, '🏃');
  });

  test('PerfilModel mapea valores por defecto correctamente', () {
    final perfil = PerfilModel.fromJson({});
    expect(perfil.nombre, 'Persona demo');
    expect(perfil.disciplina, 'bienestar');
  });
}
