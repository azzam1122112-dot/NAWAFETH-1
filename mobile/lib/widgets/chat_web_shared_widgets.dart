import 'package:flutter/material.dart';

class ChatFilterChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ChatFilterChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class ChatMiniStatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const ChatMiniStatPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatConnectionPill extends StatelessWidget {
  final bool live;
  final bool typing;

  const ChatConnectionPill({
    super.key,
    required this.live,
    this.typing = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = typing
        ? Colors.blue
        : (live ? Colors.green : Colors.orange);
    final label = typing ? 'يكتب الآن...' : (live ? 'مباشر' : 'مزامنة');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color.shade700,
        ),
      ),
    );
  }
}

class ChatReadReceiptIcon extends StatelessWidget {
  final bool readByPeer;
  final Color color;

  const ChatReadReceiptIcon({
    super.key,
    required this.readByPeer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      readByPeer ? Icons.done_all_rounded : Icons.done_rounded,
      size: 14,
      color: readByPeer ? Colors.lightBlueAccent : color,
    );
  }
}

class ChatConversationTitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const ChatConversationTitleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: titleStyle ??
              const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle ??
              const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class ChatMessageMetaRow extends StatelessWidget {
  final String timeText;
  final bool isMine;
  final bool readByPeer;
  final Color mineColor;
  final Color otherColor;

  const ChatMessageMetaRow({
    super.key,
    required this.timeText,
    required this.isMine,
    required this.readByPeer,
    this.mineColor = Colors.white70,
    this.otherColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    final timeColor = isMine ? mineColor : otherColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeText,
          style: TextStyle(
            fontSize: 11,
            color: timeColor,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 6),
          ChatReadReceiptIcon(
            readByPeer: readByPeer,
            color: mineColor,
          ),
        ],
      ],
    );
  }
}
