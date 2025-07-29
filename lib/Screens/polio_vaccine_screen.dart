import 'package:flutter/material.dart';

class PolioVaccineScreen extends StatelessWidget {
  const PolioVaccineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('VACCINE INFORMATION'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoCard(
              title: 'Polio Vaccine',
              content:
                  'Protects against poliomyelitis (polio), a viral infection that can cause paralysis and even death. '
                  'Two types are used: IPV (inactivated polio vaccine) and OPV (oral polio vaccine). Given in multiple doses during childhood.',
              extraInfo: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatItem(label: 'Efficacy', value: '99%'),
                  _StatItem(label: 'Doses', value: '4'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Diseases Tackled',
              content:
                  '• Poliomyelitis: A highly infectious viral disease that can cause permanent paralysis.\n'
                  '• Mostly affects children under 5 years of age.\n'
                  '• Transmitted through contaminated water or food.\n'
                  '• The virus can invade the nervous system.',
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Dosage Schedule',
              content: '',
              extraInfo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Text(
                        'Dose',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        'Age Given',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(children: [Text('1st Dose'), Spacer(), Text('6 weeks')]),
                  Row(children: [Text('2nd Dose'), Spacer(), Text('10 weeks')]),
                  Row(children: [Text('3rd Dose'), Spacer(), Text('14 weeks')]),
                  Row(
                    children: [
                      Text('Booster Dose'),
                      Spacer(),
                      Text('4–6 years'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Side Effects',
              content:
                  '• IPV (injection):\n'
                  '  - Redness or soreness at injection site\n'
                  '  - Mild fever\n\n'
                  '• OPV (oral):\n'
                  '  - Very rare risk of vaccine-derived polio virus\n\n'
                  '• Severe reactions are extremely rare',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.vaccines),
            label: 'Vaccines',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Resources'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final Widget? extraInfo;

  const _InfoCard({required this.title, required this.content, this.extraInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vaccines),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content.isNotEmpty) Text(content),
            if (extraInfo != null) ...[const SizedBox(height: 12), extraInfo!],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            color: Color.fromRGBO(128, 255, 255, 100),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
