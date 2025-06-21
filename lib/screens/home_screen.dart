import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/medication.dart';
import '../services/database_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Medication> _medications = [];
  List<Map<String, dynamic>> _todayLogs = [];
  bool _isLoading = true;
  bool _hasInitialized = false;

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

      if (mounted) {
        setState(() {
          _medications = medications;
          _todayLogs = todayLogs;
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

        // Prioritize today over tomorrow
        if (aIsToday && !bIsToday) {
          return -1;
        }
        if (!aIsToday && bIsToday) {
          return 1;
        }

        // If both are same day, compare times
        final aMinutes = aNextTime.hour * 60 + aNextTime.minute;
        final bMinutes = bNextTime.hour * 60 + bNextTime.minute;

        final result = aMinutes.compareTo(bMinutes);
        return result;
      });

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

  String _getNextDoseTime() {
    if (_medications.isEmpty) return 'Dorilar yo\'q';

    final sortedMedications = _sortMedicationsByNextTime(_medications);
    if (sortedMedications.isNotEmpty) {
      return _getNextTimeText(sortedMedications.first);
    }
    return 'Dorilar yo\'q';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 16),
                  Text(
                    'Ma\'lumotlar yuklanmoqda...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF6366F1),
              child: CustomScrollView(
                slivers: [
                  // Header section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medication_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Dorilar ro\'yxati',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_medications.length} ta dori mavjud',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_medications.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Navbatdagi doza: ${_getNextDoseTime()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Medications list
                  if (_medications.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.medication_outlined,
                                size: 64,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Hech qanday dori qo\'shilmagan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Birinchi dorini qo\'shish uchun\n"➕ Dori qo\'shish" tugmasini bosing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                final mainScreenState = context
                                    .findAncestorStateOfType<MainScreenState>();
                                mainScreenState?.setCurrentIndex(1);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Dori qo\'shish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final medication = _sortMedicationsByNextTime(
                            _medications,
                          )[index];
                          return _buildMedicationCard(medication);
                        }, childCount: _medications.length),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final isTakenToday = _isMedicationTakenToday(medication.id!);
    final nextTimeText = _getNextTimeText(medication);
    final times = _parseTimes(medication.times);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isTakenToday
                    ? [
                        const Color(0xFF10B981).withValues(alpha: 0.1),
                        const Color(0xFF059669).withValues(alpha: 0.1),
                      ]
                    : [
                        const Color(0xFF6366F1).withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTakenToday
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTakenToday
                        ? Icons.check_circle
                        : Icons.medication_outlined,
                    color: isTakenToday
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (isTakenToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Ichildi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medication.dosage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            nextTimeText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vaqtlar:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: times.map((time) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              time.format(context),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (!isTakenToday)
                  ElevatedButton.icon(
                    onPressed: () => _markAsTaken(medication),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Ichildi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(medication),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('O\'chirish'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showEditDialog(medication),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Tahrirlash'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dori o\'chirish'),
        content: Text('${medication.name} ni o\'chirishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteMedication(medication.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🗑️ ${medication.name} o\'chirildi'),
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
  }

  Future<void> _showEditDialog(Medication medication) async {
    // Implement the logic to show the edit dialog
  }
}
