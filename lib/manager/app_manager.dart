import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/permission.dart';
import 'package:fl_clash/common/system_dns.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/manager/window_manager.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/v2board/account.dart';
import 'package:fl_clash/widgets/animated_visibility.dart';
import 'package:fl_clash/widgets/inherited.dart';
import 'package:fl_clash/widgets/pop_scope.dart';
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
    ref.listenManual(checkIpProvider, (prev, next) {
      if (prev != next && next.isInit && next.containsDetection) {
        ref.read(networkDetectionProvider.notifier).startCheck();
      }
    });
    ref.listenManual(configProvider, (prev, next) {
      if (prev != next) {
        ref.read(storeActionProvider.notifier).savePreferencesDebounce();
      }
    });
    ref.listenManual(needUpdateGroupsProvider, (prev, next) {
      if (prev != next) {
        ref.read(proxiesActionProvider.notifier).updateGroupsDebounce();
      }
    });
    ref.listenManual(suspendProvider, (prev, next) {
      final isStart = ref.read(isStartProvider);
      if (prev != next && isStart) {
        debouncer.call(FunctionTag.suspend, () async {
          final core = ref.read(coreHandlerProvider);
          if (next == true) {
            await core.stopListener();
          } else {
            await core.startListener();
          }
          ref.read(checkIpNumProvider.notifier).add();
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

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    commonPrint.log('$state');
    if (state == AppLifecycleState.resumed) {
      permissions.check(ref.read);
      render?.resume();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(setupActionProvider.notifier).tryCheckIp();
      });
    }
  }

  @override
  void didChangePlatformBrightness() {
    ref.read(themeActionProvider.notifier).updateBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (_) {
        render?.resume();
      },
      child: widget.child,
    );
  }
}

class AppEnvManager extends StatelessWidget {
  final Widget child;

  const AppEnvManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      if (globalState.isPre) {
        return Banner(
          message: 'DEBUG',
          location: BannerLocation.topEnd,
          child: child,
        );
      }
    }
    if (globalState.isPre) {
      return Banner(
        message: globalState.appEnv.toUpperCase(),
        location: BannerLocation.topEnd,
        child: child,
      );
    }
    return child;
  }
}

class _SidebarRail extends StatelessWidget {
  const _SidebarRail({
    required this.items,
    required this.currentIndex,
    required this.showLabel,
    required this.onSelected,
  });

  final List<NavigationItem> items;
  final int currentIndex;
  final bool showLabel;
  final void Function(int index) onSelected;

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.textTheme.labelLarge!.copyWith(
      color: context.colorScheme.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: NavigationRail(
            scrollable: true,
            minExtendedWidth: 200,
            backgroundColor: Colors.transparent,
            selectedLabelTextStyle: labelStyle,
            unselectedLabelTextStyle: labelStyle,
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: item.icon,
                  label: Text(item.label.label),
                ),
            ],
            onDestinationSelected: onSelected,
            extended: false,
            selectedIndex: currentIndex,
            labelType: showLabel
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.none,
          ),
        ),
      ],
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
  static const _railWidth = 80.0;
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
    required BuildContext context,
    required Widget child,
  }) {
    return Material(color: context.colorScheme.surfaceContainer, child: child);
  }

  void _updateSideBarWidth(WidgetRef ref, double contentWidth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sideWidthProvider.notifier).value =
          ref.read(viewSizeProvider.select((state) => state.width)) -
          contentWidth;
    });
  }

  void _handleToPage(WidgetRef ref, PageLabel pageLabel) {
    final focusNode = FocusManager.instance.primaryFocus;
    final preserveNavigationFocus =
        focusNode?.context?.findAncestorWidgetOfExactType<NavigationRail>() !=
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

  Widget _buildAccountButton(V2boardSession? session) {
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
        icon: const Icon(Icons.login),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildRail({
    required List<NavigationItem> navigationItems,
    required int currentIndex,
    required bool showLabel,
    required V2boardSession? session,
  }) {
    return SizedBox(
      width: _railWidth,
      child: _buildBackground(
        context: context,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (system.isMacOS) const SizedBox(height: 22),
              const SizedBox(height: 10),
              if (!system.isMacOS) ...[
                const ClipRect(child: AppIcon()),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: ScrollConfiguration(
                  behavior: const HiddenBarScrollBehavior(),
                  child: _SidebarRail(
                    items: navigationItems,
                    currentIndex: currentIndex,
                    showLabel: showLabel,
                    onSelected: (index) {
                      _handleToPage(ref, navigationItems[index].label);
                    },
                  ),
                ),
              ),
              _buildAccountButton(session),
              const SizedBox(height: 4),
              IconButton(
                tooltip: context.appLocalizations.toggleLabel,
                onPressed: () {
                  ref
                      .read(appSettingProvider.notifier)
                      .update(
                        (state) => state.copyWith(showLabel: !state.showLabel),
                      );
                },
                icon: Icon(
                  Icons.menu,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(Widget child) {
    return Expanded(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (_, constraints) {
            _updateSideBarWidth(ref, constraints.maxWidth);
            return child;
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout({
    required Widget child,
    required ViewMode viewMode,
    required List<NavigationItem> navigationItems,
    required int currentIndex,
    required bool showLabel,
    required V2boardSession? session,
  }) {
    final content = Container(
      color: context.colorScheme.surfaceContainer,
      child: Row(
        children: [
          AnimatedVisibility.sidebar(
            visible: viewMode != ViewMode.mobile,
            child: _buildRail(
              navigationItems: navigationItems,
              currentIndex: currentIndex,
              showLabel: showLabel,
              session: session,
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
          _buildMainContent(child),
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
    final panelWidth = (MediaQuery.sizeOf(context).width - _railWidth)
        .clamp(0.0, _accountPanelWidth)
        .toDouble();
    return BackLayerScope(
      onBack: _closeAccountPanel,
      child: Stack(
        children: [
          content,
          Positioned.fill(
            left: _railWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeAccountPanel,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: _railWidth,
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
    final navigationItems = navigationState.navigationItems;
    final isMobileView = navigationState.viewMode == ViewMode.mobile;
    final currentIndex = navigationState.currentIndex;
    final showLabel = ref.watch(appSettingProvider).showLabel;
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
        child: _buildDesktopLayout(
          child: widget.child,
          viewMode: navigationState.viewMode,
          navigationItems: navigationItems,
          currentIndex: currentIndex,
          showLabel: showLabel,
          session: session,
        ),
      ),
    );
  }
}
