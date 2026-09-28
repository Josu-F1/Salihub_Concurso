import 'package:flutter/material.dart';
import '../api.dart';
import '../modelos.dart';
import '../tema.dart';

class ColeccionPantalla extends StatefulWidget {
  const ColeccionPantalla({super.key});

  @override
  State<ColeccionPantalla> createState() => _ColeccionPantallaState();
}

class _ColeccionPantallaState extends State<ColeccionPantalla> {
  bool _cargando = true;
  String? _error;
  List<CartaModel> _cartas = [];
  String _filtroDisciplina = 'todas';
  String _filtroCategoria = 'todas';

  @override
  void initState() {
    super.initState();
    _cargarCartas();
  }

  Future<void> _cargarCartas() async {
    try {
      final datos = await Api.instancia.get('cartas/');
      if (datos is List) {
        setState(() {
          _cartas = datos.map((c) => CartaModel.fromJson(c)).toList();
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  List<String> get _categoriasDisponibles {
    final cats = _cartas.map((c) => c.categoria).toSet().toList();
    cats.sort();
    return ['todas', ...cats];
  }

  List<CartaModel> get _cartasFiltradas {
    return _cartas.where((c) {
      final cumpleDisc = _filtroDisciplina == 'todas' || c.disciplina == _filtroDisciplina;
      final cumpleCat = _filtroCategoria == 'todas' || c.categoria == _filtroCategoria;
      return cumpleDisc && cumpleCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mi Colección de Cartas'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEncabezadoResumen(),
                        _buildFiltrosChips(),
                        Expanded(
                          child: _cartasFiltradas.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'No se encontraron cartas con los filtros seleccionados.\n¡Haz tu check-in diario para desbloquear más!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colores.gris, fontSize: 14),
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(20),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 220,
                                    mainAxisExtent: 270,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _cartasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final carta = _cartasFiltradas[index];
                                    return _buildTarjetaMazo(context, carta);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEncabezadoResumen() {
    final cantDoradas = _cartas.where((c) => c.esDorada).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colores.navy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colores.navy.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.style, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Álbum Digital SaliHub',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_cartas.length} cartas desbloqueadas · $cantDoradas destacadas',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro por Disciplina
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chipFiltroDisciplina('todas', 'Todas las Disciplinas'),
                _chipFiltroDisciplina('bienestar', '🌱 Bienestar'),
                _chipFiltroDisciplina('runner', '🏃 Running'),
                _chipFiltroDisciplina('ciclista', '🚴 Ciclismo'),
                _chipFiltroDisciplina('crossfitter', '🏋️ CrossFit'),
              ],
            ),
          ),
          if (_categoriasDisponibles.length > 2) ...[
            const SizedBox(height: 6),
            // Filtro por Categoría
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categoriasDisponibles.map((cat) {
                  final label = cat == 'todas' ? 'Todas las Categorías' : cat;
                  final seleccionada = _filtroCategoria == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: seleccionada,
                      label: Text(label),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: seleccionada ? FontWeight.bold : FontWeight.normal,
                        color: seleccionada ? Colores.azul : Colores.navy,
                      ),
                      backgroundColor: Colores.fondo,
                      selectedColor: Colores.azul.withValues(alpha: 0.15),
                      checkmarkColor: Colores.azul,
                      side: BorderSide(
                        color: seleccionada ? Colores.azul : Colors.grey.shade300,
                      ),
                      onSelected: (val) {
                        setState(() => _filtroCategoria = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipFiltroDisciplina(String clave, String label) {
    final seleccionada = _filtroDisciplina == clave;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: seleccionada,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: seleccionada ? FontWeight.bold : FontWeight.w500,
          color: seleccionada ? Colors.white : Colores.navy,
        ),
        selectedColor: Colores.azul,
        backgroundColor: Colores.fondo,
        side: BorderSide(color: seleccionada ? Colores.azul : Colors.grey.shade300),
        onSelected: (val) {
          if (val) setState(() => _filtroDisciplina = clave);
        },
      ),
    );
  }

  Widget _buildTarjetaMazo(BuildContext context, CartaModel carta) {
    final esDorada = carta.esDorada;

    return GestureDetector(
      onTap: () => _mostrarDetalleCarta(context, carta),
      child: Card(
        elevation: 3,
        shadowColor: Colores.navy.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: esDorada ? Colores.azul : Colores.azul.withValues(alpha: 0.2),
            width: esDorada ? 2.0 : 1.0,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: esDorada
                ? const LinearGradient(
                    colors: [Colors.white, Color(0xFFEBF5FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colores.azul.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(carta.icono, style: const TextStyle(fontSize: 20)),
                  ),
                  if (esDorada)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colores.azul,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text('Destacada', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    Text(carta.fecha, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                carta.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colores.navy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"${carta.frase}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colores.azul.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  carta.categoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colores.azul, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleCarta(BuildContext context, CartaModel carta) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colores.azul.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(carta.icono, style: const TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    carta.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colores.navy),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${carta.frase}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colores.azul.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 16, color: Colores.azul),
                            SizedBox(width: 6),
                            Text('Insight Técnico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colores.navy)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(carta.insight, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.azul,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
