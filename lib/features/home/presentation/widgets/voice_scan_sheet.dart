import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubits/voice_cubit.dart';

class VoiceScanSheet extends StatefulWidget {
  const VoiceScanSheet({super.key});

  @override
  State<VoiceScanSheet> createState() => _VoiceScanSheetState();
}

class _VoiceScanSheetState extends State<VoiceScanSheet> {
  @override
  void initState() {
    super.initState();
    // Delay slightly so the sheet is rendered before requesting mic
    Future.microtask(() {
      if (mounted) context.read<VoiceCubit>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocConsumer<VoiceCubit, VoiceCubitState>(
        listener: (context, state) {
          if (state is VoiceRecognized) {
            // Don't auto-dismiss — let user confirm
          } else if (state is VoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ──────────────────────────────────────────
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title ───────────────────────────────────────────────
                Text(
                  _title(state),
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(state),
                  style: TextStyle(color: subColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ── Mic Animation ───────────────────────────────────────
                if (state is VoiceInitializing ||
                    state is VoiceListening ||
                    state is VoiceIdle)
                  _buildMicSection(state, isDark),

                // ── Live Transcription ──────────────────────────────────
                if (state is VoiceListening && state.partialText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '"${state.partialText}"',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // ── Recognized Results ──────────────────────────────────
                if (state is VoiceRecognized) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.surfaceDark
                          : AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${state.rawText}"',
                      style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.ingredients
                        .map((ing) => Chip(
                              avatar: const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.success, size: 16),
                              label: Text(ing),
                              backgroundColor:
                                  AppTheme.success.withValues(alpha: 0.15),
                              side: BorderSide(
                                  color:
                                      AppTheme.success.withValues(alpha: 0.3)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<VoiceCubit>().reset();
                            context.read<VoiceCubit>().startListening();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pop(context, state.ingredients),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Use These'),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Error state ─────────────────────────────────────────
                if (state is VoiceError) ...[
                  const SizedBox(height: 8),
                  const Icon(Icons.mic_off_rounded,
                      size: 56, color: AppTheme.error),
                  const SizedBox(height: 12),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subColor, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<VoiceCubit>().startListening(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Cancel ──────────────────────────────────────────────
                if (state is! VoiceRecognized)
                  TextButton(
                    onPressed: () {
                      context.read<VoiceCubit>().stopListening();
                      Navigator.pop(context);
                    },
                    child: Text('Cancel', style: TextStyle(color: subColor)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMicSection(VoiceCubitState state, bool isDark) {
    final isListening = state is VoiceListening;
    return GestureDetector(
      onTap: () {
        if (isListening) {
          context.read<VoiceCubit>().stopListening();
        } else {
          context.read<VoiceCubit>().startListening();
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? AppTheme.primary.withValues(alpha: 0.2)
              : (isDark ? AppTheme.surfaceDark : AppTheme.backgroundLight),
          border: Border.all(
            color: isListening ? AppTheme.primary : AppTheme.borderDark,
            width: 2,
          ),
        ),
        child: Icon(
          isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
          size: 48,
          color: isListening ? AppTheme.primary : AppTheme.textHint,
        ),
      )
          .animate(
            onPlay: isListening ? (c) => c.repeat(reverse: true) : null,
          )
          .scale(
            begin: const Offset(1, 1),
            end: isListening ? const Offset(1.15, 1.15) : const Offset(1, 1),
            duration: 800.ms,
          ),
    );
  }

  String _title(VoiceCubitState state) {
    if (state is VoiceInitializing) return 'Starting...';
    if (state is VoiceListening) return '🎤 Listening...';
    if (state is VoiceRecognized) return '✅ Ingredients Found';
    if (state is VoiceError) return 'Oops!';
    return 'Tap to Speak';
  }

  String _subtitle(VoiceCubitState state) {
    if (state is VoiceInitializing) return 'Setting up microphone...';
    if (state is VoiceListening) return 'Say your ingredients clearly';
    if (state is VoiceRecognized) return 'Review and confirm below';
    if (state is VoiceError) return 'Something went wrong';
    return 'Say ingredients like "chicken and rice"';
  }
}
