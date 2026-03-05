import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/department_model.dart';
import '../providers/department_provider.dart';
import '../utills/app_colors.dart';
import '../widgets/toast.dart';
import '../widgets/loader.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departmentState = ref.watch(departmentProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    final filteredDepartments = departmentState.departments.where((dept) {
      if (_searchQuery.isEmpty) return true;
      return dept.departmentName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('Departments'), centerTitle: true),
      body: Container(
        color: theme.brightness == Brightness.light ? Colors.grey[50] : null,
        child: Column(
          children: [
            _buildHeader(context, theme),
            Expanded(
              child: departmentState.isLoading
                  ? const Center(child: AppLoader())
                  : _buildContent(
                      context,
                      filteredDepartments,
                      theme,
                      isDesktop,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search departments...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showDepartmentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Department'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<DepartmentModel> departments,
    ThemeData theme,
    bool isDesktop,
  ) {
    if (departments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No departments found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add Department" to create one',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (!isDesktop) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                dept.departmentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Created: ${DateFormat('dd MMM yyyy').format(dept.createdAt)}',
              ),
              trailing: _buildStatusBadge(dept.status),
              onTap: () => _showDepartmentDialog(context, department: dept),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              theme.brightness == Brightness.dark
                  ? Colors.grey.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.05),
            ),
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
            columnSpacing: 48,
            horizontalMargin: 24,
            dividerThickness: 1,
            columns: const [
              DataColumn(
                label: Text(
                  'ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Department Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Created Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: departments.map((dept) {
              return DataRow(
                cells: [
                  DataCell(Text(dept.id.substring(0, 8))), // Show short ID
                  DataCell(
                    Text(
                      dept.departmentName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(_buildStatusBadge(dept.status)),
                  DataCell(
                    Text(DateFormat('dd MMM yyyy').format(dept.createdAt)),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                          ),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showDepartmentDialog(context, department: dept),
                        ),
                        IconButton(
                          icon: Icon(
                            dept.status ? Icons.toggle_on : Icons.toggle_off,
                            color: dept.status ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                          tooltip: 'Toggle Status',
                          onPressed: () async {
                            await ref
                                .read(departmentProvider.notifier)
                                .toggleStatus(dept.id);
                            ToastHelper.show('Status updated');
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, ref, dept),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showDepartmentDialog(
    BuildContext context, {
    DepartmentModel? department,
  }) async {
    final isEditing = department != null;
    final nameController = TextEditingController(
      text: department?.departmentName ?? '',
    );
    bool status = department?.status ?? true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Department' : 'Add Department'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Department Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: status,
                          onChanged: (value) {
                            setState(() {
                              status = value;
                            });
                          },
                          activeTrackColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ToastHelper.error('Department name cannot be empty');
                      return;
                    }

                    final notifier = ref.read(departmentProvider.notifier);
                    bool success;

                    if (isEditing) {
                      final updated = department.copyWith(
                        departmentName: nameController.text.trim(),
                        status: status,
                        updatedAt: DateTime.now(),
                      );
                      success = await notifier.updateDepartment(updated);
                    } else {
                      final newDept = DepartmentModel(
                        id: DateTime.now().millisecondsSinceEpoch
                            .toString(), // Simple ID gen
                        companyId: 'COMP001', // Mock company ID for now
                        departmentName: nameController.text.trim(),
                        status: status,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      success = await notifier.addDepartment(newDept);
                    }

                    if (context.mounted) {
                      if (success) {
                        ToastHelper.success(
                          isEditing ? 'Department updated' : 'Department added',
                        );
                        Navigator.pop(context);
                      } else {
                        ToastHelper.error('An error occurred');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Department'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DepartmentModel dept,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
          'Are you sure you want to delete ${dept.departmentName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(departmentProvider.notifier)
          .deleteDepartment(dept.id);
      if (success) {
        ToastHelper.success('Department deleted');
      } else {
        ToastHelper.error('Failed to delete department');
      }
    }
  }
}
