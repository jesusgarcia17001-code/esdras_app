import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Reportes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('RESUMEN GENERAL'),
            const SizedBox(height: 12),
            _resumenGeneral(),
            const SizedBox(height: 28),
            _tituloSeccion('MIEMBROS POR RED'),
            const SizedBox(height: 12),
            _graficaMiembrosPorRed(),
            const SizedBox(height: 28),
            _tituloSeccion('GRUPOS POR ESTADO'),
            const SizedBox(height: 12),
            _graficaGruposPorEstado(),
            const SizedBox(height: 28),
            _tituloSeccion('ACADEMIA'),
            const SizedBox(height: 12),
            _resumenAcademia(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(titulo,
        style: const TextStyle(
            color: AppColors.textoTerciario,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600));
  }

  Widget _resumenGeneral() {
    return StreamBuilder(
      stream: _service.contarMiembros(),
      builder: (context, snapMiembros) {
        return StreamBuilder(
          stream: _service.contarGrupos(),
          builder: (context, snapGrupos) {
            return StreamBuilder(
              stream: _service.contarLideres(),
              builder: (context, snapLideres) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.8,
                  children: [
                    _cardReporte('Total miembros',
                        '${snapMiembros.data ?? 0}',
                        Icons.people),
                    _cardReporte('Grupos activos',
                        '${snapGrupos.data ?? 0}',
                        Icons.home_work),
                    _cardReporte('Líderes',
                        '${snapLideres.data ?? 0}',
                        Icons.star),
                    _cardReporte('Redes', '—', Icons.hub),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _cardReporte(
      String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.acentoSuave,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borde),
            ),
            child: Icon(icono,
                color: AppColors.textoPrimario, size: 16),
          ),
          const Spacer(),
          Text(valor,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          Text(titulo,
              style: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _graficaMiembrosPorRed() {
    return StreamBuilder(
      stream: _service.getMiembros(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _sinDatos('Cargando...');
        }
        final miembros = snapshot.data!;
        final redes = {
          'Jóvenes': 0, 'Niños': 0, 'Mujeres': 0,
          'Hombres': 0, 'Adultos mayores': 0,
        };
        for (final m in miembros) {
          if (redes.containsKey(m.red)) {
            redes[m.red] = redes[m.red]! + 1;
          }
        }
        final total =
            redes.values.fold(0, (a, b) => a + b);
        if (total == 0) {
          return _sinDatos('Sin miembros registrados aún');
        }

        final colores = [
          AppColors.textoPrimario,
          AppColors.textoSecundario,
          AppColors.bordeActivo,
          Colors.white60,
          Colors.white30,
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 45,
                    sections: redes.entries
                        .toList()
                        .asMap()
                        .entries
                        .where((e) => e.value.value > 0)
                        .map((e) {
                      final color =
                          colores[e.key % colores.length];
                      final pct =
                          e.value.value / total * 100;
                      return PieChartSectionData(
                        color: color,
                        value: e.value.value.toDouble(),
                        title: '${pct.round()}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.fondoPrincipal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: redes.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final color =
                      colores[e.key % colores.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(
                          '${e.value.key}: ${e.value.value}',
                          style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 11)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _graficaGruposPorEstado() {
    return StreamBuilder(
      stream: _service.getGrupos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _sinDatos('Cargando...');
        }
        final grupos = snapshot.data!;
        final estados = {
          'Activo': 0, 'En formación': 0, 'Inactivo': 0,
        };
        for (final g in grupos) {
          if (estados.containsKey(g.estado)) {
            estados[g.estado] = estados[g.estado]! + 1;
          }
        }
        if (grupos.isEmpty) {
          return _sinDatos('Sin grupos registrados aún');
        }

        final colores = {
          'Activo': AppColors.exito,
          'En formación': AppColors.advertencia,
          'Inactivo': AppColors.error,
        };

        final maxVal = estados.values
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment:
                        BarChartAlignment.spaceAround,
                    maxY: maxVal + 1,
                    barTouchData:
                        BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            final labels = [
                              'Activo', 'En form.',
                              'Inactivo'
                            ];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                      top: 6),
                              child: Text(
                                  labels[val.toInt()],
                                  style: const TextStyle(
                                      color: AppColors
                                          .textoSecundario,
                                      fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: estados.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value
                                      .toDouble(),
                                  color: colores[
                                      e.value.key],
                                  width: 40,
                                  borderRadius:
                                      BorderRadius
                                          .circular(6),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: estados.entries.map((e) {
                  final color = colores[e.key]!;
                  return Column(
                    children: [
                      Text('${e.value}',
                          style: TextStyle(
                              color: color,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      Text(e.key,
                          style: const TextStyle(
                              color:
                                  AppColors.textoSecundario,
                              fontSize: 11)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resumenAcademia() {
    return StreamBuilder(
      stream: _service.getNiveles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _sinDatos('Cargando...');
        }
        final niveles = snapshot.data!;
        final totalAlumnos = niveles.fold(
            0, (a, n) => a + n.alumnosIds.length);
        final totalProfesores = niveles.fold(
            0, (a, n) => a + n.profesoresIds.length);

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _cardReporte(
                    'Niveles', '${niveles.length}',
                    Icons.layers)),
                const SizedBox(width: 8),
                Expanded(child: _cardReporte(
                    'Alumnos', '$totalAlumnos',
                    Icons.school)),
                const SizedBox(width: 8),
                Expanded(child: _cardReporte(
                    'Profesores', '$totalProfesores',
                    Icons.person)),
              ],
            ),
            if (niveles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Column(
                  children: niveles.map((n) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.acentoSuave,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.borde),
                            ),
                            child: const Icon(Icons.school,
                                color: AppColors.textoPrimario,
                                size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(n.nombre,
                                style: const TextStyle(
                                    color: AppColors
                                        .textoPrimario,
                                    fontSize: 13)),
                          ),
                          Text(
                              '${n.alumnosIds.length} alumnos',
                              style: const TextStyle(
                                  color: AppColors
                                      .textoSecundario,
                                  fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _sinDatos(String texto) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Center(
        child: Text(texto,
            style: const TextStyle(
                color: AppColors.textoTerciario,
                fontSize: 13)),
      ),
    );
  }
}