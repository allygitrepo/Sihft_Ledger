import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_model.dart';
import '../providers/settings_provider.dart';
import '../utills/app_spacing.dart';
import '../widgets/toast.dart';

class OvertimeSlotsScreen extends ConsumerStatefulWidget {
  const OvertimeSlotsScreen({super.key});

  @override
  ConsumerState<OvertimeSlotsScreen> createState() => _OvertimeSlotsScreenState();
}

class _OvertimeSlotsScreenState extends ConsumerState<OvertimeSlotsScreen> {
  late List<OvertimeSlot> slots;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    slots = List.from(settings.overtimeSlots);
  }

  void _addSlot() {
    setState(() {
      final lastSlot = slots.isNotEmpty ? slots.last : null;
      final startHour = lastSlot != null ? lastSlot.endHour : 0;
      final endHour = startHour + 2;
      
      slots.add(OvertimeSlot(
        startHour: startHour,
        endHour: endHour,
        rate: 100.0,
      ));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overtime Slots'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSlots,
          ),
        ],
      ),
      body: Column(
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
          Expanded(
            child: slots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No slots configured',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a slot',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSlot,
        child: const Icon(Icons.add),
      ),
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
    startController = TextEditingController(text: widget.slot.startHour.toString());
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

    widget.onUpdate(OvertimeSlot(
      startHour: start,
      endHour: end,
      rate: rate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slot ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    decoration: const InputDecoration(
                      labelText: 'Start Hour',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateSlot(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endController,
                    decoration: const InputDecoration(
                      labelText: 'End Hour',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateSlot(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(
                labelText: 'Rate per Hour',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateSlot(),
            ),
            const SizedBox(height: 8),
            Text(
              'Hours ${widget.slot.startHour}-${widget.slot.endHour}: ₹${widget.slot.rate}/hour',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
