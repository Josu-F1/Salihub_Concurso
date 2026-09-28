import 'package:flutter/material.dart';

import '../api.dart';
import '../modelos.dart';
import '../tema.dart';
import 'carta_revelada.dart';
import 'checkin_swipe.dart';
import 'coleccion.dart';
import 'historial.dart';
import 'sesion.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final api = Api.instancia;
  late Future<_Datos> _datos = _cargar();

  Future<_Datos> _cargar() async {
    final respuestas = await Future.wait([
      api.get('perfil/'),
      api.get('indice/hoy/'),
      api.get('entrenamiento/sesion-del-dia/'),
      api.get('indice/historial/?dias=14'),
      api.get('entrenamiento/registros/'),
    ]);
    return _Datos(
      perfil: respuestas[0] as Map<String, dynamic>,
      indice: respuestas[1] as Map<String, dynamic>,
      sesionDelDia: respuestas[2] as Map<String, dynamic>,
      semana: (respuestas[3] as List).cast<Map<String, dynamic>>(),
      registros: (respuestas[4] is List) ? (respuestas[4] as List).cast<Map<String, dynamic>>() : [],
    );
  }

  void _recargar() => setState(() => _datos = _cargar());

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
    _recargar();
  }

  void _moverDia(int dias) {
    api.diasAdelante.value = dias;
    _recargar();
  }

  Future<void> _cambiarDisciplina(String disc) async {
    await api.put('perfil/', {'disciplina': disc});
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colores.azul.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Colores.azul, size: 22),
            ),
            const SizedBox(width: 8),
            const Text('SaliHub', style: TextStyle(fontWeight: FontWeight.bold, color: Colores.navy)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mi Colección (Álbum)',
            icon: const Icon(Icons.style, color: Colores.navy),
            onPressed: () => _abrir(const ColeccionPantalla()),
          ),
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history, color: Colores.navy),
            onPressed: () => _abrir(const PantallaHistorial()),
          ),
          PopupMenuButton<int>(
            tooltip: 'Simular otro día',
            icon: const Icon(Icons.calendar_month_outlined, color: Colores.navy),
            onSelected: _moverDia,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0, child: Text('Hoy')),
              PopupMenuItem(value: 1, child: Text('Simular mañana (+1 día)')),
              PopupMenuItem(value: 2, child: Text('Simular +2 días')),
              PopupMenuItem(value: 3, child: Text('Simular +3 días')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_Datos>(
        future: _datos,
        builder: (context, estado) {
          if (estado.hasError) return _SinConexion(error: '${estado.error}', reintentar: _recargar);
          if (!estado.hasData) return const Center(child: CircularProgressIndicator());
          final datos = estado.data!;
          final discActual = datos.perfil['disciplina'] ?? 'bienestar';
          final esWebAncho = MediaQuery.of(context).size.width > 920;

          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderPerfil(context, datos, discActual),
                      const SizedBox(height: 20),
                      if (esWebAncho)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Today's Actions)
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _TarjetaIndice(
                                    indice: datos.indice,
                                    semana: datos.semana,
                                    alHacerCheckin: () => _abrir(const CheckInSwipePantalla()),
                                  ),
                                  const SizedBox(height: 16),
                                  _TarjetaSesion(datos: datos.sesionDelDia, alAbrir: _abrir),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Column (Advanced Analytics Dashboard)
                            Expanded(
                              flex: 6,
                              child: _DashboardEstadisticas(
                                semana: datos.semana,
                                registros: datos.registros,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _TarjetaIndice(
                              indice: datos.indice,
                              semana: datos.semana,
                              alHacerCheckin: () => _abrir(const CheckInSwipePantalla()),
                            ),
                            const SizedBox(height: 16),
                            _TarjetaSesion(datos: datos.sesionDelDia, alAbrir: _abrir),
                            const SizedBox(height: 20),
                            _DashboardEstadisticas(
                              semana: datos.semana,
                              registros: datos.registros,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderPerfil(BuildContext context, _Datos datos, String discActual) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colores.navy.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colores.azul.withValues(alpha: 0.15),
                  child: const Text('👤', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${datos.perfil['nombre']}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Modo: ${datos.perfil['enfoque'] ?? "Deportista"}',
                        style: const TextStyle(color: Colores.gris, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colores.fondo,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: discActual,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colores.navy),
              items: const [
                DropdownMenuItem(value: 'bienestar', child: Text('🌱 Bienestar General')),
                DropdownMenuItem(value: 'runner', child: Text('🏃 Runner / Atletismo')),
                DropdownMenuItem(value: 'ciclista', child: Text('🚴 Ciclismo / MTB')),
                DropdownMenuItem(value: 'crossfitter', child: Text('🏋️ CrossFit / HIIT')),
              ],
              onChanged: (val) {
                if (val != null) _cambiarDisciplina(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Datos {
  _Datos({
    required this.perfil,
    required this.indice,
    required this.sesionDelDia,
    required this.semana,
    required this.registros,
  });
  final Map<String, dynamic> perfil;
  final Map<String, dynamic> indice;
  final Map<String, dynamic> sesionDelDia;
  final List<Map<String, dynamic>> semana;
  final List<Map<String, dynamic>> registros;
}

class _TarjetaIndice extends StatelessWidget {
  const _TarjetaIndice({
    required this.indice,
    required this.semana,
    required this.alHacerCheckin,
  });
  final Map<String, dynamic> indice;
  final List<Map<String, dynamic>> semana;
  final VoidCallback alHacerCheckin;

  Map<String, dynamic>? _obtenerAyer() {
    if (semana.isEmpty) return null;
    final hoyHecho = indice['hecho'] == true;
    if (hoyHecho && semana.length >= 2) {
      return semana[semana.length - 2];
    } else if (!hoyHecho && semana.isNotEmpty) {
      return semana.last;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final ayer = _obtenerAyer();
    final ayerScore = ayer != null ? (ayer['indice'] as int?) : null;

    if (indice['hecho'] != true) {
      return Card(
        elevation: 2,
        shadowColor: Colores.navy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Su Readiness Index', style: texto.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colores.azul.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Diario', style: TextStyle(color: Colores.azul, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Responda preguntas táctiles para registrar cómo llega hoy.'),
              const SizedBox(height: 14),
              // Comparison badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows, size: 20, color: Colores.azul),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                          children: [
                            const TextSpan(text: 'Comparativa: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ayerScore != null ? 'Ayer ($ayerScore pts) ' : 'Ayer (Sin registro) '),
                            const TextSpan(text: '➜ Hoy: '),
                            const TextSpan(text: 'Pendiente ⏳', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colores.azul,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: alHacerCheckin,
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Hacer check-in de hoy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final nivel = indice['nivel'] as Map<String, dynamic>;
    final color = Color(colorDesdeHex(nivel['color'] as String));
    final int hoyScore = (indice['indice'] as int?) ?? 50;
    final int? dif = ayerScore != null ? (hoyScore - ayerScore) : null;

    return Card(
      elevation: 2,
      shadowColor: Colores.navy.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: hoyScore / 100,
                          strokeWidth: 8,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.15),
                        ),
                      ),
                      Text('$hoyScore', style: texto.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 28)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Readiness Index', style: texto.labelMedium?.copyWith(color: Colores.gris)),
                      Text(nivel['nombre'] as String, style: texto.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        indice['aviso'] as String,
                        style: texto.bodySmall?.copyWith(color: Colores.gris, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Yesterday vs Today Comparison Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    dif == null || dif >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: dif == null || dif >= 0 ? Colors.green.shade700 : Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'Comparativa: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (ayerScore != null) ...[
                            TextSpan(text: 'Ayer ($ayerScore pts) ➜ Hoy ($hoyScore pts)  '),
                            TextSpan(
                              text: dif! >= 0 ? '+$dif pts 📈 (Mejor)' : '$dif pts 📉 (Mayor fatiga)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dif >= 0 ? Colors.green.shade700 : Colors.amber.shade900,
                              ),
                            ),
                          ] else ...[
                            TextSpan(text: 'Primer registro ($hoyScore pts)'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (indice['carta'] != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colores.azul, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    CartaModel? carta;
                    if (indice['carta'] != null) {
                      carta = CartaModel.fromJson(indice['carta']);
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CartaReveladaPantalla(
                          carta: carta,
                          indice: hoyScore,
                          nivelNombre: nivel['nombre'] ?? 'Moderado',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.style, size: 18, color: Colores.azul),
                  label: const Text('Ver Carta del Día Desbloqueada', style: TextStyle(color: Colores.navy, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({required this.datos, required this.alAbrir});
  final Map<String, dynamic> datos;
  final Future<void> Function(Widget) alAbrir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final sesion = datos['sesion'] as Map<String, dynamic>?;
    return Card(
      elevation: 3,
      shadowColor: Colores.navy.withValues(alpha: 0.15),
      color: Colores.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HOY RECOMENDAMOS', style: texto.labelMedium?.copyWith(color: Colores.menta, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const Icon(Icons.fitness_center, color: Colores.menta, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            if (sesion == null)
              Text(datos['motivo'] as String, style: const TextStyle(color: Colors.white))
            else ...[
              Text(sesion['titulo'] as String, style: texto.titleLarge?.copyWith(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                '${sesion['categoria']} · ${sesion['duracion_min']}-${sesion['duracion_max']} min · Intensidad ${sesion['intensidad']}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(datos['mensaje'] as String, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colores.menta,
                    foregroundColor: Colores.navy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => alAbrir(PantallaSesion(codigo: sesion['codigo'] as String)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    datos['terminada_hoy'] == true ? 'Ya la hizo hoy · Ver sesión' : 'Iniciar sesión guiada',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardEstadisticas extends StatefulWidget {
  const _DashboardEstadisticas({required this.semana, required this.registros});
  final List<Map<String, dynamic>> semana;
  final List<Map<String, dynamic>> registros;

  @override
  State<_DashboardEstadisticas> createState() => _DashboardEstadisticasState();
}

class _DashboardEstadisticasState extends State<_DashboardEstadisticas> {
  int? _diaSeleccionado;

  @override
  Widget build(BuildContext context) {
    final dias = widget.semana;
    if (dias.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Todavía no hay check-ins registrados para mostrar estadísticas.'),
        ),
      );
    }

    final scores = dias.map((d) => (d['indice'] as int?) ?? 0).toList();
    final prom = (scores.reduce((a, b) => a + b) / scores.length).round();
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final diasOptimos = dias.where((d) => ((d['indice'] as int?) ?? 0) >= 80).length;

    final Map<String, dynamic> diaDetalle = (_diaSeleccionado != null && _diaSeleccionado! < dias.length)
        ? dias[_diaSeleccionado!]
        : dias.last;

    return Column(
      children: [
        // 1. Interactive Readiness Trend Chart Card
        Card(
          elevation: 2,
          shadowColor: Colores.navy.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tendencia de Rendimiento',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colores.navy),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Evolución del Readiness Index (Últimos días)',
                          style: TextStyle(color: Colores.gris, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colores.azul.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Promedio: $prom pts',
                        style: const TextStyle(color: Colores.azul, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Chart Bars Area
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < dias.length; i++) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _diaSeleccionado = i);
                            },
                            child: _BarraGraficaItem(
                              dia: dias[i],
                              esSeleccionado: (diaDetalle['fecha'] == dias[i]['fecha']),
                            ),
                          ),
                        ),
                        if (i < dias.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Selected Day Info Box
                _buildDetalleDiaBox(diaDetalle),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Key Performance Indicators Grid
        Row(
          children: [
            Expanded(
              child: _KpiStatCard(
                titulo: 'Promedio 14d',
                valor: '$prom pts',
                subtitulo: 'Nivel ${prom >= 80 ? "Óptimo 🚀" : prom >= 65 ? "Bueno 💪" : "Moderado ⚖️"}',
                icono: Icons.insights,
                color: Colores.azul,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiStatCard(
                titulo: 'Mejor Récord',
                valor: '$maxScore pts',
                subtitulo: 'Mínimo: $minScore pts',
                icono: Icons.workspace_premium,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiStatCard(
                titulo: 'Días Óptimos',
                valor: '$diasOptimos / ${dias.length}',
                subtitulo: '${((diasOptimos / dias.length) * 100).round()}% en máxima energía',
                icono: Icons.bolt,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiStatCard(
                titulo: 'Entrenos Hechos',
                valor: '${widget.registros.length} Sesiones',
                subtitulo: 'Registradas en la app',
                icono: Icons.fitness_center,
                color: Colores.navy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetalleDiaBox(Map<String, dynamic> dia) {
    final score = (dia['indice'] as int?) ?? 50;
    final fecha = (dia['fecha'] as String? ?? '');
    final fechaFormateada = fecha.length >= 10 ? '${fecha.substring(8)}/${fecha.substring(5, 7)}' : fecha;
    final nivel = dia['nivel'] is Map ? (dia['nivel']['nombre'] ?? '') : 'Moderado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colores.azul.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colores.azul.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app, size: 16, color: Colores.azul),
              const SizedBox(width: 6),
              Text(
                'Día $fechaFormateada:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colores.navy),
              ),
              const SizedBox(width: 6),
              Text('$nivel ($score pts)', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          const Text(
            'Toca una barra para inspeccionar 👆',
            style: TextStyle(fontSize: 11, color: Colores.gris),
          ),
        ],
      ),
    );
  }
}

class _BarraGraficaItem extends StatelessWidget {
  const _BarraGraficaItem({required this.dia, required this.esSeleccionado});
  final Map<String, dynamic> dia;
  final bool esSeleccionado;

  @override
  Widget build(BuildContext context) {
    final score = (dia['indice'] as int?) ?? 50;
    final fecha = (dia['fecha'] as String? ?? '');
    final diaTexto = fecha.length >= 10 ? fecha.substring(8) : fecha;

    // Color gradient based on score
    List<Color> gradient;
    if (score >= 80) {
      gradient = [const Color(0xFF0681FB), const Color(0xFF10B981)];
    } else if (score >= 65) {
      gradient = [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    } else if (score >= 50) {
      gradient = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    } else {
      gradient = [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
    }

    final double altura = (score / 100) * 92 + 10;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Score Badge on Top of Bar
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: esSeleccionado ? 1.0 : 0.75,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: esSeleccionado ? Colores.navy : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: esSeleccionado ? Colores.navy : Colors.grey.shade300),
              boxShadow: esSeleccionado
                  ? [BoxShadow(color: Colores.navy.withValues(alpha: 0.2), blurRadius: 4)]
                  : [],
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: esSeleccionado ? Colors.white : Colores.navy,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Bar with Gradient Fill
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: altura,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
            border: esSeleccionado
                ? Border.all(color: Colores.navy, width: 2)
                : Border.all(color: Colors.transparent),
            boxShadow: esSeleccionado
                ? [BoxShadow(color: gradient.first.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          diaTexto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.normal,
            color: esSeleccionado ? Colores.navy : Colores.gris,
          ),
        ),
      ],
    );
  }
}

class _KpiStatCard extends StatelessWidget {
  const _KpiStatCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colores.navy.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 12, color: Colores.gris, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colores.navy),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SinConexion extends StatelessWidget {
  const _SinConexion({required this.error, required this.reintentar});
  final String error;
  final VoidCallback reintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colores.gris),
            const SizedBox(height: 12),
            const Text('No se pudo conectar con el API.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('¿Está corriendo en $apiUrl?', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colores.gris, fontSize: 12)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: reintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
