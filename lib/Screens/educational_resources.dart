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
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Color(0xFF4ECDC4),
              radius: 18,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryTab(categories[index]);
                    },
                  ),
                ),
                SizedBox(height: 20.0),
                Container(height: 1, color: Colors.grey[200]),
              ],
            ),
          ),

          // Vaccine Cards
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: vaccineData[selectedCategory]?.length ?? 0,
              itemBuilder: (context, index) {
                final vaccine = vaccineData[selectedCategory]![index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
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
    Widget? targetScreen;

    switch (routeName) {
      case 'dtap':
        targetScreen = DtapVaccineScreen();
        break;
      case 'polio':
        targetScreen = PolioVaccineScreen();
        break;
      case 'bcg':
        targetScreen = BcgVaccineScreen();
        break;
      case 'Meningococcal':
        targetScreen = MenacwyVaccineScreen();
        break;
      case 'hepititis':
        targetScreen = InfluenzaVaccineScreen();
        break;
      case 'hpv':
        targetScreen = HpvVaccineScreen();
        break;
      case 'meningococcal':
        targetScreen = CovidVaccineScreen();
        break;
      default:
        // Fallback to a generic vaccine screen or show an error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screen for ${routeName} not yet implemented'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  Widget _buildCategoryTab(String category) {
    final isSelected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4ECDC4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccineCard(VaccineInfo vaccine, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age Group Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.child_care,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              selectedCategory,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            if (vaccine.isRecommended)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Vaccine Name
                        Text(
                          vaccine.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Description
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

              SizedBox(height: 16),

              // Bottom Row
              Row(
                children: [
                  Text(
                    vaccine.doses,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
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
