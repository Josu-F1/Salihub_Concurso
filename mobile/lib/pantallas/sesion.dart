import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../tema.dart';

/// Detalle de la sesión, guía paso a paso y «¿Cómo le fue?».
class PantallaSesion extends StatefulWidget {
  const PantallaSesion({super.key, required this.codigo});
  final String codigo;

  @override
  State<PantallaSesion> createState() => _PantallaSesionState();
}

class _PantallaSesionState extends State<PantallaSesion> {
  late final Future<Map<String, dynamic>> _sesion =
      Api.instancia.get('entrenamiento/sesiones/${widget.codigo}/').then((d) => d as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sesión de Entrenamiento'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sesion,
        builder: (context, estado) {
          if (estado.hasError) return Center(child: Text('${estado.error}'));
          if (!estado.hasData) return const Center(child: CircularProgressIndicator());
          final sesion = estado.data!;
          final pasos = (sesion['pasos'] as List).cast<Map<String, dynamic>>();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sesion['titulo'] as String, style: texto.headlineMedium?.copyWith(fontSize: 24, color: Colores.navy)),
                          const SizedBox(height: 6),
                          Text(sesion['objetivo'] as String, style: const TextStyle(color: Colores.gris, fontSize: 14)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Dato('${sesion['duracion_min']}-${sesion['duracion_max']} min'),
                              _Dato(sesion['categoria'] as String),
                              _Dato('Esfuerzo ${sesion['rpe_min']}-${sesion['rpe_maximo']} / 10'),
                              _Dato('Equipo: ${sesion['equipo']}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colores.azul.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colores.azul.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.record_voice_over, size: 16, color: Colores.azul),
                                    SizedBox(width: 6),
                                    Text('Mensaje del Entrenador:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colores.navy)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(sesion['mensaje'] as String, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Pasos de la Sesión (${pasos.length})', style: texto.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final paso in pasos)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colores.azul.withValues(alpha: 0.15),
                          foregroundColor: Colores.azul,
                          child: Text('${paso['orden']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(paso['contenido'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Colores.navy)),
                        subtitle: Text(_duracion(paso['duracion_segundos'] as int)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colores.azul,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => _SesionGuiada(sesion: sesion)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text('Iniciar Sesión Guiada en Tarjetas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _duracion(int segundos) {
  if (segundos < 60) return '$segundos s';
  final minutos = segundos ~/ 60;
  final resto = segundos % 60;
  return resto == 0 ? '$minutos min' : '$minutos min $resto s';
}

class _Dato extends StatelessWidget {
  const _Dato(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(texto, style: const TextStyle(color: Colores.navy, fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: Colores.azul.withValues(alpha: 0.1),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

class _SesionGuiada extends StatefulWidget {
  const _SesionGuiada({required this.sesion});
  final Map<String, dynamic> sesion;

  @override
  State<_SesionGuiada> createState() => _SesionGuiadaState();
}

class _SesionGuiadaState extends State<_SesionGuiada> {
  late final List<Map<String, dynamic>> _pasos = (widget.sesion['pasos'] as List).cast<Map<String, dynamic>>();
  int _actual = 0;
  int _restante = 0;
  bool _pausado = false;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _irA(0);
  }

  void _irA(int indice) {
    _reloj?.cancel();
    if (indice >= _pasos.length) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _ComoTeFue(sesion: widget.sesion)),
      );
      return;
    }
    setState(() {
      _actual = indice;
      _restante = _pasos[indice]['duracion_segundos'] as int;
      _pausado = false;
    });
    _iniciarReloj();
  }

  void _iniciarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pausado) return;
      if (_restante <= 1) {
        _reloj?.cancel();
        setState(() => _restante = 0);
      } else {
        setState(() => _restante--);
      }
    });
  }

  void _togglePausa() {
    setState(() => _pausado = !_pausado);
  }

  void _reiniciarReloj() {
    setState(() {
      _restante = _pasos[_actual]['duracion_segundos'] as int;
      _pausado = false;
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_actual];
    final ultimo = _actual == _pasos.length - 1;
    final duracionTotalPaso = paso['duracion_segundos'] as int;
    final min = (_restante ~/ 60).toString().padLeft(2, '0');
    final seg = (_restante % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.sesion['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Progress Bar Top
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colores.navy.withValues(alpha: 0.05), blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paso ${_actual + 1} de ${_pasos.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colores.navy, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colores.azul.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${((_actual + 1) / _pasos.length * 100).round()}% Completado',
                                style: const TextStyle(color: Colores.azul, fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_actual + 1) / _pasos.length,
                            minHeight: 8,
                            color: Colores.azul,
                            backgroundColor: Colores.azul.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Interactive Step Card
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -200) {
                            // Swipe Left -> Next
                            _irA(_actual + 1);
                          } else if (details.primaryVelocity! > 200 && _actual > 0) {
                            // Swipe Right -> Previous
                            _irA(_actual - 1);
                          }
                        }
                      },
                      child: Card(
                        elevation: 4,
                        shadowColor: Colores.navy.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF0F9FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Card Header Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colores.azul,
                                    child: Text(
                                      '${_actual + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      'Duración: ${_duracion(duracionTotalPaso)}',
                                      style: const TextStyle(fontSize: 12, color: Colores.gris, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),

                              // Exercise Title / Content
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Column(
                                  children: [
                                    Text(
                                      paso['contenido'] as String,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colores.navy,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Mantén la concentración y una respiración fluida.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: Colores.gris),
                                    ),
                                  ],
                                ),
                              ),

                              // Timer Display Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colores.azul.withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(color: Colores.azul.withValues(alpha: 0.08), blurRadius: 10),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$min:$seg',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colores.azul,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          tooltip: _pausado ? 'Reanudar' : 'Pausar',
                                          style: IconButton.styleFrom(
                                            backgroundColor: _pausado ? Colors.green.shade50 : Colors.amber.shade50,
                                            foregroundColor: _pausado ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                          onPressed: _togglePausa,
                                          icon: Icon(_pausado ? Icons.play_arrow : Icons.pause),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          tooltip: 'Reiniciar paso',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colores.fondo,
                                            foregroundColor: Colores.navy,
                                          ),
                                          onPressed: _reiniciarReloj,
                                          icon: const Icon(Icons.refresh),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Card Navigation Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colores.navy,
                            side: const BorderSide(color: Colores.azul, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _actual == 0 ? null : () => _irA(_actual - 1),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Anterior', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colores.azul,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _irA(_actual + 1),
                          icon: Icon(ultimo ? Icons.check_circle : Icons.arrow_forward),
                          label: Text(
                            ultimo ? 'Terminar Sesión' : (_restante == 0 ? 'Siguiente Paso' : 'Saltar Paso'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComoTeFue extends StatefulWidget {
  const _ComoTeFue({required this.sesion});
  final Map<String, dynamic> sesion;

  @override
  State<_ComoTeFue> createState() => _ComoTeFueState();
}

class _ComoTeFueState extends State<_ComoTeFue> {
  int _valoracion = 4;
  double _esfuerzo = 5;
  final _comentario = TextEditingController();
  bool _enviando = false;

  Future<void> _guardar() async {
    setState(() => _enviando = true);
    try {
      await Api.instancia.post('entrenamiento/registros/', {
        'sesion': widget.sesion['codigo'],
        'valoracion': _valoracion,
        'esfuerzo': _esfuerzo.round(),
        'comentario': _comentario.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Sesión registrada con éxito!')));
      Navigator.of(context).pop();
    } on ApiError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.mensaje)));
      setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  String get _etiquetaEsfuerzo {
    final valor = _esfuerzo.round();
    if (valor <= 3) return 'Suave 🌱';
    if (valor <= 6) return 'Moderado ⚖️';
    return 'Exigente 🔥';
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('¿Cómo le fue?'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colores.menta,
                        child: Icon(Icons.emoji_events, color: Colores.navy, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(widget.sesion['titulo'] as String, style: texto.titleLarge?.copyWith(color: Colores.navy, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text('¿Qué tal estuvo la sesión?', style: texto.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            IconButton(
                              iconSize: 36,
                              onPressed: () => setState(() => _valoracion = i),
                              icon: Icon(
                                i <= _valoracion ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: Colores.azul,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Esfuerzo percibido (${_esfuerzo.round()}/10): $_etiquetaEsfuerzo',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colores.navy),
                      ),
                      Slider(
                        value: _esfuerzo,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: Colores.azul,
                        onChanged: (v) => setState(() => _esfuerzo = v),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _comentario,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Comentario u observaciones (opcional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colores.azul,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _enviando ? null : _guardar,
                          child: const Text('Guardar y Finalizar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
