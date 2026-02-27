import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employee_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/payroll_provider.dart';
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
  int todayAttendanceCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    await ref.read(attendanceListProvider.notifier).loadAttendance();
    if (mounted) {
      final today = DateTime.now();
      final todayRecords = ref.read(attendanceListProvider).attendanceRecords.where((r) {
        return r.date.year == today.year &&
            r.date.month == today.month &&
            r.date.day == today.day;
      }).toList();
      
      setState(() {
        todayAttendanceCount = todayRecords.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final payrollState = ref.watch(payrollProvider);
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(employeeProvider.notifier).loadEmployees();
        await ref.read(payrollProvider.notifier).loadSavedPayroll();
        await _loadTodayAttendance();
      },
      child: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Statistics Cards - Responsive Grid
          _buildStatsGrid(context, employeeState, payrollState, deviceType),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            title: 'Manage Employees',
            subtitle: 'Add, edit, or import employees',
            icon: Icons.group_add,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.employees);
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Mark Attendance',
            subtitle: 'Record daily attendance',
            icon: Icons.how_to_reg,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.attendance);
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Generate Payroll',
            subtitle: 'Calculate salaries for the period',
            icon: Icons.calculate,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.payroll);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    employeeState,
    payrollState,
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
        title: 'Generated Payroll',
        value: payrollState.payrollRecords.length.toString(),
        icon: Icons.receipt_long,
        color: AppColors.secondary,
      ),
      _StatData(
        title: 'Total Payout',
        value: '₹${_formatAmount(payrollState.totalSalary)}',
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
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
        ],
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: deviceType == DeviceScreenType.tablet ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
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
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
