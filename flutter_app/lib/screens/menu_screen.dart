import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/dish.dart';
import '../providers/analytics_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/common_widgets.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const List<String> _dishNameSuggestionSeed = [
    'Chicken Biryani',
    'Mutton Biryani',
    'Veg Biryani',
    'Hyderabadi Biryani',
    'Paneer Butter Masala',
    'Butter Chicken',
    'Chicken Curry',
    'Fish Curry',
    'Masala Dosa',
    'Plain Dosa',
    'Idli Sambar',
    'Vada',
    'Chapati',
    'Butter Naan',
    'Parotta',
    'Fried Rice',
    'Chicken Fried Rice',
    'Veg Noodles',
    'Chicken Noodles',
    'Gobi Manchurian',
    'Chicken 65',
    'Tandoori Chicken',
    'Samosa',
    'Mango Lassi',
    'Fresh Lime Soda',
    'Tea',
    'Coffee',
    'Gulab Jamun',
    'Ice Cream',
  ];

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantId = context.read<RestaurantProvider>().restaurantId;
      if (restaurantId != null) {
        context.read<MenuProvider>().loadDishes(restaurantId);
      }
    });
  }

  Future<void> _openDishDialog(int restaurantId, {Dish? dish}) async {
    final nameController = TextEditingController(text: dish?.name ?? '');
    final nameFocusNode = FocusNode();
    final costController = TextEditingController(
      text: dish == null ? '' : dish.ingredientCost.toStringAsFixed(2),
    );
    final priceController = TextEditingController(
      text: dish == null ? '' : dish.sellingPrice.toStringAsFixed(2),
    );
    final servingsController = TextEditingController(
      text: (dish?.servingsPerBatch ?? 1).toString(),
    );
    int? selectedCategoryId = dish?.categoryId;
    final menuProvider = context.read<MenuProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();
    final pageContext = context;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(dish == null ? 'Add New Dish' : 'Edit Dish'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryId,
                        dropdownColor: AppTheme.surfaceHigh,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: menuProvider.categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedCategoryId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      RawAutocomplete<String>(
                        textEditingController: nameController,
                        focusNode: nameFocusNode,
                        optionsBuilder: (textEditingValue) {
                          return _dishNameSuggestions(
                            menuProvider.dishes,
                            textEditingValue.text,
                          );
                        },
                        onSelected: (selection) {
                          nameController.text = selection;
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Dish Name',
                                ),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              color: AppTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 220,
                                  maxWidth: 360,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.restaurant_menu_outlined,
                                        size: 18,
                                      ),
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickDishTags(menuProvider.dishes)
                            .map(
                              (name) => ActionChip(
                                label: Text(name),
                                onPressed: () {
                                  nameController.text = name;
                                  nameController.selection =
                                      TextSelection.collapsed(
                                        offset: name.length,
                                      );
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: costController,
                        decoration: const InputDecoration(
                          labelText: 'Ingredient Cost for Batch',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: servingsController,
                        decoration: const InputDecoration(
                          labelText: 'Items Made from This Batch',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price per Item',
                        ),
                        keyboardType: TextInputType.number,
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
                          final cost =
                              double.tryParse(costController.text.trim()) ?? 0;
                          final price =
                              double.tryParse(priceController.text.trim()) ?? 0;
                          final servings =
                              int.tryParse(servingsController.text.trim()) ?? 0;

                          if (selectedCategoryId == null ||
                              name.isEmpty ||
                              cost < 0 ||
                              servings <= 0 ||
                              price <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all fields correctly',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          if (dish == null) {
                            await menuProvider.addDish(
                              restaurantId,
                              selectedCategoryId!,
                              name,
                              cost,
                              price,
                              servings,
                            );
                          } else {
                            await menuProvider.updateDish(
                              dish.id,
                              restaurantId,
                              selectedCategoryId!,
                              name,
                              cost,
                              price,
                              servings,
                            );
                          }

                          final menuError = menuProvider.error;
                          if (menuError != null) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(menuError)),
                              );
                            }
                            return;
                          }

                          if (rootNavigator.canPop()) {
                            rootNavigator.pop();
                          }
                          if (pageContext.mounted) {
                            await analyticsProvider.loadAnalytics(restaurantId);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(dish == null ? 'Add Dish' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    nameFocusNode.dispose();
    costController.dispose();
    priceController.dispose();
    servingsController.dispose();
  }

  Iterable<String> _dishNameSuggestions(
    List<Dish> existingDishes,
    String text,
  ) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return const Iterable<String>.empty();

    final names = <String>{
      ...existingDishes.map((dish) => dish.name),
      ..._dishNameSuggestionSeed,
    };
    final matches = names.where((name) {
      final normalized = name.toLowerCase();
      final words = normalized.split(RegExp(r'\s+'));
      return normalized.contains(query) ||
          words.any((word) => word.startsWith(query));
    }).toList()..sort((a, b) => a.length.compareTo(b.length));

    return matches.take(8);
  }

  List<String> _quickDishTags(List<Dish> existingDishes) {
    final existing = existingDishes.map((dish) => dish.name).take(3);
    return <String>{
      ...existing,
      'Chicken Biryani',
      'Masala Dosa',
      'Tea',
    }.take(5).toList();
  }

  Future<void> _confirmDeleteDish(Dish dish) async {
    final restaurantId = context.read<RestaurantProvider>().restaurantId;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Dish'),
          content: Text('Delete ${dish.name} from the menu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      await context.read<MenuProvider>().deleteDish(dish.id);
      if (restaurantId != null && mounted) {
        await context.read<AnalyticsProvider>().loadAnalytics(restaurantId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = context.watch<RestaurantProvider>().restaurantId;

    return Consumer<MenuProvider>(
      builder: (context, menuProvider, _) {
        final selectedCategoryExists = menuProvider.categories.any(
          (c) => c.id == _selectedCategoryId,
        );
        final selectedCategoryId = selectedCategoryExists
            ? _selectedCategoryId
            : null;
        final filteredDishes = selectedCategoryId == null
            ? menuProvider.dishes
            : menuProvider.dishes
                  .where((dish) => dish.categoryId == selectedCategoryId)
                  .toList();
        final missingCostCount = menuProvider.dishes
            .where((dish) => dish.ingredientCost <= 0)
            .length;

        return SmartPage(
          title: 'Menu Management',
          subtitle: 'Keep dish prices, batches, and availability organized.',
          trailing: restaurantId == null
              ? null
              : IconButton.filled(
                  onPressed: () => _openDishDialog(restaurantId),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add dish',
                ),
          floatingActionButton: restaurantId == null
              ? null
              : FloatingActionButton(
                  onPressed: () => _openDishDialog(restaurantId),
                  tooltip: 'Add dish',
                  child: const Icon(Icons.add),
                ),
          children: [
            if (missingCostCount > 0) ...[
              _MissingCostBanner(count: missingCostCount),
              const SizedBox(height: 12),
            ],
            _buildCategoryTabs(menuProvider, selectedCategoryId),
            const SizedBox(height: 16),
            if (menuProvider.isLoading)
              const LoadingWidget(message: 'Loading menu...')
            else if (menuProvider.error != null)
              AppErrorWidget(
                message: menuProvider.error!,
                onRetry: restaurantId == null
                    ? null
                    : () =>
                          context.read<MenuProvider>().loadDishes(restaurantId),
              )
            else if (filteredDishes.isEmpty)
              const EmptyStateCard(
                icon: Icons.restaurant_menu,
                title: 'No dishes here yet',
                message:
                    'Add dishes to start tracking sales and menu performance.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: filteredDishes.map((dish) {
                      return SizedBox(
                        width: wide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _DishCard(
                          dish: dish,
                          onEdit: restaurantId == null
                              ? null
                              : () => _openDishDialog(restaurantId, dish: dish),
                          onDelete: () => _confirmDeleteDish(dish),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTabs(
    MenuProvider menuProvider,
    int? selectedCategoryId,
  ) {
    final chips = [
      ChoiceChip(
        label: const Text('All'),
        selected: selectedCategoryId == null,
        onSelected: (_) => setState(() => _selectedCategoryId = null),
      ),
      ...menuProvider.categories.map((category) {
        return ChoiceChip(
          label: Text(category.name),
          selected: selectedCategoryId == category.id,
          onSelected: (_) => setState(() => _selectedCategoryId = category.id),
        );
      }),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips) ...[chip, const SizedBox(width: 8)],
        ],
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Dish dish;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DishCard({required this.dish, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final muted = !dish.isActive;
    final costMissing = dish.ingredientCost <= 0;

    return SmartCard(
      muted: muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          dish.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!dish.isActive)
                          const StatusChip(
                            label: 'Out of stock',
                            color: AppTheme.errorColor,
                          ),
                        if (costMissing)
                          const StatusChip(
                            label: 'Cost missing',
                            color: AppTheme.warningColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Batch ${formatMoney(dish.ingredientCost)} / ${dish.servingsPerBatch} items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Unit cost ${formatMoney(dish.unitIngredientCost)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMoney(dish.sellingPrice),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('BATCH INFO', style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Edit dish',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Delete dish',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissingCostBanner extends StatelessWidget {
  final int count;

  const _MissingCostBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      color: AppTheme.surfaceHigh,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.price_check_outlined,
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'dish needs' : 'dishes need'} ingredient cost',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'Add batch costs when ready to unlock exact margins and profit analysis.',
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
