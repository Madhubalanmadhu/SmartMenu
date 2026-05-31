import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/dish.dart';
import '../providers/analytics_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantId = context.read<RestaurantProvider>().restaurantId;
      if (restaurantId != null) {
        context.read<MenuProvider>().loadDishes(restaurantId);
        context.read<AnalyticsProvider>().loadAnalytics(restaurantId);
      }
    });
  }

  String _getDishName(int dishId) {
    final dishes = context.read<MenuProvider>().dishes;
    Dish? match;
    for (final dish in dishes) {
      if (dish.id == dishId) {
        match = dish;
        break;
      }
    }
    return match?.name ?? 'Dish #$dishId';
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = context.watch<RestaurantProvider>().restaurantId;

    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, _) {
        if (analyticsProvider.isLoading) {
          return const SmartPage(
            title: 'Insights',
            subtitle: 'Real-time performance and menu engineering metrics.',
            children: [LoadingWidget(message: 'Loading analytics...')],
          );
        }

        if (analyticsProvider.error != null) {
          return SmartPage(
            title: 'Insights',
            subtitle: 'Real-time performance and menu engineering metrics.',
            children: [
              AppErrorWidget(
                message: analyticsProvider.error!,
                onRetry: restaurantId == null
                    ? null
                    : () => context.read<AnalyticsProvider>().loadAnalytics(
                        restaurantId,
                      ),
              ),
            ],
          );
        }

        return SmartPage(
          title: 'Insights',
          subtitle: 'Real-time performance and menu engineering metrics.',
          floatingActionButton: restaurantId == null
              ? null
              : FloatingActionButton(
                  tooltip: 'AI food advisor',
                  onPressed: () => _openAiChat(restaurantId, analyticsProvider),
                  child: const Icon(Icons.auto_awesome),
                ),
          children: [
            if (analyticsProvider.smartDashboardData != null)
              _buildSmartDashboard(
                context,
                analyticsProvider.smartDashboardData!,
              ),
            const SizedBox(height: 12),
            if (analyticsProvider.profitData != null)
              _buildProfitDashboard(context, analyticsProvider.profitData!),
            const SizedBox(height: 12),
            if (analyticsProvider.demandData != null)
              _buildDemandDashboard(context, analyticsProvider.demandData!),
            const SizedBox(height: 12),
            if (analyticsProvider.classificationData != null)
              _buildClassificationDashboard(
                context,
                analyticsProvider.classificationData!,
              ),
          ],
        );
      },
    );
  }

  Future<void> _openAiChat(
    int restaurantId,
    AnalyticsProvider analyticsProvider,
  ) async {
    final dishes = context.read<MenuProvider>().dishes;
    Dish? selectedDish = dishes.isEmpty ? null : dishes.first;
    final inputController = TextEditingController();
    final messages = <_ChatMessage>[
      const _ChatMessage(
        fromUser: false,
        text:
            'Ask me what to prepare, how weather affects demand, festival impact, waste risk, or which dish to push today.',
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: AppTheme.outline),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> sendMessage() async {
              final text = inputController.text.trim();
              if (text.isEmpty) return;
              setSheetState(() {
                messages.add(_ChatMessage(fromUser: true, text: text));
                inputController.clear();
              });
              try {
                final response = await analyticsProvider.chat(
                  restaurantId,
                  text,
                  dishId: selectedDish?.id,
                );
                final provider = response['provider']?.toString() ?? 'AI';
                final reply = response['reply']?.toString() ?? '';
                setSheetState(() {
                  messages.add(
                    _ChatMessage(
                      fromUser: false,
                      text: '$reply\n\nSource: $provider',
                    ),
                  );
                });
              } catch (e) {
                setSheetState(() {
                  messages.add(
                    _ChatMessage(
                      fromUser: false,
                      text: 'I could not generate a reply: $e',
                    ),
                  );
                });
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI Food Advisor',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (dishes.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: selectedDish?.id,
                          dropdownColor: AppTheme.surfaceHigh,
                          decoration: const InputDecoration(
                            labelText: 'Food item context',
                          ),
                          items: dishes.map((dish) {
                            return DropdownMenuItem(
                              value: dish.id,
                              child: Text(dish.name),
                            );
                          }).toList(),
                          onChanged: (dishId) {
                            final match = dishes.firstWhere(
                              (dish) => dish.id == dishId,
                              orElse: () => selectedDish ?? dishes.first,
                            );
                            setSheetState(() => selectedDish = match);
                          },
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.48,
                        child: SingleChildScrollView(
                          child: Column(
                            children: messages.map((message) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ChatBubble(message: message),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: inputController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Ask the AI advisor',
                              ),
                              onSubmitted: (_) => sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            tooltip: 'Send',
                            onPressed: sendMessage,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    inputController.dispose();
  }

  Widget _buildProfitDashboard(
    BuildContext context,
    Map<String, dynamic> profitData,
  ) {
    final analysis = (profitData['analysis'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final totalProfit = analysis.fold<double>(0, (sum, row) {
      return sum +
          ((row['total_profit'] as num?)?.toDouble() ??
              (row['profit'] as num?)?.toDouble() ??
              0);
    });
    final totalSold = analysis.fold<int>(0, (sum, row) {
      return sum + ((row['total_sold'] as num?)?.toInt() ?? 0);
    });
    final marginRows = analysis
        .map((row) => (row['margin'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final averageMargin = marginRows.isEmpty
        ? 0.0
        : marginRows.fold<double>(0, (sum, margin) => sum + margin) /
              marginRows.length *
              100;
    final maxProfit = analysis.fold<double>(0, (max, row) {
      final value =
          (row['total_profit'] as num?)?.toDouble() ??
          (row['profit'] as num?)?.toDouble() ??
          0;
      return value > max ? value : max;
    });

    return _AnalyticsPanel(
      title: 'Profit Analysis',
      icon: Icons.attach_money,
      child: analysis.isEmpty
          ? const Text('No data available')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardMetricsGrid(
                  metrics: [
                    _VisualMetricData(
                      label: 'Profit',
                      value: formatMoney(totalProfit),
                      icon: Icons.payments_outlined,
                      color: AppTheme.successColor,
                      progress: totalProfit <= 0 ? 0 : 1,
                    ),
                    _VisualMetricData(
                      label: 'Sold',
                      value: totalSold.toString(),
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF4E9DFF),
                      progress: totalSold <= 0 ? 0 : 1,
                    ),
                    _VisualMetricData(
                      label: 'Margin',
                      value: marginRows.isEmpty
                          ? 'Cost missing'
                          : '${averageMargin.toStringAsFixed(1)}%',
                      icon: Icons.speed_outlined,
                      color: AppTheme.warningColor,
                      progress: (averageMargin / 100).clamp(0, 1).toDouble(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _VisualBarList(
                  title: 'Profit contribution',
                  items: analysis.take(6).map((row) {
                    final dishId = row['dish_id'] as int?;
                    final total =
                        (row['total_profit'] as num?)?.toDouble() ??
                        (row['profit'] as num?)?.toDouble() ??
                        0;
                    final margin = (row['margin'] as num?)?.toDouble();
                    final marginText = margin == null
                        ? 'Cost missing'
                        : '${(margin * 100).toStringAsFixed(0)}% margin';
                    final name = row['name']?.toString();
                    return _VisualBarData(
                      label: name?.isNotEmpty == true
                          ? name!
                          : dishId != null
                          ? _getDishName(dishId)
                          : 'Unknown',
                      value: maxProfit == 0 ? 0 : total / maxProfit,
                      detail: '${formatMoney(total)} profit / $marginText',
                      color: total >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSmartDashboard(BuildContext context, Map<String, dynamic> data) {
    final forecasts = data['dish_forecasts'] as List? ?? [];
    final inventory = data['inventory_estimate'] as List? ?? [];
    final recommendations = data['recommendations'] as List? ?? [];
    final predictedSales = (data['expected_sales'] as num?)?.toDouble() ?? 0;
    final customers = (data['expected_customers'] as num?)?.toInt() ?? 0;
    final top = forecasts.isNotEmpty && forecasts.first is Map
        ? forecasts.first as Map
        : const {};

    return _AnalyticsPanel(
      title: 'Food Demand Planner',
      icon: Icons.auto_graph,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InsightPill(
                label: 'Next sales',
                value: formatMoney(predictedSales),
                icon: Icons.payments_outlined,
              ),
              _InsightPill(
                label: 'Customers',
                value: customers.toString(),
                icon: Icons.groups_outlined,
              ),
              _InsightPill(
                label: 'Top item',
                value: top['name']?.toString() ?? 'No sales yet',
                icon: Icons.local_dining_outlined,
              ),
            ],
          ),
          if (forecasts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Likely to sell most next',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...forecasts.take(6).map((item) {
              final row = item is Map ? item : const {};
              final name = row['name']?.toString() ?? 'Unknown';
              final demand = (row['expected_quantity'] as num?)?.toInt() ?? 0;
              final prep = (row['preparation_quantity'] as num?)?.toInt() ?? 0;
              final sales = (row['expected_sales'] as num?)?.toDouble() ?? 0;
              final margin = (row['margin'] as num?)?.toDouble();
              final marginText = margin == null
                  ? 'Cost missing'
                  : '${margin.toStringAsFixed(0)}%';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(name)),
                    const SizedBox(width: 10),
                    StatusChip(label: 'Prep $prep'),
                    const SizedBox(width: 8),
                    Text(
                      '$demand demand',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatMoney(sales)} / $marginText',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Prep Recommendations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...recommendations.take(4).map((item) {
              final row = item is Map ? item : const {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  row['message']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }),
          ],
          if (inventory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Inventory Estimate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...inventory.take(6).map((item) {
              final row = item is Map ? item : const {};
              return Text(
                '${row['ingredient']}: ${row['quantity']} ${row['unit']}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDemandDashboard(
    BuildContext context,
    Map<String, dynamic> demandData,
  ) {
    final predictions = demandData['predictions'];
    final predictionRows = predictions is Map
        ? predictions.entries.toList()
        : const <MapEntry<dynamic, dynamic>>[];

    return _AnalyticsPanel(
      title: 'Demand Prediction',
      icon: Icons.trending_up,
      child: predictionRows.isEmpty
          ? const Text('No predictions available')
          : LayoutBuilder(
              builder: (context, constraints) {
                final rows = predictionRows.take(6).toList();
                final maxDemand = rows.fold<double>(0, (max, entry) {
                  final item = entry.value is Map
                      ? entry.value as Map
                      : const {};
                  final nextDay = (item['next_day'] as num?)?.toDouble() ?? 0;
                  final nextWeek = (item['next_week'] as num?)?.toDouble() ?? 0;
                  final value = nextDay > nextWeek ? nextDay : nextWeek;
                  return value > max ? value : max;
                });
                final tiles = rows.map((entry) {
                  final dishId = int.tryParse(entry.key.toString()) ?? 0;
                  final item = entry.value is Map
                      ? entry.value as Map
                      : const {};
                  final name = item['name']?.toString();
                  return _DemandForecastTile(
                    name: name?.isNotEmpty == true
                        ? name!
                        : _getDishName(dishId),
                    nextDay: (item['next_day'] as num?)?.toDouble() ?? 0,
                    nextWeek: (item['next_week'] as num?)?.toDouble() ?? 0,
                    maxDemand: maxDemand,
                    signal: _predictionSignal(item['confidence']?.toString()),
                  );
                }).toList();

                if (constraints.maxWidth < 760) {
                  return Column(
                    children: [
                      for (final tile in tiles) ...[
                        tile,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
                return Wrap(spacing: 12, runSpacing: 12, children: tiles);
              },
            ),
    );
  }

  Widget _buildClassificationDashboard(
    BuildContext context,
    Map<String, dynamic> classData,
  ) {
    final classifications = classData['classifications'];
    final classificationRows = classifications is Map
        ? classifications.entries.toList()
        : const <MapEntry<dynamic, dynamic>>[];

    return _AnalyticsPanel(
      title: 'Dish Classification',
      icon: Icons.star_outline,
      child: classificationRows.isEmpty
          ? const Text('No classification available')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClassificationSummary(rows: classificationRows),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: classificationRows.map((entry) {
                    final item = entry.value is Map
                        ? entry.value as Map
                        : const {};
                    return _ClassificationTile(
                      name: item['name']?.toString() ?? 'Unknown',
                      demand: item['demand_level']?.toString() ?? 'Unknown',
                      margin: (item['margin'] as num?)?.toDouble(),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  String _predictionSignal(String? confidence) {
    switch (confidence) {
      case 'high':
        return 'Model high';
      case 'medium':
        return 'Model';
      case 'limited_history':
        return 'Limited';
      case 'category_baseline':
        return 'Category';
      case 'restaurant_baseline':
        return 'Restaurant';
      case 'no_history':
        return 'No data';
      default:
        return confidence ?? 'Unknown';
    }
  }
}

class _AnalyticsPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AnalyticsPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _VisualMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;

  const _VisualMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.progress,
  });
}

class _DashboardMetricsGrid extends StatelessWidget {
  final List<_VisualMetricData> metrics;

  const _DashboardMetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (final metric in metrics) ...[
                _VisualMetricTile(metric: metric),
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              Expanded(child: _VisualMetricTile(metric: metrics[i])),
              if (i != metrics.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _VisualMetricTile extends StatelessWidget {
  final _VisualMetricData metric;

  const _VisualMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(metric.value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _ProgressBar(value: metric.progress, color: metric.color),
        ],
      ),
    );
  }
}

class _VisualBarData {
  final String label;
  final double value;
  final String detail;
  final Color color;

  const _VisualBarData({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });
}

class _VisualBarList extends StatelessWidget {
  final String title;
  final List<_VisualBarData> items;

  const _VisualBarList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          for (final item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ProgressBar(value: item.value, color: item.color),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DemandForecastTile extends StatelessWidget {
  final String name;
  final double nextDay;
  final double nextWeek;
  final double maxDemand;
  final String signal;

  const _DemandForecastTile({
    required this.name,
    required this.nextDay,
    required this.nextWeek,
    required this.maxDemand,
    required this.signal,
  });

  @override
  Widget build(BuildContext context) {
    final dayProgress = maxDemand == 0 ? 0.0 : nextDay / maxDemand;
    final weekProgress = maxDemand == 0 ? 0.0 : nextWeek / maxDemand;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: signal),
            ],
          ),
          const SizedBox(height: 14),
          _LabeledProgress(
            label: 'Next day',
            valueLabel: nextDay.toStringAsFixed(0),
            value: dayProgress,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _LabeledProgress(
            label: 'Week avg',
            valueLabel: nextWeek.toStringAsFixed(0),
            value: weekProgress,
            color: const Color(0xFF4E9DFF),
          ),
        ],
      ),
    );
  }
}

class _ClassificationSummary extends StatelessWidget {
  final List<MapEntry<dynamic, dynamic>> rows;

  const _ClassificationSummary({required this.rows});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final entry in rows) {
      final item = entry.value is Map ? entry.value as Map : const {};
      final demand = item['demand_level']?.toString() ?? 'Unknown';
      counts[demand] = (counts[demand] ?? 0) + 1;
    }
    final total = rows.isEmpty ? 1 : rows.length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: counts.entries.map((entry) {
        return SizedBox(
          width: 210,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(label: entry.key, color: _demandColor(entry.key)),
                const SizedBox(height: 14),
                _ProgressBar(
                  value: entry.value / total,
                  color: _demandColor(entry.key),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.value} menu items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ClassificationTile extends StatelessWidget {
  final String name;
  final String demand;
  final double? margin;

  const _ClassificationTile({
    required this.name,
    required this.demand,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final color = _demandColor(demand);

    return SizedBox(
      width: 230,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.34)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.star_outline, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            StatusChip(label: demand, color: color),
            const SizedBox(height: 14),
            _LabeledProgress(
              label: 'Margin',
              valueLabel: margin == null
                  ? 'Cost missing'
                  : '${(margin! * 100).toStringAsFixed(0)}%',
              value: margin == null ? 0 : margin!.clamp(0, 1).toDouble(),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledProgress extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  const _LabeledProgress({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(valueLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 7),
        _ProgressBar(value: value, color: color),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 1).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: clampedValue,
        backgroundColor: AppTheme.surfaceHigh,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

Color _demandColor(String demand) {
  final normalized = demand.toLowerCase();
  if (normalized.contains('high') || normalized.contains('star')) {
    return AppTheme.successColor;
  }
  if (normalized.contains('medium') || normalized.contains('steady')) {
    return AppTheme.primary;
  }
  if (normalized.contains('low') || normalized.contains('slow')) {
    return AppTheme.warningColor;
  }
  return const Color(0xFF4E9DFF);
}

class _ChatMessage {
  final bool fromUser;
  final String text;

  const _ChatMessage({required this.fromUser, required this.text});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment = message.fromUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final color = message.fromUser ? AppTheme.surfaceHigh : AppTheme.surfaceLow;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                message.fromUser ? Icons.person_outline : Icons.auto_awesome,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(message.text)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
