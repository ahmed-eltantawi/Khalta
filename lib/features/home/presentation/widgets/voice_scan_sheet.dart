import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../cubits/voice_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceScanSheet extends StatefulWidget {
  const VoiceScanSheet({super.key});

  @override
  State<VoiceScanSheet> createState() => _VoiceScanSheetState();
}

class _VoiceScanSheetState extends State<VoiceScanSheet> {
  @override
  void initState() {
    super.initState();
    context.read<VoiceCubit>().startListening();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocConsumer<VoiceCubit, VoiceCubitState>(
        listener: (context, state) {
          if (state is VoiceRecognized) {
            Navigator.pop(context, state.ingredients);
          } else if (state is VoiceError) {
            AppSnackBar.showError(context, state.message);
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Text('Listening...', 
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
               const SizedBox(height: 8),
               const Text('Say ingredients like "chicken and rice"', 
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
               const SizedBox(height: 48),
               
               // Pulsing Mic Icon
               Container(
                 width: 100,
                 height: 100,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: AppTheme.primary.withValues(alpha: 0.2),
                 ),
                 child: const Icon(Icons.mic_rounded, size: 48, color: AppTheme.primary),
               ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
                
               const SizedBox(height: 48),
               TextButton(
                  onPressed: () {
                     context.read<VoiceCubit>().stopListening();
                     Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
               ),
            ],
          );
        },
      ),
    );
  }
}
