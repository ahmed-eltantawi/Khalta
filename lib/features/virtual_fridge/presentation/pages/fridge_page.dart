import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/virtual_fridge/domain/entities/fridge_item_entity.dart';
import '../../../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../../../../features/search/presentation/widgets/meal_card.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/home/presentation/cubits/camera_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});
  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('My Fridge 🧊',
                      style: TextStyle(color: AppTheme.textP(context), fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textS(context),
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'My Items'), Tab(text: '📷 Scan Photo')],
              ),
            ),
            const SizedBox(height: 8),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ItemsTab(onAdd: () => _showAddDialog(context)),
                  _ScanPhotoTab(onIngredientAdded: () => _tabController.animateTo(0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<FridgeBloc>(),
        child: _AddItemSheet(),
      ),
    );
  }
}

// ─── Items Tab ───────────────────────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  final VoidCallback onAdd;
  const _ItemsTab({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeBloc, FridgeState>(
      builder: (context, state) {
        if (state is FridgeLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (state is FridgeLoaded && state.items.isEmpty) {
          return _buildEmpty(context);
        }
        if (state is FridgeLoaded) {
          return CustomScrollView(slivers: [
            // Find recipes button
            if (state.items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<FridgeBloc>().add(const SearchRecipesFromFridgeEvent()),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Find Recipes From My Fridge'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FridgeItemCard(
                    item: state.items[i], index: i,
                    onDelete: () => context.read<FridgeBloc>().add(RemoveFridgeItemEvent(state.items[i].id)),
                    onEdit: () => _showEditDialog(ctx, state.items[i]),
                  ),
                  childCount: state.items.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
                ),
              ),
            ),
            if (state.suggestedMeals != null && state.suggestedMeals!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text('Recipes You Can Make',
                    style: TextStyle(color: AppTheme.textP(context), fontSize: 17, fontWeight: FontWeight.w600)),
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
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ]);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🧊', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('Your fridge is empty', style: TextStyle(color: AppTheme.textP(context), fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Add ingredients to find matching recipes.', style: TextStyle(color: AppTheme.textS(context))),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add First Ingredient')),
      ],
    ));
  }

  void _showEditDialog(BuildContext context, FridgeItemEntity item) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<FridgeBloc>(),
        child: _EditItemSheet(item: item),
      ),
    );
  }
}

// ─── Scan Photo Tab ──────────────────────────────────────────────────────────

class _ScanPhotoTab extends StatefulWidget {
  final VoidCallback onIngredientAdded;
  const _ScanPhotoTab({required this.onIngredientAdded});
  @override
  State<_ScanPhotoTab> createState() => _ScanPhotoTabState();
}

class _ScanPhotoTabState extends State<_ScanPhotoTab> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<String> _detectedIngredients = [];
  bool _scanning = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1024);
    if (picked == null) return;
    setState(() { _selectedImage = File(picked.path); _detectedIngredients = []; });
    _scanImage(picked.path);
  }

  Future<void> _scanImage(String path) async {
    setState(() => _scanning = true);
    try {
      final cubit = sl<CameraCubit>();
      await cubit.scanImage(path);
      if (cubit.state is CameraIngredientsDetected) {
        setState(() => _detectedIngredients = (cubit.state as CameraIngredientsDetected).ingredients);
      } else {
        setState(() => _detectedIngredients = []);
      }
    } catch (_) {
      setState(() => _detectedIngredients = []);
    }
    setState(() => _scanning = false);
  }

  void _addIngredient(String name) {
    final item = FridgeItemEntity(
      id: const Uuid().v4(), name: name, quantity: '1', unit: 'piece',
      expiryDate: null, addedAt: DateTime.now(),
    );
    context.read<FridgeBloc>().add(AddFridgeItemEvent(item));
    setState(() => _detectedIngredients.remove(name));
    AppSnackBar.showSuccess(context, '$name added to fridge!');
    if (_detectedIngredients.isEmpty) widget.onIngredientAdded();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Pick buttons
        Row(children: [
          Expanded(child: _PickButton(
            icon: Icons.camera_alt_rounded, label: 'Take Photo',
            onTap: () => _pickImage(ImageSource.camera),
          )),
          const SizedBox(width: 12),
          Expanded(child: _PickButton(
            icon: Icons.photo_library_rounded, label: 'Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          )),
        ]),
        const SizedBox(height: 16),

        // Selected image preview
        if (_selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ).animate().fadeIn(duration: 300.ms),

        if (_scanning)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 12),
              Text('Analyzing image...', style: TextStyle(color: AppTheme.textSecondary)),
            ]),
          ),

        // Detected ingredients
        if (_detectedIngredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Detected Ingredients', style: TextStyle(color: AppTheme.textP(context), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_detectedIngredients.length, (i) {
            final name = _detectedIngredients[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context), width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.kitchen_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: TextStyle(color: AppTheme.textP(context), fontSize: 14, fontWeight: FontWeight.w500))),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppTheme.success),
                  onPressed: () => _addIngredient(name),
                ),
              ]),
            ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 300.ms).slideX(begin: 0.05);
          }),
        ],

        // Empty state
        if (_selectedImage == null && !_scanning)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Text('📸', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Scan your ingredients', style: TextStyle(color: AppTheme.textP(context), fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Take a photo or pick from gallery\nto auto-detect ingredients',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textS(context), height: 1.5)),
            ]),
          ),

        if (_selectedImage != null && !_scanning && _detectedIngredients.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No ingredients detected. Try a clearer photo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textS(context))),
          ),
      ]),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.primary, size: 32),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppTheme.textP(context), fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Fridge Item Card ────────────────────────────────────────────────────────

class _FridgeItemCard extends StatelessWidget {
  final FridgeItemEntity item;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _FridgeItemCard({required this.item, required this.index, required this.onDelete, required this.onEdit});

  Color get _expiryColor {
    if (item.isExpired) return AppTheme.error;
    if (item.isExpiringSoon) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      onLongPress: () => _confirmDelete(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context), width: 0.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            CachedNetworkImage(
              imageUrl: ApiConstants.ingredientImageUrl(item.name),
              width: 44, height: 44,
              errorWidget: (_, __, ___) => Icon(Icons.kitchen_rounded, color: AppTheme.textH(context), size: 36),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textH(context)),
              onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
          const Spacer(),
          Text(item.name, style: TextStyle(color: AppTheme.textP(context), fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${item.quantity} ${item.unit}', style: TextStyle(color: AppTheme.textS(context), fontSize: 11)),
          if (item.expiryDate != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _expiryColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                item.isExpired ? 'Expired' : item.isExpiringSoon ? 'Expiring soon' : DateFormat('MMM dd').format(item.expiryDate!),
                style: TextStyle(color: _expiryColor, fontSize: 10),
              ),
            ]),
          ],
        ]),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.card(context),
      title: Text('Remove Item', style: TextStyle(color: AppTheme.textP(context))),
      content: Text('Remove ${item.name}?', style: TextStyle(color: AppTheme.textS(context))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(context); onDelete(); },
          child: const Text('Remove', style: TextStyle(color: AppTheme.error))),
      ],
    ));
  }
}

// ─── Add Item Sheet ──────────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  String _unit = 'piece';
  DateTime? _expiry;
  final _units = ['piece', 'g', 'kg', 'ml', 'L', 'cup', 'tbsp', 'tsp'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Ingredient', style: TextStyle(color: AppTheme.textP(context), fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, autofocus: true,
          style: TextStyle(color: AppTheme.textP(context)),
          decoration: InputDecoration(labelText: 'Ingredient name', labelStyle: TextStyle(color: AppTheme.textH(context)))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number,
            style: TextStyle(color: AppTheme.textP(context)),
            decoration: InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: AppTheme.textH(context))))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: _unit, dropdownColor: AppTheme.card(context),
            style: TextStyle(color: AppTheme.textP(context)),
            decoration: InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: AppTheme.textH(context))),
            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _unit = v ?? 'piece'),
          )),
        ]),
        const SizedBox(height: 12),
        _ExpiryPicker(expiry: _expiry, onChanged: (d) => setState(() => _expiry = d)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            final item = FridgeItemEntity(id: const Uuid().v4(), name: _nameCtrl.text.trim(),
              quantity: _qtyCtrl.text.trim(), unit: _unit, expiryDate: _expiry, addedAt: DateTime.now());
            context.read<FridgeBloc>().add(AddFridgeItemEvent(item));
            Navigator.pop(context);
            AppSnackBar.showSuccess(context, '${item.name} added!');
          },
          child: const Text('Add to Fridge'),
        )),
      ]),
    );
  }
}

// ─── Edit Item Sheet ─────────────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final FridgeItemEntity item;
  const _EditItemSheet({required this.item});
  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late String _unit;
  DateTime? _expiry;
  final _units = ['piece', 'g', 'kg', 'ml', 'L', 'cup', 'tbsp', 'tsp'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.quantity);
    _unit = widget.item.unit;
    _expiry = widget.item.expiryDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Edit Ingredient', style: TextStyle(color: AppTheme.textP(context), fontSize: 18, fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
            onPressed: () {
              context.read<FridgeBloc>().add(RemoveFridgeItemEvent(widget.item.id));
              Navigator.pop(context);
              AppSnackBar.showSuccess(context, '${widget.item.name} removed');
            },
          ),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, style: TextStyle(color: AppTheme.textP(context)),
          decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppTheme.textH(context)))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number,
            style: TextStyle(color: AppTheme.textP(context)),
            decoration: InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: AppTheme.textH(context))))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: _unit, dropdownColor: AppTheme.card(context),
            style: TextStyle(color: AppTheme.textP(context)),
            decoration: InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: AppTheme.textH(context))),
            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _unit = v ?? 'piece'),
          )),
        ]),
        const SizedBox(height: 12),
        _ExpiryPicker(expiry: _expiry, onChanged: (d) => setState(() => _expiry = d)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            // Remove old, add updated
            context.read<FridgeBloc>().add(RemoveFridgeItemEvent(widget.item.id));
            final updated = FridgeItemEntity(id: widget.item.id, name: _nameCtrl.text.trim(),
              quantity: _qtyCtrl.text.trim(), unit: _unit, expiryDate: _expiry, addedAt: widget.item.addedAt);
            context.read<FridgeBloc>().add(AddFridgeItemEvent(updated));
            Navigator.pop(context);
            AppSnackBar.showSuccess(context, 'Updated ${updated.name}');
          },
          child: const Text('Save Changes'),
        )),
      ]),
    );
  }
}

// ─── Shared Expiry Picker ────────────────────────────────────────────────────

class _ExpiryPicker extends StatelessWidget {
  final DateTime? expiry;
  final ValueChanged<DateTime?> onChanged;
  const _ExpiryPicker({required this.expiry, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: expiry ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textH(context)),
          const SizedBox(width: 8),
          Text(
            expiry != null ? 'Expires: ${DateFormat('MMM dd, yyyy').format(expiry!)}' : 'Set expiry date (optional)',
            style: TextStyle(color: AppTheme.textS(context), fontSize: 14),
          ),
        ]),
      ),
    );
  }
}
