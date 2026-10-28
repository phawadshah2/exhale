import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Sees the page the shell sits on, so it can tell when a pushed page
/// (Logs, Edit plan) is closed and the shell comes back into view.
final RouteObserver<ModalRoute<void>> shellRouteObserver = _PageRouteObserver();

/// Reports only pages closing. Sheets, dialogs and menus close over the
/// shell without it ever leaving view, so they replay nothing.
class _PageRouteObserver extends RouteObserver<ModalRoute<void>> {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) super.didPop(route, previousRoute);
  }
}

/// Counts how often a shell tab came into view again after it was left. A
/// page that keys its content by this count replays its entrance animations
/// each time, as if opened fresh.
final NotifierProviderFamily<PageVisit, int, int> pageVisitProvider =
    NotifierProvider.family<PageVisit, int, int>(PageVisit.new);

class PageVisit extends Notifier<int> {
  PageVisit(this.tab);

  final int tab;

  @override
  int build() => 0;

  void bump() => state++;
}

/// Rebuilds [child] from scratch every time shell tab [tab] is visited
/// again, so its entrance animations play like the first time. Wrap any
/// tab's page content in it.
class ReplayOnVisit extends ConsumerWidget {
  const ReplayOnVisit({required this.tab, required this.child, super.key});

  final int tab;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KeyedSubtree(
    key: ValueKey(ref.watch(pageVisitProvider(tab))),
    child: child,
  );
}

/// Calls [onReturn] when a page pushed over the shell is closed.
class ShellReturnListener extends StatefulWidget {
  const ShellReturnListener({
    required this.onReturn,
    required this.child,
    super.key,
  });

  final VoidCallback onReturn;
  final Widget child;

  @override
  State<ShellReturnListener> createState() => _ShellReturnListenerState();
}

class _ShellReturnListenerState extends State<ShellReturnListener>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) shellRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => widget.onReturn();

  @override
  void dispose() {
    shellRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
