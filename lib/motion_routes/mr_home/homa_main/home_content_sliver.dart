import 'package:flutter/material.dart';

class HomeContentSliver extends StatelessWidget {
  const HomeContentSliver({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        for (final child in children)
          _RetainedHomeSection(key: child.key, child: child),
      ]),
    );
  }
}

// Home has a small, fixed set of sections. Retain their async snapshots and
// inner scroll positions so scrolling back cannot replace them with shimmers.
class _RetainedHomeSection extends StatefulWidget {
  const _RetainedHomeSection({super.key, required this.child});

  final Widget child;

  @override
  State<_RetainedHomeSection> createState() => _RetainedHomeSectionState();
}

class _RetainedHomeSectionState extends State<_RetainedHomeSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
