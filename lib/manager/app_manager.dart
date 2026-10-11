import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/permission.dart';
import 'package:fl_clash/common/system_dns.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/v2board/account.dart';
import 'package:fl_clash/widgets/animated_visibility.dart';
import 'package:fl_clash/widgets/icon.dart';
import 'package:fl_clash/widgets/inherited.dart';
import 'package:fl_clash/widgets/pop_scope.dart';
import 'package:fl_clash/widgets/sidebar.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStateManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppStateManager({super.key, required this.child});

  @override
  ConsumerState<AppStateManager> createState() => _AppStateManagerState();
}

class _AppStateManagerState extends ConsumerState<AppStateManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A desktop build started to the tray mounts while hidden, and a paused
    // render never runs a post-frame callback.
    scheduleMicrotask(() {
      if (mounted) {
        _updateVisible(WidgetsBinding.instance.lifecycleState);
      }
    });
    ref.listenManual(configProvider, (prev, next) {
      if (prev != next) {
        ref.read(storeActionProvider.notifier).savePreferencesDebounce();
      }
    });
    ref.listenManual(groupsProvider, (prev, next) {
      if (prev != next) {
        unawaited(precacheTargetIcons(next.map((group) => group.icon)));
      }
    }, fireImmediately: true);
    ref.listenManual(needUpdateGroupsProvider, (prev, next) {
      if (prev != next) {
        ref.read(proxiesActionProvider.notifier).updateGroupsDebounce();
      }
    });
    ref.listenManual(suspendProvider, (prev, next) {
      final isStart = ref.read(isStartProvider);
      if (prev != next && isStart && !ref.read(safeModeProvider)) {
        debouncer.call(FunctionTag.suspend, () async {
          final core = ref.read(coreHandlerProvider);
          if (next == true) {
            await core.stopListener();
          } else {
            await core.startListener();
          }
        });
      }
    });
    final systemDns = systemDnsCoordinator;
    if (systemDns != null) {
      ref.listenManual(shouldPatchSystemDnsProvider, (prev, next) {
        unawaited(systemDns.sync(next));
      }, fireImmediately: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateVisible(AppLifecycleState? state) {
    ref.read(appVisibleProvider.notifier).value = switch (state) {
      null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    commonPrint.log('$state');
    _updateVisible(state);
    if (state == AppLifecycleState.resumed) {
      permissions.check(ref.read);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(routeTrackerProvider.notifier).markResumed();
      });
    }
  }

  @override
  void didChangePlatformBrightness() {
    ref.read(themeActionProvider.notifier).updateBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AppEnvManager extends ConsumerWidget {
  final Widget child;

  const AppEnvManager({super.key, required this.child});

  String? _bannerMessage({required bool safeMode}) {
    if (safeMode) {
      return 'SAFE MODE';
    }
    if (!globalState.isPre) {
      return null;
    }
    return kDebugMode ? 'DEBUG' : globalState.appEnv.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = _bannerMessage(safeMode: ref.watch(safeModeProvider));
    if (message == null) {
      return child;
    }
    return Banner(
      message: message,
      location: BannerLocation.topEnd,
      child: child,
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.items,
    required this.currentIndex,
    required this.viewMode,
    required this.onSelected,
    this.footer,
  });

  final List<NavigationItem> items;
  final int currentIndex;
  final ViewMode viewMode;
  final void Function(int index) onSelected;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canExpand = canExpandSidebar(viewMode);
    final sidebarExpanded = ref.watch(
      appSettingProvider.select((state) => state.sidebarExpanded),
    );
    final version = ref.watch(versionProvider);
    return NavigationSidebar(
      destinations: [
        for (final item in items)
          SidebarDestination(glyph: item.glyph, label: item.label.label),
      ],
      selectedIndex: currentIndex,
      expanded: canExpand && sidebarExpanded,
      onSelected: onSelected,
      onToggle: canExpand
          ? () {
              ref
                  .read(appSettingProvider.notifier)
                  .update(
                    (state) =>
                        state.copyWith(sidebarExpanded: !state.sidebarExpanded),
                  );
            }
          : null,
      windowControls: windowControlsOverSidebar(
        isMacOS: system.isMacOS,
        version: version,
      ),
      footer: footer,
    );
  }
}

class AppSidebarContainer extends ConsumerStatefulWidget {
  final Widget child;

  const AppSidebarContainer({super.key, required this.child});

  @override
  ConsumerState<AppSidebarContainer> createState() =>
      _AppSidebarContainerState();
}

class _AppSidebarContainerState extends ConsumerState<AppSidebarContainer> {
  static const _accountPanelWidth = 320.0;

  final _drawerKey = GlobalKey<ScaffoldState>();
  bool _accountPanelOpen = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(viewModeProvider, (previous, next) {
      if (previous != next && _accountPanelOpen && mounted) {
        _closeAccountPanel();
      }
    });
  }

  Widget _buildBackground({
    required Color color,
    required Color edge,
    required Widget child,
  }) {
    return Material(
      color: color,
      shape: BorderDirectional(end: BorderSide(color: edge)),
      child: child,
    );
  }

  void _updateSideBarWidth(double contentWidth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sideWidthProvider.notifier).value =
          ref.read(viewSizeProvider.select((state) => state.width)) -
          contentWidth;
    });
  }

  void _handleToPage(PageLabel pageLabel) {
    final focusNode = FocusManager.instance.primaryFocus;
    final focusContext = focusNode?.context;
    final preserveNavigationFocus =
        focusContext?.findAncestorWidgetOfExactType<NavigationSidebar>() !=
        null;
    ref.read(currentPageLabelProvider.notifier).toPage(pageLabel);
    if (!preserveNavigationFocus || focusNode == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.context != null && focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _openDrawer() {
    _drawerKey.currentState?.openDrawer();
  }

  void _toggleAccountPanel() {
    setState(() {
      _accountPanelOpen = !_accountPanelOpen;
    });
  }

  void _closeAccountPanel() {
    if (!_accountPanelOpen) {
      return;
    }
    setState(() {
      _accountPanelOpen = false;
    });
  }

  Widget? _buildAccountButton(V2boardSession? session) {
    if (session != null) {
      return IconButton(
        tooltip: context.appLocalizations.account,
        onPressed: _toggleAccountPanel,
        icon: V2boardAccountAvatar(session: session, radius: 14),
      );
    }
    if (ref.watch(v2boardActionProvider.select((state) => state.skipped))) {
      return IconButton(
        tooltip: context.appLocalizations.login,
        onPressed: () => ref.read(v2boardActionProvider.notifier).resetSkip(),
        icon: const GlyphIcon(AppGlyphs.account),
      );
    }
    return null;
  }

  Widget _buildLayout({
    required Widget child,
    required ViewMode viewMode,
    required List<NavigationItem> navigationItems,
    required int currentIndex,
    required V2boardSession? session,
  }) {
    final blur = ref.watch(windowBlurProvider);
    final colorScheme = context.colorScheme;
    final surfaceContainer = colorScheme.surfaceContainer;
    final hasSidebar = viewMode != ViewMode.mobile;
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    final content = Container(
      color: blur ? Colors.transparent : surfaceContainer,
      child: Row(
        children: [
          AnimatedVisibility.sidebar(
            visible: hasSidebar,
            child: _buildBackground(
              color: blur
                  ? surfaceContainer.withValues(alpha: kSidebarBlurOpacity)
                  : surfaceContainer,
              edge: colorScheme.outlineVariant,
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: !isLtr,
                removeRight: isLtr,
                child: _Sidebar(
                  items: navigationItems,
                  currentIndex: currentIndex,
                  viewMode: viewMode,
                  onSelected: (index) {
                    _handleToPage(navigationItems[index].label);
                  },
                  footer: _buildAccountButton(session),
                ),
              ),
            ),
          ),
          if (viewMode == ViewMode.desktop)
            AnimatedSize(
              alignment: Alignment.centerLeft,
              duration: kThemeAnimationDuration,
              curve: Curves.easeOut,
              child: _accountPanelOpen
                  ? SizedBox(
                      width: _accountPanelWidth,
                      child: V2boardAccountPanel(onClose: _closeAccountPanel),
                    )
                  : const SizedBox.shrink(),
            ),
          Expanded(
            flex: 1,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  _updateSideBarWidth(constraints.maxWidth);
                  return MediaQuery.removePadding(
                    context: context,
                    removeLeft: hasSidebar && isLtr,
                    removeRight: hasSidebar && !isLtr,
                    child: child,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
    if (!_accountPanelOpen) {
      return content;
    }
    if (viewMode == ViewMode.desktop) {
      return BackLayerScope(onBack: _closeAccountPanel, child: content);
    }
    if (viewMode != ViewMode.laptop) {
      return content;
    }
    final sidebarWidth = ref.watch(sideWidthProvider);
    final panelWidth = (MediaQuery.sizeOf(context).width - sidebarWidth)
        .clamp(0.0, _accountPanelWidth)
        .toDouble();
    return BackLayerScope(
      onBack: _closeAccountPanel,
      child: Stack(
        children: [
          content,
          PositionedDirectional(
            start: sidebarWidth,
            top: 0,
            bottom: 0,
            end: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeAccountPanel,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: sidebarWidth,
            width: panelWidth,
            child: Material(
              elevation: 3,
              child: V2boardAccountPanel(onClose: _closeAccountPanel),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationStateProvider);
    final viewMode = navigationState.viewMode;
    final isMobileView = viewMode == ViewMode.mobile;
    final session = ref.watch(
      v2boardActionProvider.select((state) => state.session),
    );
    return Scaffold(
      key: _drawerKey,
      drawer: isMobileView
          ? Drawer(
              child: Builder(
                builder: (drawerContext) {
                  return V2boardAccountPanel(
                    onClose: () => Navigator.of(drawerContext).pop(),
                  );
                },
              ),
            )
          : null,
      body: CommonScaffoldDrawerProvider(
        openDrawer: _openDrawer,
        enabled: isMobileView,
        child: _buildLayout(
          child: widget.child,
          viewMode: viewMode,
          navigationItems: navigationState.navigationItems,
          currentIndex: navigationState.currentIndex,
          session: session,
        ),
      ),
    );
  }
}
