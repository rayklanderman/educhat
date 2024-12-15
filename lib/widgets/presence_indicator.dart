import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/presence_service.dart';

class PresenceIndicator extends ConsumerStatefulWidget {
  final String userId;
  final double size;
  final bool showLabel;

  const PresenceIndicator({
    super.key,
    required this.userId,
    this.size = 10,
    this.showLabel = false,
  });

  @override
  ConsumerState<PresenceIndicator> createState() => _PresenceIndicatorState();
}

class _PresenceIndicatorState extends ConsumerState<PresenceIndicator> {
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _subscribeToPresence();
  }

  void _subscribeToPresence() {
    ref.read(presenceServiceProvider).subscribeToPresence(
      widget.userId,
      (isOnline, lastSeen) {
        if (mounted) {
          setState(() {
            _isOnline = isOnline;
            _lastSeen = lastSeen;
          });
        }
      },
    );
  }

  String _formatLastSeen() {
    if (_lastSeen == null) return '';

    final now = DateTime.now();
    final difference = now.difference(_lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _lastSeen!.toString().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isOnline ? Colors.green : Colors.grey,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 2,
            ),
          ),
        ),
        if (widget.showLabel && _lastSeen != null) ...[
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : _formatLastSeen(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
