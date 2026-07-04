import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/virtual_fridge/domain/entities/fridge_item_entity.dart';
import '../../../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../../../../features/home/presentation/cubits/receipt_scan_cubit.dart';

/// Tab widget for scanning receipts / ingredient lists and confirming items one-by-one.
class ReceiptScanTab extends StatefulWidget {
  final VoidCallback onIngredientsAdded;
  const ReceiptScanTab({super.key, required this.onIngredientsAdded});

  @override
  State<ReceiptScanTab> createState() => _ReceiptScanTabState();
}

class _ReceiptScanTabState extends State<ReceiptScanTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 2048);
    if (picked == null) return;
    if (mounted) {
      context.read<ReceiptScanCubit>().scanReceipt(picked.path);
    }
  }

  void _handleConfirmationComplete(ReceiptConfirmationComplete state) {
    final accepted = state.acceptedIngredients;
    if (accepted.isEmpty) {
      AppSnackBar.showInfo(context, 'No ingredients were added.');
      context.read<ReceiptScanCubit>().reset();
      return;
    }

    final fridgeBloc = context.read<FridgeBloc>();
    for (final ingredient in accepted) {
      final item = FridgeItemEntity(
        id: const Uuid().v4(),
        name: ingredient.name,
        quantity: ingredient.quantity?.toString() ?? '1',
        unit: ingredient.unit ?? 'piece',
        expiryDate: null,
        addedAt: DateTime.now(),
      );
      fridgeBloc.add(AddFridgeItemEvent(item));
    }

    AppSnackBar.showSuccess(
      context,
      '${accepted.length} ingredient${accepted.length > 1 ? 's' : ''} added to fridge! 🎉',
    );

    context.read<ReceiptScanCubit>().reset();
    fridgeBloc.add(const LoadFridgeEvent());
    widget.onIngredientsAdded();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptScanCubit, ReceiptScanState>(
      listener: (context, state) {
        if (state is ReceiptScanError) {
          AppSnackBar.showError(context, state.message);
          context.read<ReceiptScanCubit>().reset();
        } else if (state is ReceiptConfirmationComplete) {
          _handleConfirmationComplete(state);
        }
      },
      builder: (context, state) {
        if (state is ReceiptScanProcessing) {
          return _buildProcessingView(context);
        }
        if (state is ReceiptScanRetrying) {
          return _buildProcessingView(context, isRetrying: true, attempt: state.attempt);
        }
        if (state is ReceiptIngredientConfirmation) {
          return _ReceiptConfirmationView(state: state);
        }
        // Idle state or Complete state (briefly)
        return _buildIdleView(context);
      },
    );
  }

  // ── Idle View ─────────────────────────────────────────────────────────────

  Widget _buildIdleView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ReceiptPickButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  subtitle: 'Snap a receipt',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReceiptPickButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  subtitle: 'Pick an image',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      size: 40, color: AppTheme.primary),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 20),
                Text(
                  'Scan Receipt or List',
                  style: TextStyle(
                    color: AppTheme.textP(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo of your supermarket receipt\nor ingredient list to add items in bulk',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textS(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Feature highlights
                const _FeatureChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI-powered text extraction',
                ),
                const SizedBox(height: 8),
                const _FeatureChip(
                  icon: Icons.merge_type_rounded,
                  label: 'Auto-merges duplicates',
                ),
                const SizedBox(height: 8),
                const _FeatureChip(
                  icon: Icons.fact_check_rounded,
                  label: 'Review items one-by-one',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Processing / Retrying View ────────────────────────────────────────────

  Widget _buildProcessingView(BuildContext context, {bool isRetrying = false, int attempt = 0}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 3,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            isRetrying ? 'AI service is temporarily busy. Retrying...' : 'Reading your receipt…',
            style: TextStyle(
              color: isRetrying ? AppTheme.warning : AppTheme.textP(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRetrying ? 'Attempt $attempt' : 'Extracting ingredients with AI',
            style: TextStyle(
              color: AppTheme.textS(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pick Button ──────────────────────────────────────────────────────────────

class _ReceiptPickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ReceiptPickButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textP(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textS(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Chip ─────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textS(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirmation View (One-by-One) ──────────────────────────────────────────

class _ReceiptConfirmationView extends StatefulWidget {
  final ReceiptIngredientConfirmation state;
  const _ReceiptConfirmationView({required this.state});

  @override
  State<_ReceiptConfirmationView> createState() =>
      _ReceiptConfirmationViewState();
}

class _ReceiptConfirmationViewState extends State<_ReceiptConfirmationView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late String _unit;
  final _units = ['piece', 'g', 'kg', 'ml', 'L', 'cup', 'tbsp', 'tsp'];

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  @override
  void didUpdateWidget(covariant _ReceiptConfirmationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentIngredient != widget.state.currentIngredient) {
      _initFields();
    }
  }

  void _initFields() {
    final ing = widget.state.currentIngredient;
    _nameCtrl = TextEditingController(text: ing.name);

    final q = ing.quantity;
    _qtyCtrl = TextEditingController(
      text: q != null
          ? (q == q.roundToDouble() ? q.round().toString() : q.toString())
          : '',
    );

    _unit = ing.unit ?? 'piece';
    if (!_units.contains(_unit)) {
      _units.add(_unit);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackBar.showError(context, 'Ingredient name cannot be empty');
      return;
    }

    final qtyText = _qtyCtrl.text.trim();
    final qty = qtyText.isNotEmpty ? double.tryParse(qtyText) : null;

    final updated = widget.state.currentIngredient.copyWith(
      name: name,
      quantity: qty ?? widget.state.currentIngredient.quantity,
      unit: _unit,
    );

    context.read<ReceiptScanCubit>().confirmIngredient(updated);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // Wait, the index of the current item being reviewed is total - remaining.
    final reviewedSoFar = state.totalDetected - state.remaining.length - 1;
    final displayIndex = reviewedSoFar + 1;

    return Column(
      children: [
        // Receipt header & progress
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.imagePath),
                  width: 44,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewing Item $displayIndex of ${state.totalDetected}',
                      style: TextStyle(
                        color: AppTheme.textP(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: displayIndex / state.totalDetected,
                        backgroundColor: AppTheme.border(context),
                        color: AppTheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.read<ReceiptScanCubit>().reset(),
                color: AppTheme.textS(context),
                tooltip: 'Cancel Scan',
              ),
            ],
          ),
        ),

        // Review Card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border(context), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ingredient Image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: ApiConstants.ingredientImageUrl(
                            state.currentIngredient.name),
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            const Icon(Icons.restaurant_rounded,
                                size: 50, color: AppTheme.primary),
                      ),
                    ),
                  )
                      .animate(key: ValueKey(state.currentIngredient.name))
                      .scale(
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                          begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 24),

                  // Low Confidence Warning
                  if (state.currentIngredient.isLowConfidence) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 18, color: AppTheme.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Low AI confidence (${(state.currentIngredient.confidence * 100).round()}%)',
                            style: const TextStyle(
                              color: AppTheme.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Editable Fields
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(
                      color: AppTheme.textP(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Ingredient Name',
                      labelStyle: TextStyle(
                        color: AppTheme.textH(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                              color: AppTheme.textP(context), fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            labelStyle: TextStyle(
                                color: AppTheme.textH(context), fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          dropdownColor: AppTheme.card(context),
                          style: TextStyle(
                              color: AppTheme.textP(context), fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(
                                color: AppTheme.textH(context), fontSize: 13),
                          ),
                          items: _units
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _unit = v ?? 'piece'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            border: Border(
              top: BorderSide(color: AppTheme.border(context), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.read<ReceiptScanCubit>().skipIngredient(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.border(context)),
                      foregroundColor: AppTheme.textS(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Add to Fridge'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
