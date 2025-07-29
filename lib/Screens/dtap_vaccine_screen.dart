import 'package:flutter/material.dart';

class DtapVaccineScreen extends StatelessWidget {
  const DtapVaccineScreen({super.key});

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
              title: 'DTaP Vaccine',
              content:
                  'Contains purified inactivated components of bacteria that cause diphtheria, tetanus, and pertussis. '
                  'DTaP is effective in protecting against all three diseases and is given in a series of five doses.',
              extraInfo: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatItem(label: 'Efficacy', value: '95%'),
                  _StatItem(label: 'Doses', value: '5'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Diseases Tackled',
              content:
                  '• Diphtheria: Bacterial infection that can cause difficulty breathing and heart failure.\n'
                  '• Tetanus: Bacterial infection that affects the nervous system.\n'
                  '• Pertussis: Also known as whooping cough, severe coughing fits can develop breathing problems in infants.',
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
                  Row(children: [Text('1st Dose'), Spacer(), Text('2 months')]),
                  Row(children: [Text('2nd Dose'), Spacer(), Text('4 months')]),
                  Row(children: [Text('3rd Dose'), Spacer(), Text('6 months')]),
                  Row(
                    children: [
                      Text('4th Dose'),
                      Spacer(),
                      Text('15-18 months'),
                    ],
                  ),
                  Row(
                    children: [Text('5ht Dose'), Spacer(), Text('4-6 years')],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Side Effects',
              content:
                  '• Common (mild):\n'
                  '  - Fever\n'
                  '  - Redness, swelling, or pain at the injection site\n'
                  '  - Tiredness or irritability\n\n'
                  '• Moderate:\n'
                  '  - Persistent crying\n'
                  '  - Seizure (often from fever)\n\n'
                  '• Severe (very rare):\n'
                  '  - Allergic reaction (hives, swelling of face)\n'
                  '  - Breathing difficulty\n'
                  '  - Brain inflammation (encephalopathy)',
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
