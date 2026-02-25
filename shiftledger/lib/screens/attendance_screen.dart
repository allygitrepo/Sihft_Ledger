import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employee_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../models/attendance_model.dart';
import '../models/settings_model.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  final Map<String, bool> presentMap = {};
  final Map<String, TextEditingController> hoursControllers = {};
  final Map<String, TextEditingController> overtimeControllers = {};
  final Map<String, TextEditingController> unitsControllers = {};

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in hoursControllers.values) {
      controller.dispose();
    }
    for (var controller in overtimeControllers.values) {
      controller.dispose();
    }
    for (var controller in unitsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final settings = ref.watch(settingsProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveAttendance(context, ref, settings),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(context),
          Expanded(
            child: employeeState.employees.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: EdgeInsets.all(horizontalPadding),
                    itemCount: employeeState.employees.length,
                    itemBuilder: (context, index) {
                      final employee = employeeState.employees[index];
                      return _buildEmployeeCard(
                        context,
                        employee,
                        settings.attendanceType,
                        settings,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, employee, AttendanceType type, SettingsModel settings) {
    final isPresent = presentMap[employee.id] ?? false;

    // Initialize controllers if not exists
    if (!hoursControllers.containsKey(employee.id)) {
      hoursControllers[employee.id] = TextEditingController();
    }
    if (!overtimeControllers.containsKey(employee.id)) {
      overtimeControllers[employee.id] = TextEditingController();
    }
    if (!unitsControllers.containsKey(employee.id)) {
      unitsControllers[employee.id] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Code: ${employee.employeeCode}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isPresent,
                  onChanged: (value) {
                    setState(() {
                      presentMap[employee.id] = value;
                    });
                  },
                ),
              ],
            ),
            if (isPresent) ...[
              const SizedBox(height: 12),
              if (type == AttendanceType.hourly) ...[
                // For hourly, only ask for overtime hours
                TextField(
                  controller: overtimeControllers[employee.id],
                  decoration: InputDecoration(
                    labelText: 'Overtime Hours (Optional)',
                    hintText: 'Enter overtime hours (e.g., 2)',
                    helperText: 'Regular hours: ${settings.minimumHours}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.timer),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ] else if (type == AttendanceType.daily) ...[
                // For daily, also allow overtime in hours
                TextField(
                  controller: overtimeControllers[employee.id],
                  decoration: const InputDecoration(
                    labelText: 'Overtime Hours (Optional)',
                    hintText: 'Enter overtime hours (e.g., 2)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ] else if (type == AttendanceType.unit) ...[
                TextField(
                  controller: unitsControllers[employee.id],
                  decoration: const InputDecoration(
                    labelText: 'Units Produced',
                    hintText: 'Enter units (e.g., 50)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add employees first to mark attendance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        presentMap.clear();
        // Clear all controllers
        for (var controller in hoursControllers.values) {
          controller.clear();
        }
        for (var controller in overtimeControllers.values) {
          controller.clear();
        }
        for (var controller in unitsControllers.values) {
          controller.clear();
        }
      });
    }
  }

  Future<void> _saveAttendance(BuildContext context, WidgetRef ref, SettingsModel settings) async {
    final employees = ref.read(employeeProvider).employees;
    
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employees to save attendance for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int savedCount = 0;
    
    for (final employee in employees) {
      final isPresent = presentMap[employee.id] ?? false;
      
      double? hoursWorked;
      double? overtimeHours;
      int? unitsProduced;
      
      if (settings.attendanceType == AttendanceType.hourly) {
        // For hourly: use minimum hours as regular hours
        hoursWorked = isPresent ? settings.minimumHours : null;
        
        // Get overtime from controller
        overtimeHours = overtimeControllers[employee.id]?.text.isNotEmpty == true
            ? double.tryParse(overtimeControllers[employee.id]!.text)
            : null;
      } else if (settings.attendanceType == AttendanceType.daily) {
        // For daily: also support overtime in hours
        overtimeHours = overtimeControllers[employee.id]?.text.isNotEmpty == true
            ? double.tryParse(overtimeControllers[employee.id]!.text)
            : null;
      } else if (settings.attendanceType == AttendanceType.unit) {
        // For unit: get units produced
        unitsProduced = unitsControllers[employee.id]?.text.isNotEmpty == true
            ? int.tryParse(unitsControllers[employee.id]!.text)
            : null;
      }
      
      final attendance = AttendanceModel(
        id: '${employee.id}_${selectedDate.millisecondsSinceEpoch}',
        employeeId: employee.id,
        date: selectedDate,
        present: isPresent,
        hoursWorked: hoursWorked,
        unitProduced: unitsProduced,
        overtimeHours: overtimeHours,
      );

      await ref.read(attendanceProvider.notifier).addAttendance(attendance);
      savedCount++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved for $savedCount employees'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
