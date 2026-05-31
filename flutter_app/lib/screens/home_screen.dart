import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/analytics_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/waste_provider.dart';
import '../widgets/common_widgets.dart';
import 'analytics_screen.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import 'sales_screen.dart';
import 'waste_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _intelligenceRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final restaurantProvider = context.read<RestaurantProvider>();
      if (restaurantProvider.restaurantId == null) {
        await restaurantProvider.loadRestaurant();
      }
      final restaurantId = restaurantProvider.restaurantId;
      if (restaurantId != null && mounted) {
        context.read<MenuProvider>().loadDishes(restaurantId);
        context.read<SalesProvider>().loadSales(restaurantId);
        context.read<WasteProvider>().loadWaste(restaurantId);
        context.read<AnalyticsProvider>().loadAnalytics(restaurantId);
        _startIntelligenceRefresh(restaurantId);
      }
    });
  }

  @override
  void dispose() {
    _intelligenceRefreshTimer?.cancel();
    super.dispose();
  }

  void _startIntelligenceRefresh(int restaurantId) {
    _intelligenceRefreshTimer?.cancel();
    _intelligenceRefreshTimer = Timer.periodic(const Duration(minutes: 30), (
      _,
    ) {
      if (!mounted) return;
      context.read<AnalyticsProvider>().loadAnalytics(restaurantId);
    });
  }

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0 || index == 3) {
      final restaurantId = context.read<RestaurantProvider>().restaurantId;
      if (restaurantId != null) {
        context.read<AnalyticsProvider>().loadAnalytics(restaurantId);
        _startIntelligenceRefresh(restaurantId);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _buildNotifications(context);
    final screens = [
      DashboardScreen(onNavigate: _goToTab),
      const MenuScreen(),
      const SalesScreen(),
      const AnalyticsScreen(),
      const WasteScreen(),
    ];

    return Scaffold(
      appBar: SmartTopBar(
        onProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        onNotifications: () => _openNotifications(context, notifications),
        notificationCount: notifications.length,
        onLogout: _logout,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: SmartBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }

  List<_SmartNotification> _buildNotifications(BuildContext context) {
    final salesHistory = context.watch<SalesProvider>().salesHistory;
    final wastePatterns = context.watch<WasteProvider>().wastePatterns;
    final dashboard = context.watch<AnalyticsProvider>().smartDashboardData;
    final forecasts = dashboard?['dish_forecasts'] as List? ?? [];
    final recommendations = dashboard?['recommendations'] as List? ?? [];
    final items = <_SmartNotification>[];

    if (salesHistory.isEmpty) {
      items.add(
        const _SmartNotification(
          title: 'Sales data needed',
          message: 'Enter today\'s sales so demand and prep alerts can update.',
          icon: Icons.point_of_sale,
          color: AppTheme.warningColor,
          tabIndex: 2,
        ),
      );
    } else {
      final latest = _latestSale(salesHistory);
      final revenue = (latest['total_revenue'] as num?)?.toDouble() ?? 0;
      items.add(
        _SmartNotification(
          title: 'Sales updated',
          message:
              'Latest logged sale is ${formatMoney(revenue)}. Dashboard is using current sales history.',
          icon: Icons.check_circle_outline,
          color: AppTheme.successColor,
        ),
      );
    }

    if (forecasts.isNotEmpty && forecasts.first is Map) {
      final top = forecasts.first as Map;
      items.add(
        _SmartNotification(
          title: 'Prep priority',
          message:
              'Prepare ${(top['preparation_quantity'] as num?)?.toInt() ?? 0} units of ${top['name'] ?? 'top item'} next.',
          icon: Icons.restaurant,
          color: AppTheme.primary,
          tabIndex: 0,
        ),
      );
    }

    for (final item in recommendations.take(2)) {
      final row = item is Map ? item : const {};
      final message = row['message']?.toString();
      if (message != null && message.isNotEmpty) {
        items.add(
          _SmartNotification(
            title: 'Food advisor',
            message: message,
            icon: Icons.auto_awesome,
            color: AppTheme.primarySoft,
            tabIndex: 3,
          ),
        );
      }
    }

    final patterns = wastePatterns?['patterns'];
    final wasteUnits = patterns is Map
        ? patterns.values.fold<int>(0, (sum, entry) {
            final data = entry is Map ? entry : const {};
            return sum + ((data['total_wasted'] as num?)?.toInt() ?? 0);
          })
        : 0;
    if (wasteUnits > 0) {
      items.add(
        _SmartNotification(
          title: 'Waste watch',
          message:
              '$wasteUnits waste units logged. Review risky dishes before prep.',
          icon: Icons.delete_outline,
          color: AppTheme.errorColor,
          tabIndex: 4,
        ),
      );
    }

    return items;
  }

  Map<dynamic, dynamic> _latestSale(List<dynamic> salesHistory) {
    Map<dynamic, dynamic> latest = const {};
    for (final sale in salesHistory) {
      final row = sale is Map ? sale : const {};
      if (latest.isEmpty || _compareSales(row, latest) > 0) {
        latest = row;
      }
    }
    return latest;
  }

  int _compareSales(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    final aDate = DateTime.tryParse(a['sale_date']?.toString() ?? '');
    final bDate = DateTime.tryParse(b['sale_date']?.toString() ?? '');
    final dateCompare = (aDate ?? DateTime(1900)).compareTo(
      bDate ?? DateTime(1900),
    );
    if (dateCompare != 0) return dateCompare;
    final aId = (a['id'] as num?)?.toInt() ?? 0;
    final bId = (b['id'] as num?)?.toInt() ?? 0;
    return aId.compareTo(bId);
  }

  Future<void> _openNotifications(
    BuildContext context,
    List<_SmartNotification> notifications,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, _, _) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 72, 12, 12),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 390,
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.72,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.outlineStrong),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.36),
                          blurRadius: 26,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Notifications',
                                style: Theme.of(
                                  dialogContext,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: notifications.isEmpty
                              ? const SingleChildScrollView(
                                  child: EmptyStateCard(
                                    icon: Icons.check_circle_outline,
                                    title: 'All clear',
                                    message:
                                        'No urgent prep, sales, or waste alerts right now.',
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final item = notifications[index];
                                    return _NotificationTile(
                                      item: item,
                                      onTap: item.tabIndex == null
                                          ? null
                                          : () {
                                              Navigator.of(dialogContext).pop();
                                              _goToTab(item.tabIndex!);
                                            },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, -0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
    );
  }
}

class _SmartNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final int? tabIndex;

  const _SmartNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.tabIndex,
  });
}

class _NotificationTile extends StatelessWidget {
  final _SmartNotification item;
  final VoidCallback? onTap;

  const _NotificationTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SmartCard(
        onTap: onTap,
        color: AppTheme.surfaceHigh,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final restaurantName =
        restaurantProvider.restaurantName ?? 'your restaurant';
    final dishes = context.watch<MenuProvider>().dishes;
    final salesProvider = context.watch<SalesProvider>();
    final wasteProvider = context.watch<WasteProvider>();
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final planningData = analyticsProvider.smartDashboardData;
    final revenue = salesProvider.salesHistory.fold<double>(0, (sum, sale) {
      final value = sale is Map ? sale['total_revenue'] : null;
      return sum + ((value as num?)?.toDouble() ?? 0);
    });
    final patterns = wasteProvider.wastePatterns?['patterns'];
    final wasteUnits = patterns is Map
        ? patterns.values.fold<int>(0, (sum, entry) {
            final data = entry is Map ? entry : const {};
            return sum + ((data['total_wasted'] as num?)?.toInt() ?? 0);
          })
        : 0;

    return SmartPage(
      title: 'Operations Dashboard',
      subtitle:
          'Plan prep from latest sales, profit, and demand for $restaurantName.',
      children: [
        _PrepDashboardCard(
          data: planningData,
          isLoading: analyticsProvider.isLoading,
          error: analyticsProvider.error,
          onRefresh: restaurantProvider.restaurantId == null
              ? null
              : () => context.read<AnalyticsProvider>().loadAnalytics(
                  restaurantProvider.restaurantId!,
                ),
        ),
        const SizedBox(height: 16),
        _SalesAnalyticsDashboard(
          data: planningData,
          salesHistory: salesProvider.salesHistory,
          dishCount: dishes.length,
          loggedRevenue: revenue,
          wasteUnits: wasteUnits,
        ),
        const SizedBox(height: 18),
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final actions = [
              ActionTile(
                title: 'Add Dish',
                subtitle: 'Open menu management',
                icon: Icons.add,
                onTap: () => onNavigate(1),
              ),
              ActionTile(
                title: 'Enter Sales',
                subtitle: 'Record daily performance',
                icon: Icons.point_of_sale,
                onTap: () => onNavigate(2),
              ),
              ActionTile(
                title: 'Review Insights',
                subtitle: 'Check AI suggestions',
                icon: Icons.lightbulb_outline,
                onTap: () => onNavigate(3),
              ),
            ];
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (final action in actions) ...[
                    action,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  Expanded(child: actions[i]),
                  if (i != actions.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SalesAnalyticsDashboard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final List<dynamic> salesHistory;
  final int dishCount;
  final double loggedRevenue;
  final int wasteUnits;

  const _SalesAnalyticsDashboard({
    required this.data,
    required this.salesHistory,
    required this.dishCount,
    required this.loggedRevenue,
    required this.wasteUnits,
  });

  @override
  Widget build(BuildContext context) {
    final forecasts = (data?['dish_forecasts'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final expectedSales =
        ((data?['expected_sales'] as num?)?.toDouble() ?? 0) > 0
        ? (data!['expected_sales'] as num).toDouble()
        : loggedRevenue;
    final expectedCustomers =
        (data?['expected_customers'] as num?)?.toInt() ?? 0;
    final units = forecasts.fold<int>(
      0,
      (sum, row) => sum + ((row['expected_quantity'] as num?)?.toInt() ?? 0),
    );
    final displayedUnits = units > 0 ? units : _loggedUnits();
    final avgTicket = expectedCustomers > 0
        ? expectedSales / expectedCustomers
        : salesHistory.isEmpty
        ? 0.0
        : loggedRevenue / salesHistory.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Analytics Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview of revenue, demand, prep targets, and menu performance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(
              label: '${salesHistory.length} sales records',
              color: AppTheme.successColor,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _MiniMetric(
                label: 'Total Revenue',
                value: formatMoney(expectedSales),
                detail: loggedRevenue > 0
                    ? 'Logged + forecast signal'
                    : 'Waiting for sales',
                color: AppTheme.successColor,
              ),
              _MiniMetric(
                label: 'Units Sold',
                value: displayedUnits.toString(),
                detail: dishCount > 0
                    ? '$dishCount menu items'
                    : 'Add menu items',
                color: const Color(0xFF4E9DFF),
              ),
              _MiniMetric(
                label: 'Waste Units',
                value: wasteUnits.toString(),
                detail: wasteUnits > 0
                    ? 'Review before prep'
                    : 'No waste alert',
                color: AppTheme.warningColor,
              ),
              _MiniMetric(
                label: 'Avg. Ticket',
                value: formatMoney(avgTicket),
                detail: expectedCustomers > 0
                    ? 'Per expected customer'
                    : 'Per sale record',
                color: const Color(0xFF7167FF),
              ),
            ];

            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 10),
                  ],
                ],
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
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final categoryPanel = _RevenueDonutPanel(forecasts: forecasts);
            final barPanel = _TopRevenueBarPanel(forecasts: forecasts);
            if (constraints.maxWidth < 820) {
              return Column(
                children: [categoryPanel, const SizedBox(height: 12), barPanel],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: categoryPanel),
                const SizedBox(width: 12),
                Expanded(child: barPanel),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final targets = _PrepTargetsPanel(forecasts: forecasts);
            final table = _PerformanceTablePanel(forecasts: forecasts);
            if (constraints.maxWidth < 820) {
              return Column(
                children: [targets, const SizedBox(height: 12), table],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: targets),
                const SizedBox(width: 12),
                Expanded(flex: 6, child: table),
              ],
            );
          },
        ),
      ],
    );
  }

  int _loggedUnits() {
    var total = 0;
    for (final sale in salesHistory) {
      final row = sale is Map ? sale : const {};
      final items = row['sales_items'] as List? ?? [];
      for (final item in items) {
        final itemRow = item is Map ? item : const {};
        total += (itemRow['quantity_sold'] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueDonutPanel extends StatelessWidget {
  final List<Map<dynamic, dynamic>> forecasts;

  const _RevenueDonutPanel({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final rows = forecasts.take(5).toList();
    final colors = [
      AppTheme.successColor,
      const Color(0xFF7167FF),
      AppTheme.warningColor,
      const Color(0xFF4E9DFF),
      const Color(0xFFFF7A1A),
    ];
    final hasData = rows.any(
      (row) => ((row['expected_sales'] as num?) ?? 0) > 0,
    );

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Menu Item',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: hasData
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 5,
                      centerSpaceRadius: 48,
                      sections: [
                        for (var i = 0; i < rows.length; i++)
                          PieChartSectionData(
                            value:
                                ((rows[i]['expected_sales'] as num?)
                                            ?.toDouble() ??
                                        0)
                                    .clamp(1, double.infinity)
                                    .toDouble(),
                            color: colors[i % colors.length],
                            radius: 42,
                            showTitle: false,
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Add sales to build chart',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (var i = 0; i < rows.length; i++)
                _LegendItem(
                  color: colors[i % colors.length],
                  label: rows[i]['name']?.toString() ?? 'Item',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TopRevenueBarPanel extends StatelessWidget {
  final List<Map<dynamic, dynamic>> forecasts;

  const _TopRevenueBarPanel({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final rows = forecasts.take(5).toList();
    final maxValue = rows.fold<double>(0, (max, row) {
      final value = (row['expected_sales'] as num?)?.toDouble() ?? 0;
      return value > max ? value : max;
    });

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Seller Forecast',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            Text(
              'Add menu and sales records to see top sellers.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...rows.map((row) {
              final value = (row['expected_sales'] as num?)?.toDouble() ?? 0;
              final ratio = maxValue <= 0 ? 0.0 : value / maxValue;
              return _HorizontalValueBar(
                label: row['name']?.toString() ?? 'Item',
                value: formatMoney(value),
                ratio: ratio,
              );
            }),
        ],
      ),
    );
  }
}

class _HorizontalValueBar extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;

  const _HorizontalValueBar({
    required this.label,
    required this.value,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppTheme.surfaceLow,
              color: const Color(0xFF7167FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrepTargetsPanel extends StatelessWidget {
  final List<Map<dynamic, dynamic>> forecasts;

  const _PrepTargetsPanel({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final rows = forecasts.take(5).toList();
    final maxPrep = rows.fold<int>(0, (max, row) {
      final prep = (row['preparation_quantity'] as num?)?.toInt() ?? 0;
      return prep > max ? prep : max;
    });

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prep Targets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            Text(
              'No prep targets yet',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...rows.map((row) {
              final prep = (row['preparation_quantity'] as num?)?.toInt() ?? 0;
              return _TargetBar(
                label: row['name']?.toString() ?? 'Item',
                percent: maxPrep <= 0 ? 0 : prep / maxPrep,
                value: '$prep units',
              );
            }),
        ],
      ),
    );
  }
}

class _TargetBar extends StatelessWidget {
  final String label;
  final double percent;
  final String value;

  const _TargetBar({
    required this.label,
    required this.percent,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.surfaceLow,
            color: AppTheme.successColor,
          ),
        ],
      ),
    );
  }
}

class _PerformanceTablePanel extends StatelessWidget {
  final List<Map<dynamic, dynamic>> forecasts;

  const _PerformanceTablePanel({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final rows = forecasts.take(5).toList();
    final totalSales = forecasts.fold<double>(
      0,
      (sum, row) => sum + ((row['expected_sales'] as num?)?.toDouble() ?? 0),
    );

    return SmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu Performance Table',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              'No performance rows yet',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ITEM')),
                  DataColumn(label: Text('SALES'), numeric: true),
                  DataColumn(label: Text('SHARE'), numeric: true),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: [
                  for (var i = 0; i < rows.length; i++)
                    DataRow(
                      cells: [
                        DataCell(Text(rows[i]['name']?.toString() ?? 'Item')),
                        DataCell(
                          Text(
                            formatMoney(
                              (rows[i]['expected_sales'] as num?)?.toDouble() ??
                                  0,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            totalSales <= 0
                                ? '0%'
                                : '${((((rows[i]['expected_sales'] as num?)?.toDouble() ?? 0) / totalSales) * 100).toStringAsFixed(1)}%',
                          ),
                        ),
                        DataCell(
                          StatusChip(
                            label: i == 0
                                ? 'Top'
                                : rows[i]['waste_risk']?.toString() == 'high'
                                ? 'Watch'
                                : 'Ok',
                            color: i == 0
                                ? AppTheme.successColor
                                : rows[i]['waste_risk']?.toString() == 'high'
                                ? AppTheme.warningColor
                                : AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrepDashboardCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  const _PrepDashboardCard({
    required this.data,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final forecasts = data?['dish_forecasts'] as List? ?? [];
    final recommendations = data?['recommendations'] as List? ?? [];
    final top = forecasts.isNotEmpty && forecasts.first is Map
        ? forecasts.first as Map
        : const {};
    final expectedSales = (data?['expected_sales'] as num?)?.toDouble() ?? 0;
    final expectedCustomers =
        (data?['expected_customers'] as num?)?.toInt() ?? 0;
    final topName = top['name']?.toString() ?? 'Add sales data';
    final topPrep = (top['preparation_quantity'] as num?)?.toInt() ?? 0;
    final topDemand = (top['expected_quantity'] as num?)?.toInt() ?? 0;

    return SmartCard(
      color: AppTheme.surfaceHigh,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s Prep Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Refresh plan',
                onPressed: onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null && data == null) ...[
            Text(
              error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.warningColor),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                _PrepStat(
                  label: 'Prepare most',
                  value: topName,
                  detail: topPrep > 0
                      ? '$topPrep prep / $topDemand demand'
                      : 'Waiting for sales',
                  icon: Icons.local_dining,
                ),
                _PrepStat(
                  label: 'Predicted sales',
                  value: formatMoney(expectedSales),
                  detail: '$expectedCustomers expected customers',
                  icon: Icons.payments_outlined,
                ),
              ];
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    for (final stat in stats) ...[
                      stat,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(child: stats[i]),
                    if (i != stats.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (recommendations.isNotEmpty)
            Text(
              (recommendations.first as Map)['message']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (forecasts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Top items to prepare',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...forecasts.take(4).map((item) {
              final row = item is Map ? item : const {};
              return _PrepForecastRow(row: row);
            }),
          ],
        ],
      ),
    );
  }
}

class _PrepStat extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;

  const _PrepStat({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrepForecastRow extends StatelessWidget {
  final Map<dynamic, dynamic> row;

  const _PrepForecastRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final name = row['name']?.toString() ?? 'Unknown item';
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
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(label: 'Prep $prep'),
          const SizedBox(width: 8),
          Text('$demand demand', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          Text(
            '${formatMoney(sales)} / $marginText',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
