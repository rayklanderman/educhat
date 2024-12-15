import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/presence_service.dart';

class TypingIndicator extends ConsumerStatefulWidget {
  final String chatId;
  final Map<String, String> userNames;

  const TypingIndicator({
    super.key,
    required this.chatId,
    required this.userNames,
  });

  @override
  ConsumerState<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends ConsumerState<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final Set<String> _typingUsers = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeOut),
        ),
      );
    });

    _subscribeToTypingStatus();
  }

  void _subscribeToTypingStatus() {
    ref.read(presenceServiceProvider).subscribeToTypingStatus(
      widget.chatId,
      (userId, isTyping) {
        if (mounted) {
          setState(() {
            if (isTyping) {
              _typingUsers.add(userId);
            } else {
              _typingUsers.remove(userId);
            }
          });
        }
      },
    );
  }

  String _getTypingText() {
    if (_typingUsers.isEmpty) return '';

    final names = _typingUsers
        .map((id) => widget.userNames[id] ?? 'Someone')
        .toList();

    if (names.length == 1) {
      return '${names[0]} is typing';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing';
    } else {
      return '${names.length} people are typing';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getTypingText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(width: 8),
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  transform: Matrix4.translation(
                    Vector3(0, -_animations[index].value, 0),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
