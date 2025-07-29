import 'package:flutter/material.dart';

class CovidVaccineScreen extends StatelessWidget {
  const CovidVaccineScreen({super.key});

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
              title: 'COVID-19 Vaccine',
              content:
                  'Protects against the coronavirus disease (COVID-19) caused by the SARS-CoV-2 virus. '
                  'Available as mRNA, viral vector, and inactivated vaccines. Helps reduce severe illness, hospitalization, and death.',
              extraInfo: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatItem(label: 'Efficacy', value: '70–95%'),
                  _StatItem(label: 'Doses', value: '2–3'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Diseases Tackled',
              content:
                  '• COVID-19: Highly contagious respiratory illness caused by SARS-CoV-2.\n'
                  '• Symptoms range from mild (fever, cough) to severe (pneumonia, organ failure).\n'
                  '• Can lead to long COVID and complications in high-risk individuals.\n'
                  '• Vaccination reduces risk of severe disease and spread.',
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
                        'Dose Type',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        'Timing',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Primary Series'),
                      Spacer(),
                      Text('2 doses (3–4 weeks apart)'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Booster (1st)'),
                      Spacer(),
                      Text('6 months after primary'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Booster (Annual)'),
                      Spacer(),
                      Text('Recommended yearly'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Side Effects',
              content:
                  '• Common:\n'
                  '  - Pain or swelling at injection site\n'
                  '  - Fever, chills, fatigue\n'
                  '  - Headache or muscle aches\n\n'
                  '• Rare:\n'
                  '  - Allergic reaction\n'
                  '  - Myocarditis (mostly in young males, with mRNA vaccines)\n\n'
                  '• Most side effects are mild and short-lived',
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
