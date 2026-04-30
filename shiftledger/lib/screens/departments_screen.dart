import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final TextEditingController _addController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(departmentProvider.notifier).loadDepartments(search: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final departmentState = ref.watch(departmentProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

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
              child: departmentState.isLoading && departmentState.departments.isEmpty
                  ? const Center(child: AppLoader())
                  : _buildContent(
                      context,
                      departmentState.departments,
                      theme,
                      isDesktop,
                    ),
            ),
            if (departmentState.totalPages > 1)
              _buildPaginationControls(departmentState),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDepartmentDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No departments found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: departments.map((d) => _buildDepartmentCard(d, theme, true)).toList(),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: departments.length,
      itemBuilder: (context, index) => _buildDepartmentCard(departments[index], theme, false),
    );
  }

  Widget _buildDepartmentCard(DepartmentModel dept, ThemeData theme, bool isGrid) {
    final card = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.business, color: AppColors.primary),
        ),
        title: Text(dept.departmentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(dept),
        ),
      ),
    );

    if (isGrid) {
      return SizedBox(width: 300, child: card);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: card);
  }

  Widget _buildPaginationControls(DepartmentState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.currentPage > 1
                ? () => ref.read(departmentProvider.notifier).loadDepartments(page: state.currentPage - 1, search: _searchController.text)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${state.currentPage} of ${state.totalPages}'),
          IconButton(
            onPressed: state.currentPage < state.totalPages
                ? () => ref.read(departmentProvider.notifier).loadDepartments(page: state.currentPage + 1, search: _searchController.text)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showAddDepartmentDialog(BuildContext context) {
    _addController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Department'),
        content: TextField(
          controller: _addController,
          decoration: const InputDecoration(labelText: 'Department Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_addController.text.isNotEmpty) {
                ref.read(departmentProvider.notifier).addDepartment(_addController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DepartmentModel dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete ${dept.departmentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(departmentProvider.notifier).deleteDepartment(dept.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
