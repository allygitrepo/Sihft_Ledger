import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/designation_model.dart';
import '../models/department_model.dart';
import '../providers/designation_provider.dart';
import '../providers/department_provider.dart';
import '../utills/app_colors.dart';
import '../widgets/toast.dart';
import '../widgets/loader.dart';

class DesignationsScreen extends ConsumerStatefulWidget {
  const DesignationsScreen({super.key});

  @override
  ConsumerState<DesignationsScreen> createState() => _DesignationsScreenState();
}

class _DesignationsScreenState extends ConsumerState<DesignationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final designationState = ref.watch(designationProvider);
    final departmentState = ref.watch(departmentProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    final filteredDesignations = designationState.designations.where((desig) {
      if (_searchQuery.isEmpty) return true;
      return desig.designationName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('Designations'), centerTitle: true),
      body: Container(
        color: theme.brightness == Brightness.light ? Colors.grey[50] : null,
        child: Column(
          children: [
            _buildHeader(context, theme, departmentState.departments),
            Expanded(
              child: designationState.isLoading || departmentState.isLoading
                  ? const Center(child: AppLoader())
                  : _buildContent(
                      context,
                      filteredDesignations,
                      departmentState.departments,
                      theme,
                      isDesktop,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    List<DepartmentModel> departments,
  ) {
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
                hintText: 'Search designations...',
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
            onPressed: () {
              if (departments.isEmpty) {
                ToastHelper.error('Please create a department first');
                return;
              }
              _showDesignationDialog(context, departments);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Designation'),
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
    List<DesignationModel> designations,
    List<DepartmentModel> departments,
    ThemeData theme,
    bool isDesktop,
  ) {
    if (designations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No designations found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add Designation" to create one',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (!isDesktop) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: designations.length,
        itemBuilder: (context, index) {
          final desig = designations[index];
          final dept = departments.firstWhere(
            (d) => d.id == desig.departmentId,
            orElse: () => DepartmentModel(
              id: '',
              companyId: '',
              departmentName: 'Unknown',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                desig.designationName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${dept.departmentName}\nCreated: ${DateFormat('dd MMM yyyy').format(desig.createdAt)}',
              ),
              trailing: _buildStatusBadge(desig.status),
              onTap: () => _showDesignationDialog(
                context,
                departments,
                designation: desig,
              ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                        'S.No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Department',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Designation Name',
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
                  rows: designations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final desig = entry.value;
                    final dept = departments.firstWhere(
                      (d) => d.id == desig.departmentId,
                      orElse: () => DepartmentModel(
                        id: '',
                        companyId: '',
                        departmentName: 'Unknown',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(dept.departmentName)),
                        DataCell(
                          Text(
                            desig.designationName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(_buildStatusBadge(desig.status)),
                        DataCell(
                          Text(
                            DateFormat('dd MMM yyyy').format(desig.createdAt),
                          ),
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
                                onPressed: () => _showDesignationDialog(
                                  context,
                                  departments,
                                  designation: desig,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  desig.status
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  color: desig.status
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 28,
                                ),
                                tooltip: 'Toggle Status',
                                onPressed: () async {
                                  await ref
                                      .read(designationProvider.notifier)
                                      .toggleStatus(desig.id);
                                  ToastHelper.show('Status updated');
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDelete(context, ref, desig),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
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

  Future<void> _showDesignationDialog(
    BuildContext context,
    List<DepartmentModel> departments, {
    DesignationModel? designation,
  }) async {
    final isEditing = designation != null;
    final nameController = TextEditingController(
      text: designation?.designationName ?? '',
    );
    String? selectedDepartmentId =
        designation?.departmentId ??
        (departments.isNotEmpty ? departments.first.id : null);
    bool status = designation?.status ?? true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Designation' : 'Add Designation'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept.id,
                          child: Text(dept.departmentName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDepartmentId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Designation Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
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
                      ToastHelper.error('Designation name cannot be empty');
                      return;
                    }
                    if (selectedDepartmentId == null) {
                      ToastHelper.error('Please select a department');
                      return;
                    }

                    final notifier = ref.read(designationProvider.notifier);
                    bool success;

                    if (isEditing) {
                      final updated = designation.copyWith(
                        departmentId: selectedDepartmentId,
                        designationName: nameController.text.trim(),
                        status: status,
                        updatedAt: DateTime.now(),
                      );
                      success = await notifier.updateDesignation(updated);
                    } else {
                      final newDesig = DesignationModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        companyId: 'COMP001',
                        departmentId: selectedDepartmentId!,
                        designationName: nameController.text.trim(),
                        status: status,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      success = await notifier.addDesignation(newDesig);
                    }

                    if (context.mounted) {
                      if (success) {
                        ToastHelper.success(
                          isEditing
                              ? 'Designation updated'
                              : 'Designation added',
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
                  child: Text(isEditing ? 'Save Changes' : 'Add Designation'),
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
    DesignationModel desig,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Designation'),
        content: Text(
          'Are you sure you want to delete ${desig.designationName}? This action cannot be undone.',
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
          .read(designationProvider.notifier)
          .deleteDesignation(desig.id);
      if (success) {
        ToastHelper.success('Designation deleted');
      } else {
        ToastHelper.error('Failed to delete designation');
      }
    }
  }
}
