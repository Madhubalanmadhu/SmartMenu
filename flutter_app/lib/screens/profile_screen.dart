import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/analytics_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/waste_provider.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openEditProfileDialog(BuildContext context) async {
    final restaurantProvider = context.read<RestaurantProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();
    final restaurant = restaurantProvider.restaurant;
    if (restaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant details are still loading')),
      );
      return;
    }

    final nameController = TextEditingController(text: restaurant.name);
    final typeController = TextEditingController(text: restaurant.type);
    final addressController = TextEditingController(text: restaurant.address);
    final phoneController = TextEditingController(text: restaurant.phone);
    final emailController = TextEditingController(text: restaurant.email);
    final weatherCityController = TextEditingController(
      text: restaurant.weatherCity,
    );
    final countryCodeController = TextEditingController(
      text: restaurant.countryCode,
    );
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: typeController,
                        decoration: const InputDecoration(
                          labelText: 'Food Style',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weatherCityController,
                        decoration: const InputDecoration(
                          labelText: 'Forecast City',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: countryCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Calendar Country Code',
                          hintText: 'IN',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final type = typeController.text.trim();
                          final address = addressController.text.trim();
                          final phone = phoneController.text.trim();
                          final email = emailController.text.trim();
                          final weatherCity = weatherCityController.text.trim();
                          final countryCode = countryCodeController.text
                              .trim()
                              .toUpperCase();

                          if (name.isEmpty ||
                              type.isEmpty ||
                              address.isEmpty ||
                              phone.isEmpty ||
                              email.isEmpty ||
                              countryCode.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            await restaurantProvider.updateRestaurant(
                              name,
                              type,
                              address,
                              phone,
                              email,
                              weatherCity: weatherCity,
                              countryCode: countryCode,
                            );
                            if (rootNavigator.canPop()) {
                              rootNavigator.pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated'),
                                ),
                              );
                            }
                            await analyticsProvider.loadAnalytics(
                              restaurant.id,
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onPrimary,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    typeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    weatherCityController.dispose();
    countryCodeController.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _exportRestaurantData(BuildContext context) async {
    final apiService = context.read<ApiService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final data = await apiService.exportRestaurantData();
      const encoder = JsonEncoder.withIndent('  ');
      await Clipboard.setData(ClipboardData(text: encoder.convert(data)));
      messenger.showSnackBar(
        const SnackBar(content: Text('Restaurant backup copied')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  List<_ProfileNotification> _buildNotifications(BuildContext context) {
    final salesHistory = context.watch<SalesProvider>().salesHistory;
    final dashboard = context.watch<AnalyticsProvider>().smartDashboardData;
    final wastePatterns = context.watch<WasteProvider>().wastePatterns;
    final forecasts = dashboard?['dish_forecasts'] as List? ?? [];
    final items = <_ProfileNotification>[];

    if (salesHistory.isEmpty) {
      items.add(
        const _ProfileNotification(
          title: 'Sales data needed',
          message: 'Enter or upload sales so forecasts can update.',
          icon: Icons.point_of_sale,
          color: AppTheme.warningColor,
        ),
      );
    }

    if (forecasts.isNotEmpty && forecasts.first is Map) {
      final top = forecasts.first as Map;
      items.add(
        _ProfileNotification(
          title: 'Prep priority',
          message:
              'Prepare ${(top['preparation_quantity'] as num?)?.toInt() ?? 0} units of ${top['name'] ?? 'top item'} next.',
          icon: Icons.restaurant,
          color: AppTheme.primary,
        ),
      );
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
        _ProfileNotification(
          title: 'Waste review',
          message: '$wasteUnits wasted units logged. Review waste patterns.',
          icon: Icons.delete_outline,
          color: AppTheme.errorColor,
        ),
      );
    }

    return items;
  }

  void _openNotifications(
    BuildContext context,
    List<_ProfileNotification> notifications,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          notifications: notifications
              .map(
                (item) => NotificationItem(
                  title: item.title,
                  message: item.message,
                  icon: item.icon,
                  color: item.color,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notifications = _buildNotifications(context);

    return Scaffold(
      appBar: SmartTopBar(
        showBack: true,
        onNotifications: () => _openNotifications(context, notifications),
        notificationCount: notifications.length,
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, _) {
          final restaurant = restaurantProvider.restaurant;
          final displayName = user?.displayName?.trim();
          final email = user?.email ?? 'No email';

          return SmartPage(
            title: 'Profile',
            subtitle: 'Manage account access and restaurant operating details.',
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              SmartCard(
                color: AppTheme.surfaceHigh,
                padding: const EdgeInsets.all(22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final account = Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withValues(alpha: 0.18),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            size: 32,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName == null || displayName.isEmpty
                                    ? 'SmartMenu User'
                                    : displayName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 10),
                              const StatusChip(label: 'Owner account'),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 700) {
                      return account;
                    }
                    return Row(
                      children: [
                        Expanded(child: account),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              restaurant?.name ?? 'Restaurant not set',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.end,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              restaurant?.type ?? 'Complete profile',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (restaurantProvider.isLoading && restaurant == null)
                const LoadingWidget(message: 'Loading restaurant profile...')
              else ...[
                _buildProfileSection(
                  context,
                  title: 'Business Profile',
                  icon: Icons.storefront_outlined,
                  children: [
                    _buildProfileField(
                      context,
                      'Name',
                      restaurant?.name ?? 'Not set',
                      Icons.badge_outlined,
                    ),
                    _buildProfileField(
                      context,
                      'Food Style',
                      restaurant?.type ?? 'Not set',
                      Icons.restaurant_menu_outlined,
                    ),
                    _buildProfileField(
                      context,
                      'Address',
                      restaurant?.address ?? 'Not set',
                      Icons.location_on_outlined,
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildProfileSection(
                  context,
                  title: 'Location Intelligence',
                  icon: Icons.public_outlined,
                  children: [
                    _buildProfileField(
                      context,
                      'Forecast City',
                      restaurant?.weatherCity.trim().isNotEmpty == true
                          ? restaurant!.weatherCity
                          : 'Derived from address',
                      Icons.cloud_queue_outlined,
                    ),
                    _buildProfileField(
                      context,
                      'Calendar Region',
                      restaurant?.countryCode.trim().isNotEmpty == true
                          ? restaurant!.countryCode
                          : 'IN',
                      Icons.event_note_outlined,
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildProfileSection(
                  context,
                  title: 'Contact Details',
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _buildProfileField(
                      context,
                      'Phone',
                      restaurant?.phone ?? 'Not set',
                      Icons.phone_outlined,
                    ),
                    _buildProfileField(
                      context,
                      'Email',
                      restaurant?.email ?? 'Not set',
                      Icons.email_outlined,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
              if (restaurantProvider.error != null) ...[
                const SizedBox(height: 12),
                AppErrorWidget(message: restaurantProvider.error!),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: restaurantProvider.isLoading
                        ? null
                        : () => _openEditProfileDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportRestaurantData(context),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export Data'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SmartCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileField(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ProfileNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _ProfileNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}
