import 'package:flutter/material.dart';
import 'package:immunova/Screens/add_patient_page.dart';
import 'package:immunova/Screens/covid19_vaccine_screen.dart';
import 'package:immunova/Screens/dtap_vaccine_screen.dart';
import 'package:immunova/Screens/influenza_vaccine_screen.dart';
import 'package:immunova/Screens/polio_vaccine_screen.dart';
import 'package:immunova/Screens/bcg_vaccine_screen.dart';
import 'package:immunova/Screens/menacwy_vaccine_screen.dart';
import 'package:immunova/Screens/hpv_vaccine_screen.dart';
import 'package:immunova/Screens/patient_records.dart';
import 'package:immunova/Screens/profile.dart';
import 'package:immunova/Screens/setting_page.dart';

class EducationalResourcesPage extends StatefulWidget {
  const EducationalResourcesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EducationalResourcesPageState createState() =>
      _EducationalResourcesPageState();
}

class _EducationalResourcesPageState extends State<EducationalResourcesPage> {
  String selectedCategory = 'Infants(0-1yr)';
  int selectedBottomNavIndex = 1; // Default to 'Resources' tab

  final List<String> categories = [
    'Infants(0-1yr)',
    'Toddlers(1-3yrs)',
    'Adolescents',
  ];

  final Map<String, List<VaccineInfo>> vaccineData = {
    'Infants(0-1yr)': [
      VaccineInfo(
        name: 'DTaP Vaccine',
        description: 'Protects against tetanus, diphtheria and pertussis.',
        doses: '5 DOSES',
        isRecommended: true,
        routeName: 'dtap',
      ),
      VaccineInfo(
        name: 'Polio Vaccine(IPV)',
        description: 'Protects against poliomyelitis.',
        doses: '5 DOSES',
        isRecommended: true,
        routeName: 'polio',
      ),
      VaccineInfo(
        name: 'BCG (Bacillus Calmette-Guérin)',
        description: 'Protects against severe forms of tuberculosis.',
        doses: '1 DOSE',
        isRecommended: true,
        routeName: 'bcg',
      ),
    ],
    'Toddlers(1-3yrs)': [
      VaccineInfo(
        name: 'Meningococcal Vaccine',
        description: 'Protects against measles, mumps, and rubella.',
        doses: '2 DOSES',
        isRecommended: true,
        routeName: 'Meningococcal',
      ),
      VaccineInfo(
        name: 'Influenza Flu Vaccine',
        description: 'Protects against chickenpox.',
        doses: '2 DOSES',
        isRecommended: true,
        routeName: 'hepititis',
      ),
    ],
    'Adolescents': [
      VaccineInfo(
        name: 'HPV Vaccine',
        description: 'Protects against human papillomavirus.',
        doses: '3 DOSES',
        isRecommended: true,
        routeName: 'hpv',
      ),
      VaccineInfo(
        name: 'Covid-19 Vaccine',
        description: 'Protects against meningococcal disease.',
        doses: '2 DOSES',
        isRecommended: true,
        routeName: 'meningococcal',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'EDUCATIONAL RESOURCES',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorProfileScreen(),
              ),
            ),
            child: Container(
              margin: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Color(0xFF4ECDC4),
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // New Hero Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44B3A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn. Guide. Immunize.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Curated vaccine insights by age group.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vaccines, topics...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF4ECDC4)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryChip(categories[index]),
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[200]),
              ],
            ),
          ),

          // Vaccine Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: vaccineData[selectedCategory]?.length ?? 0,
              itemBuilder: (context, index) {
                final vaccine = vaccineData[selectedCategory]![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildVaccineCard(vaccine, () {
                    _navigateToVaccineScreen(vaccine.routeName);
                  }),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _navigateToVaccineScreen(String routeName) {
    // Show loading indicator first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      ),
    );

    // Simulate loading delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Remove loading dialog

      Widget? targetScreen;
      String title = '';
      String description = '';

      switch (routeName) {
        case 'dtap':
          targetScreen = DtapVaccineScreen();
          title = 'DTaP Vaccine';
          description = 'Comprehensive guide to DTaP vaccination';
          break;
        case 'polio':
          targetScreen = PolioVaccineScreen();
          title = 'Polio Vaccine (IPV)';
          description = 'Essential information about polio immunization';
          break;
        case 'bcg':
          targetScreen = BcgVaccineScreen();
          title = 'BCG Vaccine';
          description = 'Tuberculosis prevention through BCG vaccination';
          break;
        case 'Meningococcal':
          targetScreen = MenacwyVaccineScreen();
          title = 'Meningococcal Vaccine';
          description = 'Protection against meningococcal disease';
          break;
        case 'hepititis':
          targetScreen = InfluenzaVaccineScreen();
          title = 'Influenza Vaccine';
          description = 'Annual flu protection guidelines';
          break;
        case 'hpv':
          targetScreen = HpvVaccineScreen();
          title = 'HPV Vaccine';
          description = 'Human papillomavirus prevention';
          break;
        case 'meningococcal':
          targetScreen = CovidVaccineScreen();
          title = 'COVID-19 Vaccine';
          description = 'Latest COVID-19 vaccination protocols';
          break;
        default:
          _showVaccineInfoModal(routeName);
          return;
      }

      // Show brief info modal before navigating
      _showVaccinePreviewModal(title, description, () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                targetScreen!,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      });
    });
  }

  void _showVaccinePreviewModal(
    String title,
    String description,
    VoidCallback onProceed,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.vaccines,
                size: 32,
                color: Color(0xFF4ECDC4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4ECDC4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onProceed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue Learning',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVaccineInfoModal(String routeName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.construction,
                size: 32,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed information for $routeName is being prepared. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccineCard(VaccineInfo vaccine, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.scale(
        scale: 0.8 + (0.2 * value),
        child: Opacity(
          opacity: value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFF4ECDC4).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF4ECDC4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4ECDC4).withOpacity(0.8),
                                    const Color(0xFF44B3A3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4ECDC4,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.vaccines,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top line with category and badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF4ECDC4,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          selectedCategory,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF4ECDC4),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (vaccine.isRecommended)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF43A047),
                                                Color(0xFF388E3C),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Recommended',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vaccine.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    vaccine.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF4ECDC4,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Color(0xFF4ECDC4),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    vaccine.doses,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4ECDC4),
                                    Color(0xFF44B3A3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4ECDC4,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onTap,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Learn More',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.people, 'Patients', 0),
          _buildBottomNavItem(Icons.description_outlined, 'Resources', 1),
          _buildBottomNavItem(Icons.person_add_outlined, 'Add Patient', 2),
          _buildBottomNavItem(Icons.settings_outlined, 'Settings', 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isActive = selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBottomNavIndex = index;
        });
        _handleBottomNavTap(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF4ECDC4) : Colors.grey[400],
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Color(0xFF4ECDC4) : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PatientRecords()),
        );
        break;
      case 1:
        // Already on Resources page
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPatientScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
    }
  }
}

class VaccineInfo {
  final String name;
  final String description;
  final String doses;
  final bool isRecommended;
  final String routeName;

  VaccineInfo({
    required this.name,
    required this.description,
    required this.doses,
    this.isRecommended = false,
    required this.routeName,
  });
}
