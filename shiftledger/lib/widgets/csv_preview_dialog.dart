import 'package:flutter/material.dart';
import '../models/csv_employee_preview.dart';
import '../models/employee_model.dart';
import '../utills/app_colors.dart';

class CsvPreviewDialog extends StatefulWidget {
  final List<CsvEmployeePreview> previews;
  final List<CsvEmployeePreview> duplicates;

  const CsvPreviewDialog({
    super.key,
    required this.previews,
    required this.duplicates,
  });

  @override
  State<CsvPreviewDialog> createState() => _CsvPreviewDialogState();
}

class _CsvPreviewDialogState extends State<CsvPreviewDialog> {
  // Default overtime settings
  OvertimeType defaultOvertimeType = OvertimeType.hourwise;
  double defaultOvertimeRate = 100.0;
  List<OvertimeSlot> defaultOvertimeSlots = [
    const OvertimeSlot(startHour: 0, endHour: 2, rate: 100),
    const OvertimeSlot(startHour: 2, endHour: 5, rate: 150),
    const OvertimeSlot(startHour: 5, endHour: 10, rate: 200),
  ];

  @override
  void initState() {
    super.initState();
    // Apply default settings to all previews
    for (var preview in widget.previews) {
      // Set default overtime settings
      preview.overtimeType = defaultOvertimeType;
      preview.overtimeRate = defaultOvertimeRate;
      preview.overtimeSlots = List.from(defaultOvertimeSlots);
      
      // Ensure rates are calculated if not set
      if (preview.hourlyRate == null) {
        preview.hourlyRate = preview.salary / 208; // 26 days * 8 hours
      }
      if (preview.dailyRate == null) {
        preview.dailyRate = preview.salary / 26; // 26 working days
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 1000 ? 900.0 : screenWidth * 0.9;

    return Dialog(
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.preview, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'CSV Import Preview & Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    _buildSummary(),
                    const SizedBox(height: 20),

                    // Default Overtime Settings
                    _buildDefaultOvertimeSettings(),
                    const SizedBox(height: 20),

                    // Employee List
                    _buildEmployeeList(),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: widget.previews.isEmpty
                        ? null
                        : () => Navigator.pop(context, true),
                    icon: const Icon(Icons.upload),
                    label: Text(
                      'Import ${widget.previews.length} Employee${widget.previews.length > 1 ? 's' : ''}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Import Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Total in CSV: ${widget.previews.length + widget.duplicates.length}'),
          Text(
            '✅ New employees: ${widget.previews.length}',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          if (widget.duplicates.isNotEmpty)
            Text(
              '⚠️  Duplicates (will be skipped): ${widget.duplicates.length}',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.calculate, size: 16, color: Colors.blue),
              SizedBox(width: 6),
              Text(
                'Salary Calculation Methods:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.access_time, size: 12, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Hour-wise',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Salary = Working Hours × Hourly Rate',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.calendar_today, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Day-wise',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Salary = Full Day Rate or Half Day (Rate ÷ 2)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultOvertimeSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Default Overtime Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These settings will be applied to all employees by default',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Overtime Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overtime Type',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setDropdownState) {
                        return DropdownButtonFormField<OvertimeType>(
                          value: defaultOvertimeType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: OvertimeType.hourwise,
                              child: Text('Hourwise'),
                            ),
                            DropdownMenuItem(
                              value: OvertimeType.slotwise,
                              child: Text('Slotwise'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                defaultOvertimeType = value;
                                // Apply to all employees
                                for (var preview in widget.previews) {
                                  if (!preview.useCustomOvertime) {
                                    preview.overtimeType = value;
                                  }
                                }
                              });
                              setDropdownState(() {});
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (defaultOvertimeType == OvertimeType.hourwise)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overtime Rate (₹/hour)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: defaultOvertimeRate.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final rate = double.tryParse(value) ?? 100.0;
                          setState(() {
                            defaultOvertimeRate = rate;
                            // Apply to all employees
                            for (var preview in widget.previews) {
                              if (!preview.useCustomOvertime) {
                                preview.overtimeRate = rate;
                              }
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Slotwise settings
          if (defaultOvertimeType == OvertimeType.slotwise) ...[
            const SizedBox(height: 16),
            const Text(
              'Overtime Slots',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...defaultOvertimeSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${slot.startHour}-${slot.endHour} hrs'),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: slot.rate.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixText: '₹/hr',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final rate = double.tryParse(value) ?? slot.rate;
                          setState(() {
                            defaultOvertimeSlots[index] = OvertimeSlot(
                              startHour: slot.startHour,
                              endHour: slot.endHour,
                              rate: rate,
                            );
                            // Apply to all employees
                            for (var preview in widget.previews) {
                              if (!preview.useCustomOvertime) {
                                preview.overtimeSlots = List.from(defaultOvertimeSlots);
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee Configuration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure employee type and rates for each employee',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // Employee cards
        ...widget.previews.map((preview) => _buildEmployeeCard(preview)),

        // Duplicates
        if (widget.duplicates.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Duplicates (Will be skipped)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.duplicates.map((preview) => _buildDuplicateCard(preview)),
        ],
      ],
    );
  }

  Widget _buildEmployeeCard(CsvEmployeePreview preview) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: preview.employeeType == EmployeeType.hourly 
              ? Colors.blue 
              : Colors.green,
          child: Icon(
            preview.employeeType == EmployeeType.hourly 
                ? Icons.access_time 
                : Icons.calendar_today,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                preview.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: preview.employeeType == EmployeeType.hourly
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: preview.employeeType == EmployeeType.hourly
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                preview.employeeType == EmployeeType.hourly ? 'Hour-wise' : 'Day-wise',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: preview.employeeType == EmployeeType.hourly
                      ? Colors.blue[700]
                      : Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${preview.employeeCode} • ${preview.position} • ${preview.department}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '₹${preview.salary.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Type & Salary Calculation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calculate, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Text(
                            'Salary Calculation Method',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Employee Type',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'How to calculate work salary',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                StatefulBuilder(
                                  builder: (context, setDropdownState) {
                                    return DropdownButtonFormField<EmployeeType>(
                                      value: preview.employeeType,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: EmployeeType.hourly,
                                          child: Text('Hourly (Hours × Rate)'),
                                        ),
                                        DropdownMenuItem(
                                          value: EmployeeType.daily,
                                          child: Text('Daily (Days × Rate)'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            preview.employeeType = value;
                                          });
                                          setDropdownState(() {});
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preview.employeeType == EmployeeType.hourly
                                      ? 'Hourly Rate (₹/hour)'
                                      : 'Daily Rate (₹/day)',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preview.employeeType == EmployeeType.hourly
                                      ? 'Calculated from monthly salary'
                                      : 'Calculated from monthly salary',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: ValueKey('${preview.employeeCode}_${preview.employeeType}'),
                                  initialValue: preview.employeeType == EmployeeType.hourly
                                      ? (preview.hourlyRate?.toStringAsFixed(2) ?? '')
                                      : (preview.dailyRate?.toStringAsFixed(2) ?? ''),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    suffixText: preview.employeeType == EmployeeType.hourly ? '₹/hr' : '₹/day',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final rate = double.tryParse(value);
                                    setState(() {
                                      if (preview.employeeType == EmployeeType.hourly) {
                                        preview.hourlyRate = rate;
                                      } else {
                                        preview.dailyRate = rate;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                preview.employeeType == EmployeeType.hourly
                                    ? 'Hourly: Salary = Working Hours × Hourly Rate'
                                    : 'Daily: Salary = Full Day Rate or Half Day Rate (Rate ÷ 2)',
                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Custom Overtime Toggle
                CheckboxListTile(
                  value: preview.useCustomOvertime,
                  onChanged: (value) {
                    setState(() {
                      preview.useCustomOvertime = value ?? false;
                      if (!preview.useCustomOvertime) {
                        // Reset to default
                        preview.overtimeType = defaultOvertimeType;
                        preview.overtimeRate = defaultOvertimeRate;
                        preview.overtimeSlots = List.from(defaultOvertimeSlots);
                      }
                    });
                  },
                  title: const Text(
                    'Use Custom Overtime Settings',
                    style: TextStyle(fontSize: 13),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

                // Custom Overtime Settings
                if (preview.useCustomOvertime) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setDropdownState) {
                                  return DropdownButtonFormField<OvertimeType>(
                                    value: preview.overtimeType,
                                    decoration: const InputDecoration(
                                      labelText: 'OT Type',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: OvertimeType.hourwise,
                                        child: Text('Hourwise'),
                                      ),
                                      DropdownMenuItem(
                                        value: OvertimeType.slotwise,
                                        child: Text('Slotwise'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          preview.overtimeType = value;
                                        });
                                        setDropdownState(() {});
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (preview.overtimeType == OvertimeType.hourwise)
                              Expanded(
                                child: TextFormField(
                                  initialValue: preview.overtimeRate.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'OT Rate (₹/hr)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final rate = double.tryParse(value) ?? 100.0;
                                    setState(() {
                                      preview.overtimeRate = rate;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateCard(CsvEmployeePreview preview) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.orange.withValues(alpha: 0.1),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.warning, color: Colors.orange, size: 20),
        title: Text(
          preview.name,
          style: const TextStyle(
            fontSize: 14,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${preview.employeeCode} • ${preview.position}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '₹${preview.salary.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
