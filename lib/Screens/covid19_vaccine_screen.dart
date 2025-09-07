import 'package:flutter/material.dart';

class CovidVaccineScreen extends StatelessWidget {
  const CovidVaccineScreen({super.key});

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
