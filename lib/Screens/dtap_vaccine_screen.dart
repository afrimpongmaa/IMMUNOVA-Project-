import 'package:flutter/material.dart';

class DtapVaccineScreen extends StatelessWidget {
  const DtapVaccineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'VACCINE INFORMATION',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44B3A3)],
                    ),
                  ),
                  child: const Icon(Icons.vaccines, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            if (extraInfo != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.25),
                  ),
                ),
                child: extraInfo!,
              ),
            ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            color: Color(0xFF4ECDC4),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
