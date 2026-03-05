import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_model.dart';
import '../providers/settings_provider.dart';
import '../utills/app_spacing.dart';
import '../utills/app_colors.dart';
import '../widgets/toast.dart';

class OvertimeSlotsScreen extends ConsumerStatefulWidget {
  const OvertimeSlotsScreen({super.key});

  @override
  ConsumerState<OvertimeSlotsScreen> createState() =>
      _OvertimeSlotsScreenState();
}

class _OvertimeSlotsScreenState extends ConsumerState<OvertimeSlotsScreen> {
  late List<OvertimeSlot> slots;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);

    // Always start with saved slots, or create one default slot if empty
    if (settings.overtimeSlots.isEmpty) {
      slots = [OvertimeSlot(startHour: 0, endHour: 2, rate: 100.0)];
    } else {
      slots = List.from(settings.overtimeSlots);
    }
  }

  void _addSlot() {
    setState(() {
      final lastSlot = slots.isNotEmpty ? slots.last : null;
      final startHour = lastSlot != null ? lastSlot.endHour : 0;
      final endHour = startHour + 2;

      slots.add(
        OvertimeSlot(startHour: startHour, endHour: endHour, rate: 100.0),
      );
    });
  }

  void _removeSlot(int index) {
    setState(() {
      slots.removeAt(index);
    });
  }

  void _updateSlot(int index, OvertimeSlot slot) {
    setState(() {
      slots[index] = slot;
    });
  }

  Future<void> _saveSlots() async {
    // Validate slots
    if (slots.isEmpty) {
      ToastHelper.error('Please add at least one slot');
      return;
    }

    // Check for overlapping slots
    for (int i = 0; i < slots.length - 1; i++) {
      if (slots[i].endHour > slots[i + 1].startHour) {
        ToastHelper.error('Slots cannot overlap');
        return;
      }
    }

    final settings = ref.read(settingsProvider);
    final updatedSettings = settings.copyWith(overtimeSlots: slots);

    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

    if (mounted) {
      ToastHelper.success('Overtime slots saved successfully');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('Overtime Slots'), centerTitle: true),
      body: isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: _addSlot,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configure Overtime Slots',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define hour ranges and rates for overtime calculation',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildSlotsList(context)),
        Padding(
          padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
          child: ElevatedButton(
            onPressed: _saveSlots,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Save Slots'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 48.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manage Slots',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Slots list
                ...slots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final slot = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _SlotCard(
                      slot: slot,
                      index: index,
                      onUpdate: (slot) => _updateSlot(index, slot),
                      onRemove: () => _removeSlot(index),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _addSlot,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Slot',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveSlots,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsList(BuildContext context) {
    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No slots configured',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a slot',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.getHorizontalPadding(context)),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        return _SlotCard(
          slot: slots[index],
          index: index,
          onUpdate: (slot) => _updateSlot(index, slot),
          onRemove: () => _removeSlot(index),
        );
      },
    );
  }
}

class _SlotCard extends StatefulWidget {
  final OvertimeSlot slot;
  final int index;
  final Function(OvertimeSlot) onUpdate;
  final VoidCallback onRemove;

  const _SlotCard({
    required this.slot,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  late TextEditingController startController;
  late TextEditingController endController;
  late TextEditingController rateController;

  @override
  void initState() {
    super.initState();
    startController = TextEditingController(
      text: widget.slot.startHour.toString(),
    );
    endController = TextEditingController(text: widget.slot.endHour.toString());
    rateController = TextEditingController(text: widget.slot.rate.toString());
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    rateController.dispose();
    super.dispose();
  }

  void _updateSlot() {
    final start = int.tryParse(startController.text) ?? 0;
    final end = int.tryParse(endController.text) ?? 0;
    final rate = double.tryParse(rateController.text) ?? 0.0;

    if (start >= end) {
      ToastHelper.error('End hour must be greater than start hour');
      return;
    }

    widget.onUpdate(OvertimeSlot(startHour: start, endHour: end, rate: rate));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slot ${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: widget.onRemove,
                borderRadius: BorderRadius.circular(20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startController,
                  decoration: InputDecoration(
                    labelText: 'Start Hour',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateSlot(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: endController,
                  decoration: InputDecoration(
                    labelText: 'End Hour',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateSlot(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: rateController,
            decoration: InputDecoration(
              labelText: 'Rate per Hour',
              prefixIcon: const Icon(
                Icons.currency_rupee,
                size: 20,
                color: Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateSlot(),
          ),
          const SizedBox(height: 12),
          Text(
            'Hours ${widget.slot.startHour}-${widget.slot.endHour}: ₹${widget.slot.rate}/hour',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
