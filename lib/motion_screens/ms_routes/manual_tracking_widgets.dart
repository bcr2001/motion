part of 'manual_tracking.dart';

class _ManualTrackingTimeDialogActions extends StatelessWidget {
  const _ManualTrackingTimeDialogActions({
    required this.onCancel,
    required this.onAdd,
    required this.isBusy,
  });

  final VoidCallback onCancel;
  final VoidCallback onAdd;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.16) : Colors.black12;
    final cancelTextColor = isDarkMode ? Colors.white70 : Colors.blueGrey;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: cancelTextColor,
              minimumSize: const Size(0, 42),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppString.trackCancelTextButton,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.w700,
                color: cancelTextColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isBusy ? null : onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.blueMainColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppString.trackAddTextButton,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _TrackedBlocksHeader extends StatelessWidget {
  const _TrackedBlocksHeader({
    required this.title,
    required this.emptyLabel,
    required this.blockCount,
    required this.totalMinutes,
    required this.icon,
    this.accentColor = AppColor.blueMainColor,
  });

  final String title;
  final String emptyLabel;
  final int blockCount;
  final double totalMinutes;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final convertedTotal = convertMinutesToTime(totalMinutes);

    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 15,
                  fontweight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                blockCount == 0
                    ? emptyLabel
                    : "$blockCount ${blockCount == 1 ? "block" : "blocks"} | $convertedTotal",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackedBlockTile extends StatelessWidget {
  const _TrackedBlockTile({
    required this.index,
    required this.convertedTimeRecorded,
    required this.onDelete,
    required this.isDeleting,
    this.subtitle,
  });

  final int index;
  final String convertedTimeRecorded;
  final String? subtitle;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final tileColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.025);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11,
                  fontweight: FontWeight.w800,
                  color: AppColor.blueMainColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convertedTimeRecorded,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 15,
                    fontweight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.normal,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: isDeleting ? null : onDelete,
            visualDensity: VisualDensity.compact,
            icon: isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
          ),
        ],
      ),
    );
  }
}
