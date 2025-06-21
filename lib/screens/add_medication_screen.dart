import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/medication.dart';
import '../services/database_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();

  final List<TimeOfDay> _selectedTimes = [];
  int _frequency = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (!_selectedTimes.contains(picked)) {
          _selectedTimes.add(picked);
          _selectedTimes.sort(
            (a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute),
          );
        }
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kamida bitta vaqt tanlang'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert times to JSON string
      final timesJson = jsonEncode(
        _selectedTimes
            .map((time) => {'hour': time.hour, 'minute': time.minute})
            .toList(),
      );

      final medication = Medication(
        name: _medicationNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        times: timesJson,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final id = await _databaseService.insertMedication(medication);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Dori muvaffaqiyatli qo\'shildi! (ID: $id)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        print('Dori muvaffaqiyatli qo\'shildi! (ID: $id)');

        // Clear form
        _clearForm();

        // Navigate back to home screen and refresh
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e, stack) {
      print('Medication add error: $e');
      print('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Xatolik yuz berdi: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print('Xatolik yuz berdi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
    _medicationNameController.clear();
    _dosageController.clear();
    _notesController.clear();
    setState(() {
      _selectedTimes.clear();
      _frequency = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ Dori qo\'shish'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Saqlanmoqda...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.medication, color: Colors.green, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yangi dori qo\'shish',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Barcha maydonlarni to\'ldiring',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dori nomi
                  TextFormField(
                    controller: _medicationNameController,
                    decoration: InputDecoration(
                      labelText: '💊 Dori nomi',
                      hintText: 'Masalan: Paracetamol',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.medication),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.05),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dori nomini kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dozalash
                  TextFormField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: '📏 Dozalash',
                      hintText: 'Masalan: 500mg, 1 tabletka',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.straighten),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.05),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dozalashni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kunlik ichish soni
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                '🕐 Kunlik ichish soni',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_frequency > 1) {
                                    setState(() {
                                      _frequency--;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 32,
                                ),
                                color: _frequency > 1
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_frequency marta',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _frequency++;
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 32,
                                ),
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vaqt tanlash
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                '⏰ Vaqt tanlash',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Selected times
                          if (_selectedTimes.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTimes.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final time = entry.value;
                                return Chip(
                                  label: Text(
                                    time.format(context),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blue,
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onDeleted: () => _removeTime(index),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Add time button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.add),
                              label: const Text('Vaqt qo\'shish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Eslatma
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '📝 Eslatma (ixtiyoriy)',
                      hintText: 'Qo\'shimcha ma\'lumotlar...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.05),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Saqlash tugmasi
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saveMedication,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        '💾 Saqlash',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
