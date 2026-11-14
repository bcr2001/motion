import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class TimelineCollectionsPage extends StatelessWidget {
  const TimelineCollectionsPage({super.key});

  static String _message(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(State|Argument)Error: '), '');
  }

  Future<void> _create(BuildContext context) async {
    final name = await showCollectionNameDialog(context: context);
    if (name == null || !context.mounted) return;
    try {
      await context.read<GoalTrackerProvider>().createCollection(name);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  Future<void> _rename(
    BuildContext context,
    MotionTimelineCollection collection,
  ) async {
    final name = await showCollectionNameDialog(
      context: context,
      collection: collection,
    );
    if (name == null || !context.mounted) return;
    try {
      await context
          .read<GoalTrackerProvider>()
          .renameCollection(collection, name);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    MotionTimelineCollection collection,
  ) async {
    final provider = context.read<GoalTrackerProvider>();
    final count = provider.entryCountForCollection(collection.id);
    final confirmed = await showGoalConfirmation(
      context: context,
      title: 'Delete Collection?',
      message: count == 0
          ? 'This removes ${collection.name}. No timelines or goals will be affected.'
          : '$count ${count == 1 ? 'entry' : 'entries'} will move to Uncategorized. Nothing will be deleted.',
      actionLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      actionColor: Colors.redAccent,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.deleteCollection(collection);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boundaryColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.10);
    final surfaceColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: Consumer<GoalTrackerProvider>(
        builder: (context, provider, _) {
          if (provider.collections.isEmpty) {
            return const _EmptyCollections();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: provider.collections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final collection = provider.collections[index];
              final count = provider.entryCountForCollection(collection.id);
              return MotionPanel(
                padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
                borderRadius: 8,
                child: Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: AppColor.blueMainColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: AppColor.blueMainColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 13.5,
                              fontweight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count ${count == 1 ? 'entry' : 'entries'}',
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 10.5,
                              fontweight: FontWeight.normal,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Rename ${collection.name}',
                      onPressed: provider.isSaving
                          ? null
                          : () => _rename(context, collection),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    IconButton(
                      tooltip: 'Delete ${collection.name}',
                      onPressed: provider.isSaving
                          ? null
                          : () => _delete(context, collection),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        key: const Key('collectionsBottomAction'),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: boundaryColor)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Consumer<GoalTrackerProvider>(
              builder: (context, provider, _) {
                return FilledButton.icon(
                  onPressed: provider.isSaving ? null : () => _create(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppColor.blueMainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('New Collection'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: AppColor.blueMainColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: AppColor.blueMainColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No collections yet',
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 16,
                fontweight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Create a collection to organize related timelines and goals.',
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
