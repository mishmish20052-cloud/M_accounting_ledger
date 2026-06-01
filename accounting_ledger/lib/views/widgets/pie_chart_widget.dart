// lib/views/widgets/pie_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatefulWidget {
  final Map<String, double> data;
  final String title;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _touchedIndex = -1;

  static const _colors = [
    Color(0xFF1A73E8),
    Color(0xFF34A853),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF9C27B0),
    Color(0xFFFF6D00),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFF8BC34A),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = widget.data.values.fold<double>(0, (s, v) => s + v);

    if (entries.isEmpty) {
      return Center(
        child: Text('No data', style: theme.textTheme.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final isTouched = i == _touchedIndex;
                final pct = total > 0 ? (entry.value / total * 100) : 0;
                return PieChartSectionData(
                  color: _colors[i % _colors.length],
                  value: entry.value,
                  title: '${pct.toStringAsFixed(1)}%',
                  radius: isTouched ? 65 : 55,
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 13 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (response == null ||
                        response.touchedSection == null ||
                        !event.isInterestedForInteractions) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: entries.asMap().entries.map((e) {
            final i = e.key;
            final entry = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colors[i % _colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.key} (${entry.value.toStringAsFixed(0)})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
