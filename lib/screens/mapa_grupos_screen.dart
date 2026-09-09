import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/grupo_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Coordenada por defecto cuando aún no hay ubicación.
const LatLng _kUbicacionPorDefecto =
    LatLng(10.2135, -64.6329); // Puerto La Cruz, Anzoátegui, Venezuela

/// Paleta fija de colores para distinguir Redes. Es pública (sin guion
/// bajo) para poder usarse también desde grupos_screen.dart y que una
/// red se vea siempre con el mismo color en toda la app.
const List<Color> paletaColoresRed = [
  Color(0xFFE57373), // rojo
  Color(0xFF64B5F6), // azul
  Color(0xFF81C784), // verde
  Color(0xFFFFB74D), // naranja
  Color(0xFFBA68C8), // morado
  Color(0xFF4DD0E1), // cian
  Color(0xFFFFD54F), // amarillo
  Color(0xFFF06292), // rosado
  Color(0xFFA1887F), // marrón
  Color(0xFF90A4AE), // gris azulado
];

/// Devuelve un color para una Red, calculado a partir de su propio ID
/// (no de su posición en una lista). Esto garantiza que una red se vea
/// SIEMPRE con el mismo color sin importar en qué pantalla se muestre
/// ni qué otras redes estén visibles junto a ella en ese momento — a
/// diferencia de una asignación por índice, que puede cambiar de color
/// si cambia el conjunto de redes visibles.
/// El segundo parámetro se conserva por compatibilidad con las llamadas
/// existentes, pero ya no se usa para calcular el color.
Color colorParaRed(String redId, [List<String> idsOrdenados = const []]) {
  if (redId.isEmpty) return AppColors.textoPrimario;
  final indice = redId.hashCode.abs() % paletaColoresRed.length;
  return paletaColoresRed[indice];
}

/// Pantalla que muestra todos los grupos pequeños en un mapa.
class MapaGruposScreen extends StatefulWidget {
  const MapaGruposScreen({super.key});

  @override
  State<MapaGruposScreen> createState() => _MapaGruposScreenState();
}

class _MapaGruposScreenState extends State<MapaGruposScreen> {
  final _service = FirestoreService();
  final _mapController = MapController();
  Grupo? _grupoSeleccionado;
  final Set<String> _lideresOcultos = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Mapa de grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Estadísticas por líder',
            onPressed: _mostrarEstadisticas,
          ),
        ],
      ),
      body: StreamBuilder<List<Grupo>>(
        stream: _service.getGrupos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final todos = snapshot.data ?? [];
          final conUbicacion = todos
              .where((g) => g.latitud != null && g.longitud != null)
              .toList();

          // Lista única de Redes presentes en los grupos con ubicación.
          final Map<String, String> redesMapa = {}; // id -> nombre
          for (final g in conUbicacion) {
            if (g.redId != null && g.redId!.isNotEmpty) {
              redesMapa[g.redId!] = g.redNombre ?? g.redId!;
            }
          }
          // Orden estable para que cada red tenga siempre un color distinto
          // de las demás (y no cambie de color entre refrescos).
          final idsRedesOrdenados = redesMapa.keys.toList()..sort();

          // Se muestra un grupo si su red está visible, o si no tiene
          // red asignada (para no ocultarlo silenciosamente).
          final grupos = conUbicacion.where((g) {
            if (g.redId == null || g.redId!.isEmpty) return true;
            return !_lideresOcultos.contains(g.redId);
          }).toList();

          if (conUbicacion.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined,
                        color: AppColors.textoSecundario, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Todavía no hay grupos con ubicación marcada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textoSecundario, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Edita un grupo y marca su ubicación en el mapa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textoTerciario, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final centro = LatLng(
            conUbicacion.first.latitud!,
            conUbicacion.first.longitud!,
          );

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: 12,
                  onTap: (_, __) =>
                      setState(() => _grupoSeleccionado = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.esdras.app',
                  ),
                  MarkerLayer(
                    markers: grupos.map((g) {
                      final colorMarcador = (g.redId != null &&
                              g.redId!.isNotEmpty)
                          ? colorParaRed(g.redId!, idsRedesOrdenados)
                          : AppColors.textoPrimario;
                      return Marker(
                        point: LatLng(g.latitud!, g.longitud!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _abrirFichaGrupo(
                              context, g, idsRedesOrdenados),
                          child: Icon(
                            Icons.location_on,
                            color: colorMarcador,
                            size: 34,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              if (redesMapa.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: _panelFiltroRedes(redesMapa, idsRedesOrdenados),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _panelFiltroRedes(
      Map<String, String> redesMapa, List<String> idsRedesOrdenados) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: redesMapa.entries.map((entry) {
          final id = entry.key;
          final nombre = entry.value;
          final color = colorParaRed(id, idsRedesOrdenados);
          final oculto = _lideresOcultos.contains(id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                if (oculto) {
                  _lideresOcultos.remove(id);
                } else {
                  _lideresOcultos.add(id);
                }
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: oculto ? AppColors.borde : color,
                    width: oculto ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: oculto ? AppColors.textoTerciario : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      nombre,
                      style: TextStyle(
                        color: oculto
                            ? AppColors.textoTerciario
                            : AppColors.textoPrimario,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration:
                            oculto ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _abrirFichaGrupo(
      BuildContext context, Grupo g, List<String> idsRedesOrdenados) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _FichaGrupo(grupo: g, idsRedesOrdenados: idsRedesOrdenados),
    );
  }

  void _mostrarEstadisticas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StreamBuilder<List<Grupo>>(
        stream: _service.getGrupos(),
        builder: (context, snapshot) {
          final grupos = snapshot.data ?? [];
          return _PanelEstadisticas(grupos: grupos);
        },
      ),
    );
  }
}

class _FichaGrupo extends StatelessWidget {
  final Grupo grupo;
  final List<String> idsRedesOrdenados;
  const _FichaGrupo(
      {required this.grupo, this.idsRedesOrdenados = const []});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      grupo.nombre,
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _chipEstado(grupo.estado),
                ],
              ),
              if (grupo.redNombre != null && grupo.redNombre!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorParaRed(
                                grupo.redId ?? '', idsRedesOrdenados)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: colorParaRed(
                                grupo.redId ?? '', idsRedesOrdenados)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hub_outlined,
                              size: 14,
                              color: colorParaRed(
                                  grupo.redId ?? '', idsRedesOrdenados)),
                          const SizedBox(width: 5),
                          Text(
                            grupo.redNombre!,
                            style: TextStyle(
                              color: colorParaRed(
                                  grupo.redId ?? '', idsRedesOrdenados),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _filaInfo(Icons.location_on_outlined, grupo.direccion),
              _filaInfo(Icons.access_time, grupo.hora),
              const SizedBox(height: 20),
              _seccion('LÍDER(ES) D12'),
              _listaChips(grupo.lideresLineaNombres, AppColors.info),
              const SizedBox(height: 16),
              _seccion('LÍDER(ES) D72'),
              _listaChips(grupo.lideresCedulaNombres, AppColors.exito),
              const SizedBox(height: 16),
              _seccion(
                  'MIEMBROS (${grupo.miembrosNombres.length})'),
              if (grupo.miembrosNombres.isEmpty)
                const Text(
                  'Sin miembros registrados aún',
                  style: TextStyle(
                      color: AppColors.textoSecundario, fontSize: 13),
                )
              else
                ...grupo.miembrosNombres.map(
                  (nombre) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.textoSecundario, size: 16),
                        const SizedBox(width: 8),
                        Text(nombre,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _chipEstado(String estado) {
    final activo = estado.toLowerCase() == 'activo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (activo ? AppColors.exito : AppColors.error)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: activo ? AppColors.exito : AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _filaInfo(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, color: AppColors.textoSecundario, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.textoTerciario,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _listaChips(List<String> nombres, Color color) {
    if (nombres.isEmpty) {
      return const Text(
        'Sin asignar',
        style: TextStyle(color: AppColors.textoSecundario, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nombres
          .map((n) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(n,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }
}

/// Panel de estadísticas: cantidad de células por Líder D12 y por Líder D72.
class _PanelEstadisticas extends StatelessWidget {
  final List<Grupo> grupos;
  const _PanelEstadisticas({required this.grupos});

  @override
  Widget build(BuildContext context) {
    // Conteo por Red (id -> {nombre, cantidad})
    final Map<String, String> nombresRed = {};
    final Map<String, int> conteoRed = {};

    var activas = 0;
    var inactivas = 0;

    for (final g in grupos) {
      if (g.estado.toLowerCase() == 'activo') {
        activas++;
      } else {
        inactivas++;
      }

      if (g.redId != null && g.redId!.isNotEmpty) {
        nombresRed[g.redId!] = g.redNombre ?? g.redId!;
        conteoRed[g.redId!] = (conteoRed[g.redId!] ?? 0) + 1;
      }
    }

    final entradasRed = conteoRed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxRed =
        entradasRed.isEmpty ? 1 : entradasRed.first.value;

    // Orden estable (independiente del orden por cantidad de arriba) para
    // que cada red mantenga siempre el mismo color y nunca coincida con
    // el de otra red en esta misma lista.
    final idsRedesOrdenados = nombresRed.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Estadísticas por red',
                style: TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _tarjetaResumen(
                        'Total células', '${grupos.length}',
                        AppColors.info),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tarjetaResumen(
                        'Activas', '$activas', AppColors.exito),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tarjetaResumen(
                        'Inactivas', '$inactivas', AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'CÉLULAS POR RED',
                style: TextStyle(
                  color: AppColors.textoTerciario,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              if (entradasRed.isNotEmpty)
                const Text(
                  'Toca una red para ver sus células y miembros',
                  style: TextStyle(
                      color: AppColors.textoTerciario, fontSize: 11),
                ),
              const SizedBox(height: 10),
              if (entradasRed.isEmpty)
                const Text('Sin redes asignadas a células aún',
                    style: TextStyle(
                        color: AppColors.textoSecundario, fontSize: 13))
              else
                ...entradasRed.map((e) => _filaBarra(
                      nombre: nombresRed[e.key] ?? e.key,
                      cantidad: e.value,
                      maximo: maxRed,
                      color: colorParaRed(e.key, idsRedesOrdenados),
                      onTap: () {
                        final celulasDeRed = grupos
                            .where((g) => g.redId == e.key)
                            .toList();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => _DetalleRed(
                            nombreRed: nombresRed[e.key] ?? e.key,
                            color: colorParaRed(e.key, idsRedesOrdenados),
                            celulas: celulasDeRed,
                          ),
                        );
                      },
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _tarjetaResumen(String etiqueta, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(valor,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(etiqueta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _filaBarra({
    required String nombre,
    required int cantidad,
    required int maximo,
    required Color color,
    VoidCallback? onTap,
  }) {
    final proporcion = maximo == 0 ? 0.0 : cantidad / maximo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(nombre,
                      style: const TextStyle(
                          color: AppColors.textoPrimario, fontSize: 13)),
                ),
                Text('$cantidad',
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textoTerciario),
                ],
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcion.clamp(0.05, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.fondoInput,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Detalle de una Red: lista sus células con sus miembros.
class _DetalleRed extends StatelessWidget {
  final String nombreRed;
  final Color color;
  final List<Grupo> celulas;

  const _DetalleRed({
    required this.nombreRed,
    required this.color,
    required this.celulas,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nombreRed,
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${celulas.length} ${celulas.length == 1 ? 'célula' : 'células'}',
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (celulas.isEmpty)
                const Text('Esta red no tiene células asignadas',
                    style: TextStyle(
                        color: AppColors.textoSecundario, fontSize: 13))
              else
                ...celulas.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.fondoInput,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borde),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.nombre,
                                  style: const TextStyle(
                                    color: AppColors.textoPrimario,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (c.estado.toLowerCase() ==
                                          'activo'
                                      ? AppColors.exito
                                      : AppColors.error)
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  c.estado,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: c.estado.toLowerCase() ==
                                            'activo'
                                        ? AppColors.exito
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c.direccion} · ${c.hora}',
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'MIEMBROS (${c.miembrosNombres.length})',
                            style: const TextStyle(
                              color: AppColors.textoTerciario,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (c.miembrosNombres.isEmpty)
                            const Text('Sin miembros registrados',
                                style: TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 12))
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: c.miembrosNombres
                                  .map((n) => Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.fondoTarjeta,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                          border: Border.all(
                                              color: AppColors.borde),
                                        ),
                                        child: Text(n,
                                            style: const TextStyle(
                                                color: AppColors
                                                    .textoPrimario,
                                                fontSize: 11)),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

/// Selector de ubicación: se usa dentro del formulario de grupo para
/// escoger o ajustar las coordenadas tocando el mapa.
class SelectorUbicacionMapa extends StatefulWidget {
  final double? latitudInicial;
  final double? longitudInicial;

  const SelectorUbicacionMapa({
    super.key,
    this.latitudInicial,
    this.longitudInicial,
  });

  @override
  State<SelectorUbicacionMapa> createState() =>
      _SelectorUbicacionMapaState();
}

class _SelectorUbicacionMapaState extends State<SelectorUbicacionMapa> {
  late LatLng _punto;
  bool _cargandoUbicacion = false;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _punto = (widget.latitudInicial != null && widget.longitudInicial != null)
        ? LatLng(widget.latitudInicial!, widget.longitudInicial!)
        : _kUbicacionPorDefecto;
  }

  Future<void> _usarMiUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    try {
      final permiso = await Geolocator.checkPermission();
      var permisoFinal = permiso;
      if (permiso == LocationPermission.denied) {
        permisoFinal = await Geolocator.requestPermission();
      }
      if (permisoFinal == LocationPermission.denied ||
          permisoFinal == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final nuevoPunto = LatLng(pos.latitude, pos.longitude);
      setState(() => _punto = nuevoPunto);
      // Sin esto, el marcador se movía a la nueva ubicación pero la
      // cámara del mapa se quedaba donde estaba; move() la hace viajar
      // también hasta ahí.
      _mapController.move(nuevoPunto, 16);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu ubicación'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Marcar ubicación'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, {'lat': _punto.latitude, 'lng': _punto.longitude}),
            child: const Text('Guardar',
                style: TextStyle(color: AppColors.textoPrimario)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _punto,
              initialZoom: 14,
              onTap: (_, punto) => setState(() => _punto = punto),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.esdras.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _punto,
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.location_on,
                        color: AppColors.error, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.fondoTarjeta,
              onPressed: _cargandoUbicacion ? null : _usarMiUbicacion,
              child: _cargandoUbicacion
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.my_location,
                      color: AppColors.textoPrimario),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.fondoTarjeta.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borde),
              ),
              child: const Text(
                'Toca el mapa para marcar dónde se reúne el grupo',
                style: TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
