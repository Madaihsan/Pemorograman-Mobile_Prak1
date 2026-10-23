import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'view_model.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final QuizViewModel viewModel = QuizViewModel(
    onGameOver: _handleGameOver,
  );

  VoidCallback? _showGameOverScreen;
  int? _selectedAnswerIndex;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(
                onPressed:
                    viewModel.hasNextQuestion && viewModel.didAnswerQuestion
                    ? () {
                        setState(() {
                          _selectedAnswerIndex = null;
                        });
                        viewModel.getNextQuestion();
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
          body: Center(
            child: Column(
              children: [
                OpenContainer(
                  tappable: false,
                  closedElevation: 0,
                  closedColor: Colors.transparent,
                  transitionDuration: const Duration(milliseconds: 700),
                  openBuilder: (context, closeContainer) {
                    return GameOverScreen(viewModel: viewModel);
                  },
                  closedBuilder: (context, openContainer) {
                    _showGameOverScreen = openContainer;
                    return QuestionCard(question: viewModel.currentQuestion?.question);
                  },
                ),
                const Spacer(),
                AnswerCards(
                  onTapped: (index) {
                    setState(() {
                      _selectedAnswerIndex = index;
                    });
                    viewModel.checkAnswer(index);
                  },
                  selectedAnswer: _selectedAnswerIndex,
                  answers: viewModel.currentQuestion?.possibleAnswers ?? [],
                  correctAnswer: viewModel.didAnswerQuestion
                      ? viewModel.currentQuestion?.correctAnswer
                      : null,
                ),
                StatusBar(viewModel: viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleGameOver() {
    _showGameOverScreen?.call();
  }
}

class QuestionCard extends StatelessWidget {
  final String? question;

  const QuestionCard({required this.question, super.key});

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
      child: Card(
        key: ValueKey(question),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            question ?? '',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ),
    );
  }
}


class AnswerCards extends StatelessWidget {
  final List<String> answers;
  final ValueChanged<int> onTapped;
  final int? correctAnswer;
  final int? selectedAnswer;

  const AnswerCards({
    required this.answers,
    required this.onTapped,
    required this.correctAnswer,
    this.selectedAnswer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 5 / 2,
      children: List.generate(answers.length, (index) {
        var color = Theme.of(context).colorScheme.primaryContainer;
        Widget? trailingIcon;
        final isWrong = selectedAnswer == index &&
            correctAnswer != null &&
            correctAnswer != index;

        if (correctAnswer == index) {
          color = Theme.of(context).colorScheme.tertiaryContainer;
          trailingIcon = const Icon(Icons.check_circle, color: Colors.teal, size: 20);
        } else if (isWrong) {
          color = Theme.of(context).colorScheme.errorContainer;
          trailingIcon = Icon(Icons.cancel, color: Theme.of(context).colorScheme.error, size: 20);
        }

        return CardFlipEffect(
          delayAmount: index.toDouble() / 2,
          child: ShakeEffect(
            shake: isWrong,
            child: Card.filled(
              key: ValueKey(answers[index]),
              color: color,
              elevation: 2,
              margin: const EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: correctAnswer == null ? () => onTapped(index) : null,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          answers.length > index ? answers[index] : '',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 6),
                        trailingIcon,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class StatusBar extends StatelessWidget {
  final QuizViewModel viewModel;

  const StatusBar({required this.viewModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Question ${viewModel.answeredQuestionCount} / ${viewModel.totalQuestions}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: List.generate(
                viewModel.totalQuestions,
                (index) => AnimatedScoreIcon(
                  isActive: index < viewModel.score,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class AnimatedScoreIcon extends StatelessWidget {
  final bool isActive;
  final Duration _duration = const Duration(milliseconds: 1000);
  final Curve _curve = Curves.elasticOut;

  const AnimatedScoreIcon({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.5,
      curve: _curve,
      duration: _duration,
      child: TweenAnimationBuilder<Color?>(
        curve: _curve,
        duration: _duration,
        tween: ColorTween(
          begin: Colors.grey.shade400,
          // warna teal saat aktif, abu-abu saat belum aktif
          end: isActive ? Colors.teal : Colors.grey.shade400,
        ),
        builder: (context, color, child) {
          // munculkan ikon piala (Icons.emoji_events)
          return Icon(Icons.emoji_events, size: 40, color: color);
        },
      ),
    );
  }
}

class CardFlipEffect extends StatefulWidget {
  final Widget child;
  final double delayAmount;

  const CardFlipEffect({
    super.key,
    required this.child,
    required this.delayAmount,
  });

  @override
  State<CardFlipEffect> createState() => _CardFlipEffectState();
}

class _CardFlipEffectState extends State<CardFlipEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late Animation<double> _animationWithDelay;
  Widget? _previousChild;

  @override
  void initState() {
    super.initState();
    // Menyesuaikan total durasi dengan delay agar kecepatan putar setiap kartu seragam
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (350 * (widget.delayAmount + 1)).round(),
      ),
    );

    // KUNCI PERBAIKAN: Ketika animasi selesai berputar (180 derajat),
    // reset controller ke 0 agar rotasi kembali tegak (0 derajat) dan teks tidak terbalik.
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });

    _setupAnimation();
  }

  void _setupAnimation() {
    _animationWithDelay = TweenSequence<double>([
      if (widget.delayAmount > 0)
        TweenSequenceItem(
          tween: ConstantTween<double>(0.0),
          weight: widget.delayAmount,
        ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(_animationController);
  }

  @override
  void didUpdateWidget(covariant CardFlipEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _previousChild = oldWidget.child;
      _setupAnimation();
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateX(_animationWithDelay.value * math.pi),
          child: _animationController.isAnimating
              ? _animationWithDelay.value < 0.5
                  ? _previousChild
                  : Transform.flip(flipY: true, child: widget.child)
              : widget.child,
        );
      },
    );
  }
}

class GameOverScreen extends StatelessWidget {
  final QuizViewModel viewModel;

  const GameOverScreen({required this.viewModel, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassed = viewModel.score >= (viewModel.totalQuestions / 2);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPassed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 100,
                  color: isPassed ? Colors.amber.shade700 : theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Kuis Selesai!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skor Akhir Anda',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${viewModel.score} / ${viewModel.totalQuestions}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Main Lagi'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShakeEffect extends StatefulWidget {
  final Widget child;
  final bool shake;

  const ShakeEffect({
    super.key,
    required this.child,
    required this.shake,
  });

  @override
  State<ShakeEffect> createState() => _ShakeEffectState();
}

class _ShakeEffectState extends State<ShakeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant ShakeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnimation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
