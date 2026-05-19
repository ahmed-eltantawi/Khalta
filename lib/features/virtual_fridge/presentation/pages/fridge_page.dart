import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/virtual_fridge/domain/entities/fridge_item_entity.dart';
import '../../../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../../../../features/search/presentation/widgets/meal_card.dart';
import '../../../../core/widgets/app_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FridgePage extends StatelessWidget {
  const FridgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: BlocBuilder<FridgeBloc, FridgeState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Fridge 🧊',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700)),
                            if (state is FridgeLoaded)
                              Text(
                                '${state.items.length} item${state.items.length == 1 ? '' : 's'}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                ),
                // ── Cook with fridge button ──────────────────────────────
                if (state is FridgeLoaded && state.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: ElevatedButton.icon(
                        onPressed: () => context
                            .read<FridgeBloc>()
                            .add(const SearchRecipesFromFridgeEvent()),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Find Recipes From My Fridge'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                // ── Items grid ────────────────────────────────────────────
                if (state is FridgeLoading)
                  const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )),
                  ),
                if (state is FridgeLoaded && state.items.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty(context)),
                if (state is FridgeLoaded && state.items.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _FridgeItemCard(
                          item: state.items[i],
                          index: i,
                          onDelete: () => context
                              .read<FridgeBloc>()
                              .add(RemoveFridgeItemEvent(state.items[i].id)),
                        ),
                        childCount: state.items.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                    ),
                  ),
                // ── Suggested recipes ─────────────────────────────────────
                if (state is FridgeLoaded && (state.suggestedMeals?.isNotEmpty ?? false)) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text('Recipes You Can Make',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => MealCard(meal: state.suggestedMeals![i], index: i),
                        childCount: state.suggestedMeals!.length.clamp(0, 10),
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Text('🧊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Your fridge is empty',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add ingredients to track what you have\nand find matching recipes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Ingredient'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<FridgeBloc>(),
        child: const _AddItemSheet(),
      ),
    );
  }
}

class _FridgeItemCard extends StatelessWidget {
  final FridgeItemEntity item;
  final int index;
  final VoidCallback onDelete;

  const _FridgeItemCard({required this.item, required this.index, required this.onDelete});

  Color get _expiryColor {
    if (item.isExpired) return AppTheme.error;
    if (item.isExpiringSoon) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CachedNetworkImage(
                  imageUrl: ApiConstants.ingredientImageUrl(item.name),
                  width: 44,
                  height: 44,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.kitchen_rounded,
                    color: AppTheme.textHint,
                    size: 36,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textHint),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.name,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${item.quantity} ${item.unit}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            if (item.expiryDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _expiryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.isExpired
                        ? 'Expired'
                        : item.isExpiringSoon
                            ? 'Expiring soon'
                            : DateFormat('MMM dd').format(item.expiryDate!),
                    style: TextStyle(color: _expiryColor, fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Remove Item', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Remove ${item.name} from your fridge?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _unit = 'piece';
  DateTime? _expiryDate;

  final _units = ['piece', 'g', 'kg', 'ml', 'L', 'cup', 'tbsp', 'tsp'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Ingredient',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Ingredient name',
              labelStyle: TextStyle(color: AppTheme.textHint),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: TextStyle(color: AppTheme.textHint),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  dropdownColor: AppTheme.cardDark,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: AppTheme.textHint)),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _unit = v ?? 'piece'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
                  ),
                  child: child!,
                ),
              );
              setState(() => _expiryDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Text(
                    _expiryDate != null
                        ? 'Expires: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}'
                        : 'Set expiry date (optional)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _add,
              child: const Text('Add to Fridge'),
            ),
          ),
        ],
      ),
    );
  }

  void _add() {
    if (_nameController.text.trim().isEmpty) return;
    final item = FridgeItemEntity(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      quantity: _quantityController.text.trim(),
      unit: _unit,
      expiryDate: _expiryDate,
      addedAt: DateTime.now(),
    );
    context.read<FridgeBloc>().add(AddFridgeItemEvent(item));
    Navigator.pop(context);
    AppSnackBar.showSuccess(context, '${item.name} added to fridge!');
  }
}
