import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/settings_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/employee_provider.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: _buildAttendanceForm(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: _buildAttendanceList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          children: [
            _buildAttendanceForm(),
            const SizedBox(height: 24),
            _buildAttendanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceForm() {
    final formState = ref.watch(attendanceFormProvider);
    final employeeState = ref.watch(employeeProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),

              // Employee Dropdown
              DropdownButtonFormField<EmployeeModel>(
                initialValue: formState.selectedEmployee,
                decoration: const InputDecoration(
                  labelText: 'Select Employee',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: employeeState.employees.map((employee) {
                  return DropdownMenuItem(
                    value: employee,
                    child: Text(employee.name),
                  );
                }).toList(),
                onChanged: (employee) {
                  if (employee != null) {
                    ref.read(attendanceFormProvider.notifier).setEmployee(employee);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(formState.selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attendance Type Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ref.read(attendanceFormProvider.notifier).setAttendanceType(AttendanceType.daywise);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: formState.attendanceType == AttendanceType.daywise
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                formState.attendanceType == AttendanceType.daywise
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: formState.attendanceType == AttendanceType.daywise
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Day-wise',
                                style: TextStyle(
                                  color: formState.attendanceType == AttendanceType.daywise
                                      ? AppColors.primary
                                      : Colors.black87,
                                  fontWeight: formState.attendanceType == AttendanceType.daywise
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ref.read(attendanceFormProvider.notifier).setAttendanceType(AttendanceType.hourwise);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: formState.attendanceType == AttendanceType.hourwise
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                formState.attendanceType == AttendanceType.hourwise
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: formState.attendanceType == AttendanceType.hourwise
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hour-wise',
                                style: TextStyle(
                                  color: formState.attendanceType == AttendanceType.hourwise
                                      ? AppColors.primary
                                      : Colors.black87,
                                  fontWeight: formState.attendanceType == AttendanceType.hourwise
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Day-wise or Hour-wise UI
              if (formState.attendanceType == AttendanceType.daywise)
                _buildDaywiseUI(formState)
              else
                _buildHourwiseUI(formState),

              const SizedBox(height: 16),

              // Overtime UI
              if (formState.settings.overtimeEnabled) _buildOvertimeUI(formState),

              const SizedBox(height: 20),

              // Calculated Values Display
              _buildCalculatedValues(formState),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: formState.isLoading || formState.selectedEmployee == null
                      ? null
                      : () => _saveAttendance(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: formState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Attendance', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaywiseUI(AttendanceFormState formState) {
    return Column(
      children: [
        // Check-in Time
        InkWell(
          onTap: () => _selectTime(context, true),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Check-in Time',
              prefixIcon: Icon(Icons.login),
              border: OutlineInputBorder(),
            ),
            child: Text(
              formState.checkInTime != null
                  ? DateFormat('hh:mm a').format(formState.checkInTime!)
                  : 'Select time',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Check-out Time
        InkWell(
          onTap: () => _selectTime(context, false),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Check-out Time',
              prefixIcon: Icon(Icons.logout),
              border: OutlineInputBorder(),
            ),
            child: Text(
              formState.checkOutTime != null
                  ? DateFormat('hh:mm a').format(formState.checkOutTime!)
                  : 'Select time',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourwiseUI(AttendanceFormState formState) {
    final controller = TextEditingController(
      text: formState.workingHours > 0 ? formState.workingHours.toString() : '',
    );
    
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Working Hours',
        prefixIcon: Icon(Icons.access_time),
        border: OutlineInputBorder(),
        hintText: 'Enter hours (e.g., 8.5)',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final hours = double.tryParse(value) ?? 0.0;
        ref.read(attendanceFormProvider.notifier).setWorkingHours(hours);
      },
    );
  }

  Widget _buildOvertimeUI(AttendanceFormState formState) {
    final controller = TextEditingController(
      text: formState.overtimeHours > 0 ? formState.overtimeHours.toString() : '',
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Overtime Hours',
            prefixIcon: const Icon(Icons.timer),
            border: const OutlineInputBorder(),
            hintText: 'Enter OT hours',
            helperText: formState.settings.overtimeType == OvertimeType.slotwise
                ? 'Rate will be calculated based on slots'
                : 'Rate: ₹${formState.settings.overtimeRate}/hour',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final hours = double.tryParse(value) ?? 0.0;
            ref.read(attendanceFormProvider.notifier).setOvertimeHours(hours);
          },
        ),
      ],
    );
  }

  Widget _buildCalculatedValues(AttendanceFormState formState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Calculated Values',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow('Working Hours', '${formState.calculatedWorkingHours.toStringAsFixed(2)} hrs'),
          _buildInfoRow('Work Salary', '₹${formState.workSalary.toStringAsFixed(2)}'),
          if (formState.settings.overtimeEnabled && formState.overtimeHours > 0) ...[
            _buildInfoRow('OT Hours', '${formState.overtimeHours.toStringAsFixed(2)} hrs'),
            _buildInfoRow('OT Rate', '₹${formState.overtimeRate.toStringAsFixed(2)}/hr'),
            _buildInfoRow('OT Salary', '₹${formState.overtimeSalary.toStringAsFixed(2)}'),
          ],
          const Divider(height: 20),
          _buildInfoRow(
            'Total Salary',
            '₹${formState.totalSalary.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 8),
          _buildStatusChip(formState.attendanceStatus),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue[900] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case AttendanceStatus.fullDay:
        color = Colors.green;
        label = 'Full Day';
        icon = Icons.check_circle;
        break;
      case AttendanceStatus.halfDay:
        color = Colors.orange;
        label = 'Half Day';
        icon = Icons.timelapse;
        break;
      case AttendanceStatus.absent:
        color = Colors.red;
        label = 'Absent';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    final listState = ref.watch(attendanceListProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance Records',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(attendanceListProvider.notifier).loadAttendance();
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (listState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (listState.attendanceRecords.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mark attendance to see records here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listState.attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = listState.attendanceRecords[index];
                  return _buildAttendanceCard(record);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(record.attendanceStatus),
              child: Icon(
                _getStatusIcon(record.attendanceStatus),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.employeeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(record.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.workingHours?.toStringAsFixed(1) ?? 0} hrs • ₹${record.totalSalary?.toStringAsFixed(0) ?? 0}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(record.attendanceStatus),
                const SizedBox(height: 6),
                Text(
                  record.attendanceType == AttendanceType.daywise ? 'Day-wise' : 'Hour-wise',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return Colors.green;
      case AttendanceStatus.halfDay:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return Icons.check_circle;
      case AttendanceStatus.halfDay:
        return Icons.timelapse;
      case AttendanceStatus.absent:
        return Icons.cancel;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final formState = ref.read(attendanceFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: formState.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(attendanceFormProvider.notifier).setDate(picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isCheckIn) async {
    final formState = ref.read(attendanceFormProvider);
    final initialTime = isCheckIn
        ? (formState.checkInTime != null
            ? TimeOfDay.fromDateTime(formState.checkInTime!)
            : const TimeOfDay(hour: 9, minute: 0))
        : (formState.checkOutTime != null
            ? TimeOfDay.fromDateTime(formState.checkOutTime!)
            : const TimeOfDay(hour: 18, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final date = formState.selectedDate;
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      );

      if (isCheckIn) {
        ref.read(attendanceFormProvider.notifier).setCheckIn(dateTime);
      } else {
        ref.read(attendanceFormProvider.notifier).setCheckOut(dateTime);
      }
    }
  }

  Future<void> _saveAttendance() async {
    final success = await ref.read(attendanceFormProvider.notifier).saveAttendance();

    if (!mounted) return;

    if (success) {
      // Refresh attendance list
      ref.read(attendanceListProvider.notifier).loadAttendance();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save attendance. Please check all fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
