// lib/presentation/screens/focus_mode_screen.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/todo.dart';
import '../../routing/app_router.dart';
import '../notifiers/todo_list_notifier.dart';

class FocusModeScreen extends ConsumerStatefulWidget {
  final Todo todo;
  const FocusModeScreen({super.key, required this.todo});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  final CountDownController _countDownController = CountDownController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _quotes = ["The secret of getting ahead is getting started.", "Well done is better than well said.", "Focus on being productive instead of busy."];
  int _quoteIndex = 0;
  late Timer _quoteTimer;
  // NEW: State to track if the timer is playing
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _quoteTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() => _quoteIndex = (_quoteIndex + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    _quoteTimer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // In class _FocusModeScreenState

    Future<void> _finishSession({bool markAsComplete = true}) async {
    if (!mounted) return;

    if (markAsComplete) {
      _audioPlayer.play(AssetSource('sounds/success.mp3'));
      
      // THE FIX: Call the notifier directly.
      await ref.read(todoListProvider.notifier).toggle(widget.todo.id);
    }
    
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }
  
  void _togglePlayPause() {
    if (_isPlaying) {
      _countDownController.pause();
    } else {
      _countDownController.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int durationInSeconds = widget.todo.durationMinutes * 60;

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          tooltip: 'End session without completing',
          onPressed: () => context.go(AppRoutes.home),
        ),
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(widget.todo.title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
              const Spacer(),
              CircularCountDownTimer(
                duration: durationInSeconds,
                controller: _countDownController,
                width: MediaQuery.of(context).size.width / 1.5,
                height: MediaQuery.of(context).size.width / 1.5,
                ringColor: Colors.white.withOpacity(0.3),
                fillColor: theme.colorScheme.secondary,
                strokeWidth: 20.0,
                strokeCap: StrokeCap.round,
                textStyle: theme.textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                textFormat: CountdownTextFormat.MM_SS,
                isReverse: true, // This makes numbers count 25:00 -> 00:00. Correct.
                
                // THE FIX: This makes the ring DRAIN instead of FILL.
                isReverseAnimation: false, 
                
                isTimerTextShown: true,
                autoStart: true,
                onComplete: () => _finishSession(),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // THE NEW TOGGLE BUTTON
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 48),
                    onPressed: _togglePlayPause,
                  ),
                  // "Finish Early" button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Finish Now"),
                    onPressed: () => _finishSession(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(_quotes[_quoteIndex], key: ValueKey<int>(_quoteIndex), textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.8), fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}