import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = [
      _SalesData('السبت', 5200),
      _SalesData('الأحد', 7400),
      _SalesData('الإثنين', 6100),
      _SalesData('الثلاثاء', 8900),
      _SalesData('الأربعاء', 7600),
      _SalesData('الخميس', 10200),
      _SalesData('الجمعة', 12450),
    ];

    final maxValue = sales.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المبيعات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'آخر 7 أيام',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const Spacer(),

              TextButton(onPressed: () {}, child: const Text('التقارير')),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ...sales.map((item) {
                  final height = (item.value / maxValue) * 150;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(item.value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            height: height,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E4C4C),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            item.day,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesData {
  final String day;
  final double value;

  const _SalesData(this.day, this.value);
}
