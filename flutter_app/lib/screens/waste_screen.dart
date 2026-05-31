import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/dish.dart';
import '../providers/analytics_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/waste_provider.dart';
import '../widgets/common_widgets.dart';

class WasteScreen extends StatefulWidget {
  const WasteScreen({super.key});

  @override
  State<WasteScreen> createState() => _WasteScreenState();
}

class _WasteScreenState extends State<WasteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantId = context.read<RestaurantProvider>().restaurantId;
      if (restaurantId != null) {
        context.read<WasteProvider>().loadWaste(restaurantId);
      }
    });
  }

  Future<void> _openWasteDialog(int restaurantId) async {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final dateController = TextEditingController();
    int? selectedDishId;

    final wasteProvider = context.read<WasteProvider>();
    final dishes = wasteProvider.dishes;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log Waste'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedDishId,
                        dropdownColor: AppTheme.surfaceHigh,
                        decoration: const InputDecoration(labelText: 'Dish'),
                        items: dishes.map((dish) {
                          return DropdownMenuItem(
                            value: dish.id,
                            child: Text(dish.name),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedDishId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity Wasted',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(labelText: 'Reason'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date (YYYY-MM-DD)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final quantity =
                        int.tryParse(quantityController.text.trim()) ?? 0;
                    final reason = reasonController.text.trim();
                    final wasteDate = dateController.text.trim();

                    if (selectedDishId == null ||
                        quantity <= 0 ||
                        reason.isEmpty ||
                        wasteDate.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields correctly'),
                        ),
                      );
                      return;
                    }

                    await context.read<WasteProvider>().logWaste(
                      restaurantId,
                      selectedDishId!,
                      quantity,
                      reason,
                      wasteDate,
                    );
                    if (context.mounted) {
                      await context.read<AnalyticsProvider>().loadAnalytics(
                        restaurantId,
                      );
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    reasonController.dispose();
    dateController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = context.watch<RestaurantProvider>().restaurantId;
    final wasteProvider = context.watch<WasteProvider>();
    final patterns =
        wasteProvider.wastePatterns?['patterns'] as Map<String, dynamic>?;
    final totalUnits = _totalWaste(patterns);
    final reasonCount = _reasonCount(patterns);

    return SmartPage(
      title: 'Waste Analysis',
      subtitle: 'Operational efficiency and margin protection data.',
      trailing: restaurantId == null
          ? null
          : IconButton.filled(
              onPressed: () => _openWasteDialog(restaurantId),
              icon: const Icon(Icons.add),
              tooltip: 'Log waste',
            ),
      floatingActionButton: restaurantId == null
          ? null
          : FloatingActionButton(
              onPressed: () => _openWasteDialog(restaurantId),
              tooltip: 'Log waste',
              child: const Icon(Icons.add),
            ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              MetricCard(
                label: 'Weekly waste volume',
                value: '$totalUnits',
                icon: Icons.delete_outline,
                color: AppTheme.warningColor,
              ),
              MetricCard(
                label: 'Affected dishes',
                value: (patterns?.length ?? 0).toString(),
                icon: Icons.restaurant_menu_outlined,
              ),
              MetricCard(
                label: 'Reason signals',
                value: reasonCount.toString(),
                icon: Icons.insights_outlined,
                color: AppTheme.successColor,
              ),
            ];
            if (constraints.maxWidth < 760) {
              return Column(
                children: cards
                    .expand((card) => [card, const SizedBox(height: 12)])
                    .toList(),
              );
            }
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionHeader(title: 'Waste Patterns'),
        const SizedBox(height: 12),
        if (wasteProvider.isLoading)
          const LoadingWidget(message: 'Loading waste patterns...')
        else if (wasteProvider.error != null)
          AppErrorWidget(
            message: wasteProvider.error!,
            onRetry: restaurantId == null
                ? null
                : () => context.read<WasteProvider>().loadWaste(restaurantId),
          )
        else if (patterns == null || patterns.isEmpty)
          const EmptyStateCard(
            icon: Icons.delete_outline,
            title: 'No waste patterns yet',
            message:
                'Log waste alongside sales to identify recurring operational losses.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: patterns.entries.map((entry) {
                  return SizedBox(
                    width: wide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: _WastePatternCard(
                      dishName: _dishName(wasteProvider.dishes, entry.key),
                      data: entry.value as Map<String, dynamic>? ?? {},
                    ),
                  );
                }).toList(),
              );
            },
          ),
        if (wasteProvider.message != null) ...[
          const SizedBox(height: 12),
          StatusChip(
            label: wasteProvider.message!,
            color: AppTheme.successColor,
          ),
        ],
      ],
    );
  }

  String _dishName(List<Dish> dishes, String dishId) {
    final parsedId = int.tryParse(dishId);
    if (parsedId == null) return 'Dish #$dishId';
    for (final dish in dishes) {
      if (dish.id == parsedId) return dish.name;
    }
    return 'Dish #$dishId';
  }

  int _totalWaste(Map<String, dynamic>? patterns) {
    if (patterns == null) return 0;
    return patterns.values.fold<int>(0, (sum, value) {
      final row = value is Map ? value : const {};
      return sum + ((row['total_wasted'] as num?)?.toInt() ?? 0);
    });
  }

  int _reasonCount(Map<String, dynamic>? patterns) {
    if (patterns == null) return 0;
    return patterns.values.fold<int>(0, (sum, value) {
      final row = value is Map ? value : const {};
      final reasons = row['reasons'];
      return sum + (reasons is Map ? reasons.length : 0);
    });
  }
}

class _WastePatternCard extends StatelessWidget {
  final String dishName;
  final Map<String, dynamic> data;

  const _WastePatternCard({required this.dishName, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data['total_wasted']?.toString() ?? '0';
    final reasons = data['reasons'] as Map<String, dynamic>? ?? {};

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dishName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(label: '$total units', color: AppTheme.warningColor),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (reasons.isEmpty)
            Text(
              'No reason breakdown available',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...reasons.entries.map((reasonEntry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        reasonEntry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      reasonEntry.value.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
