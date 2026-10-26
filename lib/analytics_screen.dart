import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      decoration: p.bgDecoration,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.green.withValues(alpha: 0.15),
                  child: const Icon(CupertinoIcons.person_fill,
                      color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700),
                    children: [
                      const TextSpan(
                          text: 'KUmedFarm\n',
                          style: TextStyle(color: AppColors.teal)),
                      TextSpan(
                          text: 'Analitika',
                          style: TextStyle(color: p.text)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border)),
                  child: Icon(CupertinoIcons.bell_fill,
                      color: p.text, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Oylik tashrif',
                          style: TextStyle(
                              color: p.text,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.circle, size: 8, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text('Haftalik tashrif',
                          style: TextStyle(color: p.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 180, child: _BarChart()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                    child: _RingCard(
                        title: 'Bajarilgan reja: 84%',
                        value: 0.84,
                        center: '84%',
                        sub: 'Bajarilgan',
                        color: AppColors.green)),
                SizedBox(width: 12),
                Expanded(
                    child: _RingCard(
                        title: 'Tashriflar soni: 45 ta',
                        value: 0.6,
                        center: '45 ta',
                        sub: 'Tashriflar',
                        color: AppColors.blue)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Yangi bildirishnomalar',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.text)),
            const SizedBox(height: 10),
            const _Notice(
                icon: CupertinoIcons.mail_solid,
                title: 'Tizim:',
                text: 'Bugungi rejangiz yangilandi'),
            const SizedBox(height: 8),
            const _Notice(
                icon: CupertinoIcons.sparkles,
                title: 'AI:',
                text: 'Rasm tahlili yakunlandi'),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart();

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    const labels = ['Oyli', 'Nov', 'Mar', 'Ayi', 'Koh', 'Hon'];
    const values = [55.0, 100.0, 100.0, 70.0, 120.0, 145.0];
    return BarChart(
      duration: const Duration(milliseconds: 900),
      BarChartData(
        maxY: 160,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (_) => FlLine(
              color: p.muted.withValues(alpha: 0.15), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 40,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: TextStyle(color: p.muted, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[v.toInt()],
                    style: TextStyle(color: p.muted, fontSize: 11)),
              ),
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i],
                width: 20,
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.blue, AppColors.green],
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _RingCard extends StatelessWidget {
  final String title, center, sub;
  final double value;
  final Color color;
  const _RingCard(
      {required this.title,
      required this.value,
      required this.center,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GlassCard(
      child: Column(
        children: [
          Text(title,
              style: TextStyle(color: p.muted, fontSize: 11)),
          const SizedBox(height: 12),
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 10,
            percent: value,
            animation: true,
            animationDuration: 1200,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: color,
            backgroundColor: p.cardAlt,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(center,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
                Text(sub,
                    style: TextStyle(fontSize: 10, color: p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const _Notice({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                      text: '$title ',
                      style: TextStyle(
                          color: p.text, fontWeight: FontWeight.w700)),
                  TextSpan(
                      text: text,
                      style: TextStyle(color: p.muted)),
                ],
              ),
            ),
          ),
          Text('now',
              style: TextStyle(color: p.muted, fontSize: 11)),
        ],
      ),
    );
  }
}
