import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';
import 'avatar_stack.dart';
import 'poll_option_tile.dart';

class PollCard extends StatelessWidget {
  final Poll poll;
  final String? selectedOptionId;
  final bool hasVoted;
  final VoidCallback? onVote;
  final ValueChanged<String>? onOptionTap;
  final VoidCallback? onClosePoll;
  final VoidCallback? onTap;

  const PollCard({
    super.key,
    required this.poll,
    this.selectedOptionId,
    this.hasVoted = false,
    this.onVote,
    this.onOptionTap,
    this.onClosePoll,
    this.onTap,
  });

  String _formatDeadline(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    Widget cardUI = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              poll: poll,
              formatDeadline: _formatDeadline,
              onClosePoll: onClosePoll,
            ),
            const SizedBox(height: 14),
            Text(
              poll.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            ...poll.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PollOptionTile(
                  option: option,
                  totalVotes: poll.totalVotes,
                  isSelected: selectedOptionId == option.id,
                  showResults: hasVoted || !poll.isActive,
                  isEnabled: poll.isActive && !hasVoted,
                  onTap: onOptionTap != null
                      ? () => onOptionTap!(option.id)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FooterRow(
              poll: poll,
              hasVoted: hasVoted,
              canVote: selectedOptionId != null && !hasVoted && poll.isActive,
              onVote: onVote,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: cardUI,
        ),
      );
    }
    return cardUI;
  }
}

class _HeaderRow extends StatelessWidget {
  final Poll poll;
  final String Function(DateTime) formatDeadline;
  final VoidCallback? onClosePoll;
  const _HeaderRow({
    required this.poll,
    required this.formatDeadline,
    this.onClosePoll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(poll.categoryEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                poll.category,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (poll.deadline != null && poll.isActive)
          _DeadlineBadge(label: formatDeadline(poll.deadline!), isClosed: false)
        else if (!poll.isActive)
          const _DeadlineBadge(label: 'Closed', isClosed: true),
        const SizedBox(width: 4),
        PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          splashRadius: 18,
          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.muted),
          onSelected: (value) {
            if (value == 0) onClosePoll?.call();
          },
          itemBuilder: (_) => [
            if (poll.isActive)
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Close Poll'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Share'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  final String label;
  final bool isClosed;
  const _DeadlineBadge({required this.label, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isClosed ? AppColors.sand : AppColors.paleSunset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClosed ? Icons.lock_clock : Icons.schedule,
            size: 13,
            color: isClosed ? AppColors.muted : AppColors.sunset,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isClosed ? AppColors.muted : AppColors.sunset,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  final Poll poll;
  final bool hasVoted;
  final bool canVote;
  final VoidCallback? onVote;
  const _FooterRow({
    required this.poll,
    required this.hasVoted,
    required this.canVote,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarStack(initials: poll.voterInitials),
        const SizedBox(width: 10),
        Text(
          '${poll.totalVotes}/${poll.totalMembers} voted',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const Spacer(),
        if (canVote)
          FilledButton.tonal(
            onPressed: onVote,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Vote',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else if (hasVoted)
          _StatusPill(
            icon: Icons.check_circle,
            label: 'Voted',
            color: AppColors.forest,
            bgColor: AppColors.paleMint,
          )
        else if (!poll.isActive)
          const _StatusPill(
            icon: Icons.emoji_events_outlined,
            label: 'Ended',
            color: AppColors.muted,
            bgColor: AppColors.sand,
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
