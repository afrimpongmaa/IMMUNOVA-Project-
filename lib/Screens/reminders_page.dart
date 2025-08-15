import 'package:flutter/material.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  int selectedTabIndex = 0;

  final Map<int, List<ReminderItem>> tabData = {
    0: [
      ReminderItem(
        date: '23\nJuly',
        title: 'Polio Vaccine(IPV)',
        subtitle: 'Johnson Amoah',
        time: '3:30pm',
      ),
      ReminderItem(
        date: '23\nJuly',
        title: 'DTaP Vaccine',
        subtitle: 'Julina Owusu',
        time: '1:30pm',
      ),
      ReminderItem(
        date: '23\nJuly',
        title: 'BCG (Bacillus Calmette-Guerin)',
        subtitle: 'Keziah Amoateng',
        time: '12:00pm',
      ),
    ],
    1: [
      ReminderItem(
        date: '11\nJuly',
        title: 'COVID-19 Vaccine',
        subtitle: 'John Konedu',
        time: '8:30am',
      ),
      ReminderItem(
        date: '09\nJuly',
        title: 'Influenza (Flu) Vaccine',
        subtitle: 'Grace Painstil',
        time: '11:30am',
      ),
      ReminderItem(
        date: '01\nJuly',
        title: 'Hepatitis B Vaccine',
        subtitle: 'Kwesi Osei',
        time: '04:00pm',
      ),
    ],
    2: [
      ReminderItem(
        date: '03\nJuly',
        title: 'Meningococcal (MenACWY)',
        subtitle: 'Obeng Kwame',
        time: '3:30pm',
      ),
      ReminderItem(
        date: '13\nJuly',
        title: 'Polio Vaccine(IPV)',
        subtitle: 'Kelvin Asibey',
        time: '1:00pm',
      ),
      ReminderItem(
        date: '22\nJuly',
        title: 'TdaP Vaccine',
        subtitle: 'Greatness Boateng',
        time: '12:00pm',
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
          'REMINDERS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: selectedTabIndex == 0
            ? [
                GestureDetector(
                  onTap: _addReminder,
                  child: Container(
                    margin: EdgeInsets.only(right: 16),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.cyan[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ]
            : [],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTab('UPCOMING', 0),
                SizedBox(width: 20),
                _buildTab('COMPLETED', 1),
                SizedBox(width: 20),
                _buildTab('OVERDUE', 2),
              ],
            ),
          ),

          // Today Section
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              _getSectionTitle(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Reminders List
          Expanded(
            child: Container(color: Colors.white, child: _buildRemindersList()),
          ),
        ],
      ),
    );
  }

  String _getSectionTitle() {
    switch (selectedTabIndex) {
      case 0:
        return 'TODAY';
      case 1:
        return 'COMPLETED';
      case 2:
        return 'OVERDUE';
      default:
        return 'TODAY';
    }
  }

  Widget _buildRemindersList() {
    List<ReminderItem> currentItems = tabData[selectedTabIndex] ?? [];

    if (currentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No reminders found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: currentItems.length,
      itemBuilder: (context, index) {
        final item = currentItems[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 50),
          child: GestureDetector(
            onLongPress: () => _deleteReminder(index),
            child: _buildReminderCard(
              date: item.date,
              title: item.title,
              subtitle: item.subtitle,
              time: item.time,
              isCompleted: selectedTabIndex == 1,
              isOverdue: selectedTabIndex == 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan[300] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String date,
    required String title,
    required String subtitle,
    required String time,
    bool isCompleted = false,
    bool isOverdue = false,
  }) {
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[200]!;
    Color dateBackgroundColor = Colors.transparent;

    if (isCompleted) {
      borderColor = Colors.green[200]!;
    } else if (isOverdue) {
      borderColor = Colors.red[200]!;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: dateBackgroundColor,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  height: 1.2,
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isOverdue ? Colors.red[400] : Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue ? Colors.red[400] : Colors.grey[600],
                      ),
                    ),
                    if (isOverdue) ...[
                      SizedBox(width: MediaQuery.sizeOf(context).width * .5),
                      Icon(
                        Icons.warning_rounded,
                        size: 16,
                        color: Colors.red[400],
                      ),
                    ],
                    if (isCompleted) ...[
                      SizedBox(width: MediaQuery.sizeOf(context).width * .5),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[400],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addReminder() {
    final _dateController = TextEditingController();
    final _titleController = TextEditingController();
    final _subtitleController = TextEditingController();
    final _timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Reminder"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dateController,
                decoration: InputDecoration(labelText: 'Date (e.g, 5th Aug)'),
              ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Vaccine Name'),
              ),
              TextField(
                controller: _subtitleController,
                decoration: InputDecoration(labelText: 'Patient Name'),
              ),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time (e.g., 10:00am)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_dateController.text.isNotEmpty &&
                  _titleController.text.isNotEmpty &&
                  _subtitleController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty) {
                setState(() {
                  tabData[0]?.add(
                    ReminderItem(
                      date: _dateController.text,
                      title: _titleController.text,
                      subtitle: _subtitleController.text,
                      time: _timeController.text,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteReminder(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Reminder"),
        content: Text("Do you want to delete this reminder?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                tabData[selectedTabIndex]!.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class ReminderItem {
  final String date;
  final String title;
  final String subtitle;
  final String time;

  ReminderItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
