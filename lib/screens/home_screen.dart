import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/medication.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_medication_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  List<Medication> _medications = [];
  List<Map<String, dynamic>> _todayLogs = [];
  bool _isLoading = true;
  bool _hasInitialized = false;
  bool _hasActiveNotifications = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load data once when the screen is first created
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medications = await _databaseService.getAllMedications();
      final todayLogs = await _databaseService.getTodayLogs();
      final pendingNotifications = await _notificationService
          .getPendingNotifications();

      if (mounted) {
        setState(() {
          _medications = medications;
          _todayLogs = todayLogs;
          _hasActiveNotifications = pendingNotifications.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ma\'lumotlarni yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsTaken(Medication medication) async {
    try {
      await _databaseService.logMedicationTaken(medication.id!);
      await _loadData(); // Reload data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${medication.name} ichildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<TimeOfDay> _parseTimes(String timesJson) {
    try {
      final List<dynamic> timesList = jsonDecode(timesJson);
      return timesList.map((timeMap) {
        return TimeOfDay(hour: timeMap['hour'], minute: timeMap['minute']);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  bool _isMedicationTakenToday(int medicationId) {
    return _todayLogs.any((log) => log['medicationId'] == medicationId);
  }

  List<Medication> _sortMedicationsByNextTime(List<Medication> medications) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    print('Current time: ${currentTime.format(context)}');
    print('Sorting ${medications.length} medications...');

    final sorted = List<Medication>.from(medications)
      ..sort((a, b) {
        final aTimes = _parseTimes(a.times);
        final bTimes = _parseTimes(b.times);

        if (aTimes.isEmpty && bTimes.isEmpty) return 0;
        if (aTimes.isEmpty) return 1;
        if (bTimes.isEmpty) return -1;

        // Find next time for medication A
        TimeOfDay? aNextTime;
        bool aIsToday = true;

        // First try to find a future time today
        for (final time in aTimes) {
          if (_isTimeAfter(time, currentTime)) {
            aNextTime = time;
            aIsToday = true;
            break;
          }
        }

        // If no future time today, use first time tomorrow
        if (aNextTime == null) {
          aNextTime = aTimes.first;
          aIsToday = false;
        }

        // Find next time for medication B
        TimeOfDay? bNextTime;
        bool bIsToday = true;

        // First try to find a future time today
        for (final time in bTimes) {
          if (_isTimeAfter(time, currentTime)) {
            bNextTime = time;
            bIsToday = true;
            break;
          }
        }

        // If no future time today, use first time tomorrow
        if (bNextTime == null) {
          bNextTime = bTimes.first;
          bIsToday = false;
        }

        print(
          '${a.name}: ${aIsToday ? "Today" : "Tomorrow"} ${aNextTime.format(context)}',
        );
        print(
          '${b.name}: ${bIsToday ? "Today" : "Tomorrow"} ${bNextTime.format(context)}',
        );

        // Prioritize today over tomorrow
        if (aIsToday && !bIsToday) {
          print('${a.name} comes first (today vs tomorrow)');
          return -1;
        }
        if (!aIsToday && bIsToday) {
          print('${b.name} comes first (today vs tomorrow)');
          return 1;
        }

        // If both are same day, compare times
        final aMinutes = aNextTime.hour * 60 + aNextTime.minute;
        final bMinutes = bNextTime.hour * 60 + bNextTime.minute;

        final result = aMinutes.compareTo(bMinutes);
        print('Time comparison: ${aMinutes} vs ${bMinutes} = $result');
        return result;
      });

    print('Sorted medications:');
    for (int i = 0; i < sorted.length; i++) {
      final med = sorted[i];
      final nextTimeText = _getNextTimeText(med);
      print('${i + 1}. ${med.name} - $nextTimeText');
    }

    return sorted;
  }

  bool _isTimeAfter(TimeOfDay time, TimeOfDay currentTime) {
    final timeMinutes = time.hour * 60 + time.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    return timeMinutes > currentMinutes;
  }

  String _getNextTimeText(Medication medication) {
    final times = _parseTimes(medication.times);
    if (times.isEmpty) return 'Vaqt belgilanmagan';

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // Find next time
    TimeOfDay? nextTime;
    bool isToday = true;

    for (final time in times) {
      if (_isTimeAfter(time, currentTime)) {
        nextTime = time;
        isToday = true;
        break;
      }
    }

    if (nextTime == null) {
      // If no future time today, show first time of tomorrow
      nextTime = times.first;
      isToday = false;
    }

    if (isToday) {
      return 'Bugun ${nextTime.format(context)}';
    } else {
      return 'Ertaga ${nextTime.format(context)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('🏠 Bosh sahifa'),
      //   backgroundColor: Colors.blue,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   flexibleSpace: Container(
      //     decoration: const BoxDecoration(
      //       gradient: LinearGradient(
      //         begin: Alignment.topLeft,
      //         end: Alignment.bottomRight,
      //         colors: [Colors.blue, Colors.lightBlue],
      //       ),
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: _loadData,
      //       tooltip: 'Yangilash',
      //     ),
      //   ],
      // ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text('Yuklanmoqda...'),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Navbatdagi doza
                    if (_medications.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue, Colors.lightBlue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      if (_hasActiveNotifications)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '⏰ Navbatdagi doza',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Builder(
                                builder: (context) {
                                  final sortedMedications =
                                      _sortMedicationsByNextTime(_medications);
                                  if (sortedMedications.isNotEmpty) {
                                    final nextMedication =
                                        sortedMedications.first;
                                    final nextTimeText = _getNextTimeText(
                                      nextMedication,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nextMedication.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            nextMedication.dosage,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '🕐 $nextTimeText',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const Text(
                                    'Dorilar mavjud emas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Jami: ${_medications.length} ta dori',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Dorilar ro'yxati
                    if (_medications.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.medication,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '💊 Dorilar ro\'yxati',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._sortMedicationsByNextTime(
                        _medications,
                      ).map((medication) => _buildMedicationCard(medication)),
                    ] else ...[
                      // Empty state
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.medication_outlined,
                                    size: 60,
                                    color: Colors.blue.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Hali dorilar qo\'shilmagan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Dori qo\'shish uchun + tugmasini bosing',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _navigateToAddMedication(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Dori qo\'shish'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: _medications.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _navigateToAddMedication(),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  void _navigateToAddMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );

    // If medication was added successfully, refresh data
    if (result == true) {
      await _loadData();
    }
  }

  Widget _buildMedicationCard(Medication medication) {
    final times = _parseTimes(medication.times);
    final isTakenToday = _isMedicationTakenToday(medication.id!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTakenToday
              ? [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ]
              : [Colors.white, Colors.grey.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isTakenToday
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isTakenToday
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTakenToday
                          ? [Colors.green, Colors.lightGreen]
                          : [Colors.blue, Colors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (isTakenToday ? Colors.green : Colors.blue)
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.medication, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isTakenToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Colors.lightGreen],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '✅ Ichildi',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        medication.dosage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '⏰ ${_getNextTimeText(medication)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Times (only if multiple times)
            if (times.length > 1) ...[
              const Text(
                '🕐 Vaqtlar:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: times.map((time) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      time.format(context),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Notes (only if exists and short)
            if (medication.notes != null &&
                medication.notes!.isNotEmpty &&
                medication.notes!.length < 50) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '📝 ${medication.notes!}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isTakenToday
                            ? [Colors.grey, Colors.grey.shade400]
                            : [Colors.green, Colors.lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isTakenToday ? Colors.grey : Colors.green)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isTakenToday
                          ? null
                          : () => _markAsTaken(medication),
                      icon: Icon(
                        isTakenToday ? Icons.check_circle : Icons.check,
                        size: 16,
                      ),
                      label: Text(
                        isTakenToday ? 'Ichildi' : 'Ichdim',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Edit medication
                    },
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () async {
                      // Delete medication
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Dori o\'chirish'),
                          content: Text(
                            '${medication.name} ni o\'chirishni xohlaysizmi?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Bekor'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('O\'chirish'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await _databaseService.deleteMedication(
                            medication.id!,
                          );
                          await _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '🗑️ ${medication.name} o\'chirildi',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Xatolik: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
