import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
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
  List<XFile> _recentPhotos = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadRecentPhotos();
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

  Future<void> _loadRecentPhotos() async {
    try {
      // Pick multiple images silently isn't possible, so we show a small
      // prompt strip. The user taps a "Gallery" button to pick.
      // We'll show the last picked image as a thumbnail if available.
    } catch (_) {}
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

  void _pickMultipleFromGallery() async {
    try {
      final picked = await _picker.pickMultiImage(maxWidth: 1024);
      if (picked.isNotEmpty && mounted) {
        // Scan the first selected image
        context.read<CameraCubit>().scanImage(picked.first.path);
        // Store the rest for the thumbnail strip
        setState(() => _recentPhotos = picked);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to load photos');
    }
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
          if (state is CameraIngredientsDetected) {
            if (state.ingredients.isEmpty) {
              AppSnackBar.showInfo(context, 'No ingredients detected. Try again.');
              context.read<CameraCubit>().reset();
            } else {
              Navigator.pop(context, state.ingredients);
            }
          } else if (state is CameraError) {
            AppSnackBar.showError(context, state.message);
            context.read<CameraCubit>().reset();
          }
        },
        builder: (context, state) {
          if (state is CameraScanning) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text('Analyzing image...', style: TextStyle(color: AppTheme.textP(context))),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scan Ingredients',
                        style: TextStyle(color: AppTheme.textP(context), fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppTheme.textP(context)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Camera Preview ──────────────────────────────────
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
                                width: 250, height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.primary, width: 2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
              ),

              // ── Bottom Controls ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Icon(Icons.photo_library_rounded, color: AppTheme.textS(context), size: 24),
                      ),
                    ),

                    // Shutter button
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                        ),
                      ),
                    ),

                    // Multi-select button
                    GestureDetector(
                      onTap: _pickMultipleFromGallery,
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Icon(Icons.burst_mode_rounded, color: AppTheme.textS(context), size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Gallery Thumbnails Strip ────────────────────────
              if (_recentPhotos.isNotEmpty)
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recentPhotos.length,
                    itemBuilder: (ctx, i) {
                      return GestureDetector(
                        onTap: () {
                          // Scan this selected photo
                          context.read<CameraCubit>().scanImage(_recentPhotos[i].path);
                        },
                        child: Container(
                          width: 64, height: 64,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border(context)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(
                            File(_recentPhotos[i].path),
                            fit: BoxFit.cover,
                          ),
                        ).animate(delay: Duration(milliseconds: i * 50))
                            .fadeIn(duration: 200.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      );
                    },
                  ),
                ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          );
        },
      ),
    );
  }
}
