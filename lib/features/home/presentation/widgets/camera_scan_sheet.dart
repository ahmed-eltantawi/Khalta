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
      _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
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
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
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
                            border: Border.all(color: AppTheme.primary, width: 2),
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
    final stepNumber = state.accepted.length + 1;

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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Progress indicator
        if (state.totalDetected > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Item $stepNumber of ${state.totalDetected}',
                      style: TextStyle(
                          color: AppTheme.textS(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    if (state.accepted.isNotEmpty)
                      Text(
                        '${state.accepted.length} added',
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
                    value: stepNumber / state.totalDetected,
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
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.file(
            File(state.imagePath),
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 28),

        // "I see a potato" message
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
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ingredient image from CDN
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiConstants.ingredientImageUrl(state.currentIngredient),
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
                ),
                const SizedBox(height: 12),
                Text(
                  'I see a',
                  style: TextStyle(
                      color: AppTheme.textS(context), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  state.currentIngredient.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.textP(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Should I add it to your fridge?',
                  style: TextStyle(
                      color: AppTheme.textS(context), fontSize: 14),
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
                  onPressed: () {
                    context.read<CameraCubit>().skipIngredient();
                  },
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
                    _addToFridge(state.currentIngredient);
                    AppSnackBar.showSuccess(context,
                        '${state.currentIngredient} added to fridge! ✅');
                    context.read<CameraCubit>().confirmIngredient();
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
