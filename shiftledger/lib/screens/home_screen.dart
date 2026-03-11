import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employee_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/payroll_provider.dart';
import '../providers/department_provider.dart';
import '../providers/designation_provider.dart';
import '../routes/app_routes.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';
import '../utills/responsive_breakpoints.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final payrollState = ref.watch(payrollProvider);
    final attendanceList = ref.watch(attendanceListProvider);
    final departmentState = ref.watch(departmentProvider);
    final designationState = ref.watch(designationProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);

    // Calculate today's attendance count
    final today = DateTime.now();
    final todayAttendanceCount = attendanceList.attendanceRecords.where((r) {
      return r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day;
    }).length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(employeeProvider.notifier).loadEmployees();
        await ref.read(payrollProvider.notifier).loadSavedPayroll();
        await ref.read(attendanceListProvider.notifier).loadAttendance();
        await ref.read(departmentProvider.notifier).loadDepartments();
        await ref.read(designationProvider.notifier).loadAllDesignations();
      },
      child: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          Text(
            'Overview',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Statistics Cards - Responsive Grid
          _buildStatsGrid(
            context,
            employeeState,
            payrollState,
            departmentState,
            designationState,
            todayAttendanceCount,
            deviceType,
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(context, deviceType),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DeviceScreenType deviceType) {
    final actions = [
      _ActionData(
        title: 'Manage Employees',
        subtitle: 'Add, edit, or import employees',
        icon: Icons.group_add,
        onTap: () => Navigator.pushNamed(context, AppRoutes.employees),
      ),
      _ActionData(
        title: 'Manage Departments',
        subtitle: 'Configure company departments',
        icon: Icons.business,
        onTap: () => Navigator.pushNamed(context, AppRoutes.departments),
      ),
      _ActionData(
        title: 'Manage Designations',
        subtitle: 'Set up employee roles',
        icon: Icons.badge,
        onTap: () => Navigator.pushNamed(context, AppRoutes.designations),
      ),
      _ActionData(
        title: 'Mark Attendance',
        subtitle: 'Record daily attendance',
        icon: Icons.how_to_reg,
        onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
      ),
      _ActionData(
        title: 'Generate Payroll',
        subtitle: 'Calculate salaries for the period',
        icon: Icons.calculate,
        onTap: () => Navigator.pushNamed(context, AppRoutes.payroll),
      ),
    ];

    if (deviceType == DeviceScreenType.mobile) {
      return Column(
        children: actions
            .map(
              (a) => _buildActionCard(
                context: context,
                title: a.title,
                subtitle: a.subtitle,
                icon: a.icon,
                onTap: a.onTap,
                isFullWidth: true,
              ),
            )
            .toList(),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: deviceType == DeviceScreenType.tablet ? 3 : 5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0, // Square shape
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final a = actions[index];
          return _buildActionCard(
            context: context,
            title: a.title,
            subtitle: a.subtitle,
            icon: a.icon,
            onTap: a.onTap,
            isFullWidth: false,
            isSquare: true,
          );
        },
      );
    }
  }

  Widget _buildStatsGrid(
    BuildContext context,
    employeeState,
    payrollState,
    departmentState,
    designationState,
    int todayAttendanceCount,
    DeviceScreenType deviceType,
  ) {
    final stats = [
      _StatData(
        title: 'Total Employees',
        value: employeeState.employees.length.toString(),
        icon: Icons.people,
        color: AppColors.primary,
      ),
      _StatData(
        title: "Today's Attendance",
        value: todayAttendanceCount.toString(),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      _StatData(
        title: 'Departments',
        value: departmentState.departments.length.toString(),
        icon: Icons.business,
        color: Colors.orange,
      ),
      _StatData(
        title: 'Designations',
        value: designationState.designations.length.toString(),
        icon: Icons.badge,
        color: Colors.cyan,
      ),
      _StatData(
        title: 'Generated Payroll',
        value: payrollState.payrollRecords.length.toString(),
        icon: Icons.receipt_long,
        color: AppColors.secondary,
      ),
      _StatData(
        title: 'Total Payout',
        value: '₹${_formatAmount(payrollState.totalSalary)}',
        icon: Icons.account_balance_wallet,
        color: Colors.purple,
      ),
    ];

    if (deviceType == DeviceScreenType.mobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(context, stats[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, stats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, stats[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, stats[3])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, stats[4])),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, stats[5])),
            ],
          ),
        ],
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: deviceType == DeviceScreenType.tablet ? 3 : 6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: deviceType == DeviceScreenType.tablet ? 1.4 : 1.2,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _buildStatCard(context, stats[index]),
      );
    }
  }

  Widget _buildStatCard(BuildContext context, _StatData data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.getCardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(data.icon, color: data.color, size: 28),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isFullWidth = true,
    bool isSquare = false,
  }) {
    if (isSquare) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      margin: isFullWidth ? const EdgeInsets.only(bottom: 12) : EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }
}

class _ActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _ActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
