import 'package:flutter/material.dart';

class InfluenzaVaccineScreen extends StatelessWidget {
  const InfluenzaVaccineScreen({super.key});

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
              title: 'Influenza (Flu) Vaccine',
              content:
                  'Protects against seasonal influenza viruses that change yearly. Recommended annually for most individuals, especially children, elderly, pregnant women, and those with chronic health conditions.',
              extraInfo: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatItem(label: 'Efficacy', value: '40–60%'),
                  _StatItem(label: 'Doses', value: '1–2 yearly'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Diseases Tackled',
              content:
                  '• Influenza A and B viruses\n'
                  '• Symptoms include fever, cough, sore throat, body aches, fatigue\n'
                  '• Can cause severe illness, pneumonia, hospitalization, and death—especially in high-risk groups',
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
                        'Age Group',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        'Recommended Doses',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('6 months – 8 years'),
                      Spacer(),
                      Text('2 doses (1 month apart)'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('9+ years'),
                      Spacer(),
                      Text('1 dose annually'),
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
                  '  - Soreness, redness, or swelling at injection site\n'
                  '  - Headache, fever, muscle aches\n'
                  '  - Fatigue\n\n'
                  '• Rare:\n'
                  '  - Allergic reaction (rash, difficulty breathing)\n'
                  '  - Guillain-Barré syndrome (extremely rare)',
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
