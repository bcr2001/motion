part of 'manual_tracking.dart';

class _DiscardActivityTimerDialog extends StatelessWidget {
  final ActivityTimerSession session;
  final int elapsedSeconds;

  const _DiscardActivityTimerDialog({
    required this.session,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Discard Timer?',
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 17,
                      fontweight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'The time recorded for ${session.subcategoryName} will not be saved.',
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.normal,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 19,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  formatActivityTimerDuration(elapsedSeconds),
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 16,
                    fontweight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryText,
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishActivityTimerDialog extends StatefulWidget {
  final ActivityTimerSession session;
  final int initialSeconds;
  final bool needsReview;

  const _FinishActivityTimerDialog({
    required this.session,
    required this.initialSeconds,
    required this.needsReview,
  });

  @override
  State<_FinishActivityTimerDialog> createState() =>
      _FinishActivityTimerDialogState();
}

class _FinishActivityTimerDialogState
    extends State<_FinishActivityTimerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
      text: '${widget.initialSeconds ~/ 3600}',
    );
    _minutesController = TextEditingController(
      text: '${(widget.initialSeconds % 3600) ~/ 60}',
    );
    _secondsController = TextEditingController(
      text: '${widget.initialSeconds % 60}',
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final totalSeconds = (int.tryParse(_hoursController.text) ?? 0) * 3600 +
        (int.tryParse(_minutesController.text) ?? 0) * 60 +
        (int.tryParse(_secondsController.text) ?? 0);
    if (totalSeconds <= 0) return;
    Navigator.of(context).pop(totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        36;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: availableHeight.clamp(330.0, 610.0),
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: AppColor.blueMainColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.stop_circle_outlined,
                        color: AppColor.blueMainColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finish Timer',
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 17,
                              fontweight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.session.subcategoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 10.5,
                              fontweight: FontWeight.normal,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: secondaryText),
                    ),
                  ],
                ),
                if (widget.needsReview) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This was a long session. Check the duration before saving.',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 10.5,
                            fontweight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Recorded Duration',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12,
                    fontweight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _TimerDurationField(
                      label: 'Hours',
                      controller: _hoursController,
                      maximum: 999,
                    ),
                    const SizedBox(width: 8),
                    _TimerDurationField(
                      label: 'Minutes',
                      controller: _minutesController,
                      maximum: 59,
                    ),
                    const SizedBox(width: 8),
                    _TimerDurationField(
                      label: 'Seconds',
                      controller: _secondsController,
                      maximum: 59,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.call_split_rounded,
                      size: 17,
                      color: secondaryText,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Sessions crossing midnight are split between the correct dates.',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10.5,
                          fontweight: FontWeight.normal,
                          color: secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondaryText,
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.blueMainColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Time'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerDurationField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maximum;

  const _TimerDurationField({
    required this.label,
    required this.controller,
    required this.maximum,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final fillColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.65);
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.14) : Colors.black12;

    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: AppColor.blueMainColor,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 14,
          fontweight: FontWeight.w800,
          color: textColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyle.subSectionTextStyle(
            fontsize: 10.5,
            fontweight: FontWeight.normal,
            color: isDarkMode ? Colors.white60 : Colors.blueGrey,
          ),
          filled: true,
          fillColor: fillColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: AppColor.blueMainColor,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
          counterText: '',
        ),
        maxLength: maximum > 99 ? 3 : 2,
        validator: (value) {
          final parsed = int.tryParse(value?.trim() ?? '');
          if (parsed == null || parsed < 0 || parsed > maximum) {
            return 'Invalid';
          }
          return null;
        },
      ),
    );
  }
}

class _TrackingMethodSelector extends StatelessWidget {
  final ActivityTimerProvider timer;
  final bool isCurrentActivity;
  final VoidCallback? onTimer;
  final VoidCallback onManual;

  const _TrackingMethodSelector({
    required this.timer,
    required this.isCurrentActivity,
    required this.onTimer,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    final session = timer.session;
    final timerLabel = session == null
        ? 'Start tracking'
        : isCurrentActivity
            ? timer.isRunning
                ? 'Timer running'
                : 'Timer paused'
            : 'Open active timer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: _TrackingMethodTile(
              icon: session == null
                  ? Icons.play_arrow_rounded
                  : isCurrentActivity && !timer.isRunning
                      ? Icons.pause_rounded
                      : Icons.timer_outlined,
              title: 'Timer',
              subtitle: timerLabel,
              accent: AppColor.blueMainColor,
              onTap: timer.isBusy ? null : onTimer,
              isSelected: isCurrentActivity,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TrackingMethodTile(
              icon: Icons.edit_calendar_outlined,
              title: 'Add Manually',
              subtitle: 'Enter a time block',
              accent: Colors.teal,
              onTap: onManual,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final bool isSelected;

  const _TrackingMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor = isSelected
        ? accent.withValues(alpha: 0.65)
        : isDarkMode
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black12;
    final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 88,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: isDarkMode ? 0.12 : 0.08)
                : surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 23),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 13,
                  fontweight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10,
                  fontweight: FontWeight.normal,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTimerPanel extends StatelessWidget {
  final ActivityTimerProvider timer;
  final bool isCurrentActivity;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback onDiscard;
  final VoidCallback onOpenRunningTimer;

  const _ActivityTimerPanel({
    required this.timer,
    required this.isCurrentActivity,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onDiscard,
    required this.onOpenRunningTimer,
  });

  @override
  Widget build(BuildContext context) {
    final session = timer.session;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    if (session == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: isCurrentActivity
          ? _currentTimer(context, session)
          : _otherTimer(context, session),
    );
  }

  Widget _otherTimer(
    BuildContext context,
    ActivityTimerSession session,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _timerIcon(Icons.lock_clock_outlined, Colors.orange),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subcategoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 13,
                      fontweight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Another activity is already being timed',
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.normal,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatActivityTimerDuration(timer.elapsedSeconds),
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 13,
                fontweight: FontWeight.w900,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        OutlinedButton.icon(
          onPressed: onOpenRunningTimer,
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const Text('Open Running Timer'),
        ),
      ],
    );
  }

  Widget _currentTimer(
    BuildContext context,
    ActivityTimerSession session,
  ) {
    final warning = timer.needsReview || timer.isReminderDue;
    final accent = warning ? Colors.orange : AppColor.blueMainColor;
    return Column(
      children: [
        Row(
          children: [
            _timerIcon(
              timer.isRunning ? Icons.timer_outlined : Icons.pause_rounded,
              accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                timer.isRunning ? 'Tracking Now' : 'Timer Paused',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 13,
                  fontweight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
            if (timer.isBusy)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          formatActivityTimerDuration(timer.elapsedSeconds),
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 34,
            fontweight: FontWeight.w900,
            color: accent,
          ),
        ),
        if (warning) ...[
          const SizedBox(height: 7),
          Text(
            timer.needsReview
                ? 'Long session - review the duration before saving'
                : 'Still tracking? Review or continue this timer',
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 10.5,
              fontweight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
        ],
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: timer.isBusy
                    ? null
                    : timer.isRunning
                        ? onPause
                        : onResume,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: Icon(
                  timer.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(timer.isRunning ? 'Pause' : 'Resume'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: timer.isBusy ? null : onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.blueMainColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColor.blueMainColor.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Finish'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        TextButton.icon(
          onPressed: timer.isBusy ? null : onDiscard,
          icon: const Icon(Icons.delete_outline_rounded, size: 17),
          label: const Text('Discard Timer'),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _timerIcon(IconData icon, Color color) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

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
