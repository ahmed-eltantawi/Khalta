import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
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
      AppSnackBar.showError(context, 'Failed to capture image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            return const Center(
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     CircularProgressIndicator(color: AppTheme.primary),
                     SizedBox(height: 16),
                     Text('Analyzing image...', style: TextStyle(color: AppTheme.textPrimary)),
                  ],
               ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scan Ingredients', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppTheme.surfaceDark,
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
                      : const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
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
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
