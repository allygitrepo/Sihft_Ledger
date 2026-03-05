import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/csv_employee_preview.dart';
import '../models/employee_model.dart';
import '../utills/app_colors.dart';
import '../services/csv_import_service.dart';
import '../providers/employee_provider.dart';
import '../providers/settings_provider.dart';

class CsvPreviewDialog extends ConsumerStatefulWidget {
  final PlatformFile file;

  const CsvPreviewDialog({super.key, required this.file});

  @override
  ConsumerState<CsvPreviewDialog> createState() => _CsvPreviewDialogState();
}

class _CsvPreviewDialogState extends ConsumerState<CsvPreviewDialog> {
  List<CsvEmployeePreview> _previews = [];
  List<CsvEmployeePreview> _duplicates = [];
  bool _isParsing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseCSV();
  }

  Future<void> _parseCSV() async {
    try {
      // Read file content
      String content;
      if (widget.file.bytes != null) {
        content = String.fromCharCodes(widget.file.bytes!);
      } else if (widget.file.path != null) {
        final file = File(widget.file.path!);
        content = await file.readAsString();
      } else {
        throw Exception('Unable to read file content');
      }

      final settings = ref.read(settingsProvider);
      final parsedPreviews = await CsvImportService.parseCSV(content, settings);

      if (parsedPreviews.isEmpty) {
        if (mounted) {
          setState(() {
            _isParsing = false;
            _errorMessage = 'No employee data found in CSV file.';
          });
        }
        return;
      }

      // Check for duplicates
      final existingEmployees = ref.read(employeeProvider).employees;
      final newPreviews = <CsvEmployeePreview>[];
      final duplicatePreviews = <CsvEmployeePreview>[];

      for (final preview in parsedPreviews) {
        final isDuplicate = existingEmployees.any(
          (e) =>
              e.employeeCode.toLowerCase() ==
              preview.employeeCode.toLowerCase(),
        );
        if (isDuplicate) {
          duplicatePreviews.add(preview);
        } else {
          // Initialize rates
          if (preview.hourlyRate == null) {
            preview.hourlyRate = preview.salary / 208;
          }
          if (preview.dailyRate == null) {
            preview.dailyRate = preview.salary / 26;
          }
          newPreviews.add(preview);
        }
      }

      if (mounted) {
        setState(() {
          _previews = newPreviews;
          _duplicates = duplicatePreviews;
          _isParsing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isParsing = false;
          _errorMessage = 'Error parsing CSV: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 1000 ? 900.0 : screenWidth * 0.9;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.preview, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'CSV Import Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
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
              child: _isParsing
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary
                          _buildSummary(theme),
                          const SizedBox(height: 20),

                          // Employee List
                          _buildEmployeeList(theme),
                        ],
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.cardColor.withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        _isParsing || _previews.isEmpty || _errorMessage != null
                        ? null
                        : () {
                            final employees = _previews
                                .map((p) => p.toEmployeeModel())
                                .toList();
                            Navigator.pop(context, employees);
                          },
                    icon: const Icon(Icons.upload),
                    label: Text(
                      _isParsing
                          ? 'Processing...'
                          : 'Import ${_previews.length} Employee${_previews.length > 1 ? 's' : ''}',
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

  Widget _buildSummary(ThemeData theme) {
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
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Import Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total in CSV: ${_previews.length + _duplicates.length}',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
          Text(
            '✅ New employees: ${_previews.length}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_duplicates.length > 0)
            Text(
              '⚠️  Duplicates (will be skipped): ${_duplicates.length}',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employee Configuration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure employee type and rates for each employee',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 12),

        // Employee cards
        ..._previews.map((preview) => _buildEmployeeCard(preview, theme)),

        // Duplicates
        if (_duplicates.length > 0) ...[
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
          ..._duplicates.map((preview) => _buildDuplicateCard(preview, theme)),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Parsing CSV file...',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            widget.file.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Parsing Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(CsvEmployeePreview preview, ThemeData theme) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
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
                preview.employeeType == EmployeeType.hourly
                    ? 'Hour-wise'
                    : 'Day-wise',
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
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
                      // Make responsive - stack on mobile, row on larger screens
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;

                          if (isMobile) {
                            // Stack vertically on mobile
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Employee Type',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'How to calculate work salary',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StatefulBuilder(
                                      builder: (context, setDropdownState) {
                                        return DropdownButtonFormField<
                                          EmployeeType
                                        >(
                                          value: preview.employeeType,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: EmployeeType.hourly,
                                              child: Text(
                                                'Hourly (Hours × Rate)',
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: EmployeeType.daily,
                                              child: Text(
                                                'Daily (Days × Rate)',
                                              ),
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
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      preview.employeeType ==
                                              EmployeeType.hourly
                                          ? 'Hourly Rate (₹/hour)'
                                          : 'Daily Rate (₹/day)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Calculated from monthly salary',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      key: ValueKey(
                                        '${preview.employeeCode}_${preview.employeeType}',
                                      ),
                                      initialValue:
                                          preview.employeeType ==
                                              EmployeeType.hourly
                                          ? (preview.hourlyRate
                                                    ?.toStringAsFixed(2) ??
                                                '')
                                          : (preview.dailyRate?.toStringAsFixed(
                                                  2,
                                                ) ??
                                                ''),
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        suffixText:
                                            preview.employeeType ==
                                                EmployeeType.hourly
                                            ? '₹/hr'
                                            : '₹/day',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        final rate = double.tryParse(value);
                                        setState(() {
                                          if (preview.employeeType ==
                                              EmployeeType.hourly) {
                                            preview.hourlyRate = rate;
                                          } else {
                                            preview.dailyRate = rate;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            // Row layout for larger screens
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Employee Type',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'How to calculate work salary',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      StatefulBuilder(
                                        builder: (context, setDropdownState) {
                                          return DropdownButtonFormField<
                                            EmployeeType
                                          >(
                                            value: preview.employeeType,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: EmployeeType.hourly,
                                                child: Text(
                                                  'Hourly (Hours × Rate)',
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: EmployeeType.daily,
                                                child: Text(
                                                  'Daily (Days × Rate)',
                                                ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preview.employeeType ==
                                                EmployeeType.hourly
                                            ? 'Hourly Rate (₹/hour)'
                                            : 'Daily Rate (₹/day)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Calculated from monthly salary',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        key: ValueKey(
                                          '${preview.employeeCode}_${preview.employeeType}',
                                        ),
                                        initialValue:
                                            preview.employeeType ==
                                                EmployeeType.hourly
                                            ? (preview.hourlyRate
                                                      ?.toStringAsFixed(2) ??
                                                  '')
                                            : (preview.dailyRate
                                                      ?.toStringAsFixed(2) ??
                                                  ''),
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                          suffixText:
                                              preview.employeeType ==
                                                  EmployeeType.hourly
                                              ? '₹/hr'
                                              : '₹/day',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          final rate = double.tryParse(value);
                                          setState(() {
                                            if (preview.employeeType ==
                                                EmployeeType.hourly) {
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
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? theme.cardColor.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                preview.employeeType == EmployeeType.hourly
                                    ? 'Hourly: Salary = Working Hours × Hourly Rate'
                                    : 'Daily: Salary = Full Day Rate or Half Day Rate (Rate ÷ 2)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateCard(CsvEmployeePreview preview, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.orange.withValues(alpha: 0.1),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.warning, color: Colors.orange, size: 20),
        title: Text(
          preview.name,
          style: TextStyle(
            fontSize: 14,
            decoration: TextDecoration.lineThrough,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        subtitle: Text(
          '${preview.employeeCode} • ${preview.position}',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: Text(
          '₹${preview.salary.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}
