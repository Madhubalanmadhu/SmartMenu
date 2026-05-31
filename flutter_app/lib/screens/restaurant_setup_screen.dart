import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/restaurant_provider.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class RestaurantSetupScreen extends StatefulWidget {
  final String userToken;

  const RestaurantSetupScreen({super.key, required this.userToken});

  @override
  State<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends State<RestaurantSetupScreen> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _weatherCityController = TextEditingController();
  final _countryCodeController = TextEditingController(text: 'IN');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _weatherCityController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _setupRestaurant() async {
    if (_nameController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _countryCodeController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    final apiService = context.read<ApiService>();
    final restaurantProvider = context.read<RestaurantProvider>();
    setState(() => _isLoading = true);
    try {
      final restaurant = await apiService.createRestaurant(
        widget.userToken,
        _nameController.text.trim(),
        _typeController.text.trim(),
        _addressController.text.trim(),
        _phoneController.text.trim(),
        _emailController.text.trim(),
        weatherCity: _weatherCityController.text.trim(),
        countryCode: _countryCodeController.text.trim().toUpperCase(),
      );

      restaurantProvider.setRestaurant(restaurant);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to create restaurant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartTopBar(showBack: true),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'Set Up Profile',
                    subtitle:
                        'Add the restaurant details SmartMenu will use for operations planning.',
                  ),
                  const SizedBox(height: 18),
                  SmartCard(
                    color: AppTheme.surfaceHigh,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Setup checklist',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        const _SetupChecklistItem(
                          icon: Icons.storefront_outlined,
                          label: 'Restaurant identity and contact details',
                        ),
                        const SizedBox(height: 8),
                        const _SetupChecklistItem(
                          icon: Icons.cloud_queue_outlined,
                          label: 'Forecast city for weather-aware demand',
                        ),
                        const SizedBox(height: 8),
                        const _SetupChecklistItem(
                          icon: Icons.public_outlined,
                          label: 'Calendar region for holiday signals',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SmartCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.errorColor.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Restaurant Name',
                            hintText: 'e.g. Madras Spice House',
                            prefixIcon: Icon(Icons.restaurant_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _typeController,
                          decoration: const InputDecoration(
                            labelText: 'Food Style',
                            hintText: 'South Indian, cafe, biryani, fast food',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            hintText: 'Full address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _weatherCityController,
                          decoration: const InputDecoration(
                            labelText: 'Forecast City',
                            hintText: 'e.g. Chennai',
                            prefixIcon: Icon(Icons.cloud_queue_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _countryCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Calendar Country Code',
                            hintText: 'IN',
                            prefixIcon: Icon(Icons.public_outlined),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '+91 98765 43210',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Restaurant Email',
                            hintText: 'hello@restaurant.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _setupRestaurant,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimary,
                                  ),
                                )
                              : const Text('Complete Setup'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupChecklistItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SetupChecklistItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
