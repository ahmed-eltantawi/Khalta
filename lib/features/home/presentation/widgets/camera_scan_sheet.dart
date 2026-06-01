import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/virtual_fridge/domain/entities/fridge_item_entity.dart';
import '../../../../features/virtual_fridge/presentation/blocs/fridge_bloc.dart';
import '../cubits/camera_cubit.dart';

class CameraScanSheet extends StatefulWidget {
  const CameraScanSheet({super.key});

  @override
  State<CameraScanSheet> createState() => _CameraScanSheetState();
}

class _CameraScanSheetState extends State<CameraScanSheet> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(cameras.first, ResolutionPreset.medium,
          enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _takePicture() async {
    if (!_isCameraInitialized || _controller == null) return;
    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        context.read<CameraCubit>().scanImage(image.path);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to capture image');
    }
  }

  void _pickFromGallery() async {
    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
      if (picked != null && mounted) {
        context.read<CameraCubit>().scanImage(picked.path);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to pick image');
    }
  }

  void _addToFridge(String ingredientName) {
    final item = FridgeItemEntity(
      id: const Uuid().v4(),
      name: ingredientName,
      quantity: '1',
      unit: 'piece',
      expiryDate: null,
      addedAt: DateTime.now(),
    );
    context.read<FridgeBloc>().add(AddFridgeItemEvent(item));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocConsumer<CameraCubit, CameraCubitState>(
        listener: (context, state) {
          if (state is CameraConfirmationComplete) {
            // All ingredients processed — close the sheet and return accepted list
            Navigator.pop(context, state.acceptedIngredients);
          } else if (state is CameraError) {
            AppSnackBar.showError(context, state.message);
            context.read<CameraCubit>().reset();
          }
        },
        builder: (context, state) {
          if (state is CameraScanning) {
            return _buildScanningView(context);
          }
          if (state is CameraIngredientConfirmation) {
            return _buildConfirmationView(context, state, isDark);
          }
          // CameraIdle — show camera viewfinder
          return _buildCameraView(context, isDark);
        },
      ),
    );
  }

  // ── Scanning spinner ──────────────────────────────────────────────────────

  Widget _buildScanningView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text('Analyzing image…',
              style: TextStyle(color: AppTheme.textP(context), fontSize: 16)),
        ],
      ),
    );
  }

  // ── Camera viewfinder ─────────────────────────────────────────────────────

  Widget _buildCameraView(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scan Ingredients',
                  style: TextStyle(
                      color: AppTheme.textP(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppTheme.textP(context)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Camera Preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            ),
            clipBehavior: Clip.hardEdge,
            child: _isCameraInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppTheme.primary, width: 2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary)),
          ),
        ),

        // Bottom Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: AppTheme.textS(context), size: 24),
                ),
              ),

              // Shutter button
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 4),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.primary),
                  ),
                ),
              ),

              // Spacer to balance the layout
              const SizedBox(width: 52, height: 52),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }

  // ── Confirmation view ("I see a potato") ──────────────────────────────────

  Widget _buildConfirmationView(
      BuildContext context, CameraIngredientConfirmation state, bool isDark) {
    return _IngredientConfirmationView(
      state: state,
      isDark: isDark,
      onSkip: () => context.read<CameraCubit>().skipIngredient(),
      onAdd: (finalName) {
        _addToFridge(finalName);
        AppSnackBar.showSuccess(context, '$finalName added to fridge! ✅');
        context.read<CameraCubit>().confirmIngredient(finalName);
      },
      onCancel: () => Navigator.pop(context),
    );
  }
}

class _IngredientConfirmationView extends StatefulWidget {
  final CameraIngredientConfirmation state;
  final bool isDark;
  final VoidCallback onSkip;
  final Function(String) onAdd;
  final VoidCallback onCancel;

  const _IngredientConfirmationView({
    required this.state,
    required this.isDark,
    required this.onSkip,
    required this.onAdd,
    required this.onCancel,
    super.key,
  });

  @override
  State<_IngredientConfirmationView> createState() =>
      _IngredientConfirmationViewState();
}

class _IngredientConfirmationViewState
    extends State<_IngredientConfirmationView> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.state.currentIngredient);
  }

  @override
  void didUpdateWidget(_IngredientConfirmationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentIngredient != widget.state.currentIngredient) {
      _nameController.text = widget.state.currentIngredient;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepNumber = widget.state.accepted.length + 1;
    final isUnknown = widget.state.currentIngredient.isEmpty;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ingredient Detected',
                  style: TextStyle(
                      color: AppTheme.textP(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppTheme.textP(context)),
                onPressed: widget.onCancel,
              ),
            ],
          ),
        ),

        // Progress indicator
        if (widget.state.totalDetected > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Item $stepNumber of ${widget.state.totalDetected}',
                      style: TextStyle(
                          color: AppTheme.textS(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    if (widget.state.accepted.isNotEmpty)
                      Text(
                        '${widget.state.accepted.length} added',
                        style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stepNumber / widget.state.totalDetected,
                    backgroundColor: AppTheme.border(context),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Captured image preview (small)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.file(
            File(widget.state.imagePath),
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 28),

        // Editable name card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border(context), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: widget.isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ingredient image from CDN (if known)
                if (!isUnknown)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      ApiConstants.ingredientImageUrl(
                          widget.state.currentIngredient),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.eco_rounded,
                            size: 32, color: AppTheme.primary),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        size: 32, color: AppTheme.warning),
                  ),
                const SizedBox(height: 12),

                Text(
                  isUnknown ? "We couldn't recognize this item" : 'I see a',
                  style:
                      TextStyle(color: AppTheme.textS(context), fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Editable Text Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textP(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter ingredient name',
                      hintStyle: TextStyle(
                        color: AppTheme.textH(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: widget.isDark
                          ? AppTheme.surfaceDark
                          : AppTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      suffixIcon: Icon(Icons.edit_rounded,
                          color: AppTheme.textH(context), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Should I add it to your fridge?',
                  style:
                      TextStyle(color: AppTheme.textS(context), fontSize: 14),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

        const Spacer(),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(
            children: [
              // Skip button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onSkip,
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textS(context),
                    side: BorderSide(color: AppTheme.border(context)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add to fridge button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      AppSnackBar.showError(
                          context, 'Please enter a name first');
                      return;
                    }
                    widget.onAdd(name);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Yes, add to fridge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }
}
