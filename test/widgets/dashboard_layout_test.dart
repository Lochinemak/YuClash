import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/dashboard.dart';
import 'package:fl_clash/views/dashboard/compact_dashboard.dart';
import 'package:fl_clash/widgets/grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

void main() {
  testWidgets('dashboard limits a wide grid to 16 centered columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        appSettingProvider.overrideWithBuild(
          (_, _) =>
              const AppSettingProps(dashboardLayout: DashboardLayout.classic),
        ),
        dashboardStateProvider.overrideWithValue(
          const DashboardState(dashboardWidgets: []),
        ),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: DashboardView()),
      ),
    );
    await tester.pump();

    final grid = find.byType(Grid);
    expect(tester.widget<Grid>(grid).crossAxisCount, 16);
    expect(tester.getSize(grid).width, 1120);
    expect(tester.getTopLeft(grid).dx, 240);
    expect(tester.takeException(), null);
  });

  testWidgets('compact dashboard is the default and switches to classic', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: _compactOverrides());
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(child: DashboardView()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('compact-running-switch')),
      findsOneWidget,
    );
    expect(find.byType(Grid), findsNothing);

    await tester.tap(find.byKey(const ValueKey('classic-dashboard-icon')));
    await tester.pumpAndSettle();

    expect(
      container.read(appSettingProvider).dashboardLayout,
      DashboardLayout.classic,
    );
    expect(find.byType(Grid), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compact-dashboard-icon')),
      findsOneWidget,
    );
  });

  testWidgets('mobile compact layout hides desktop network controls', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: _compactOverrides());
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: CompactDashboard(showDesktopNetworkOptions: false),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('compact-system-proxy-switch')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('compact-tun-switch')), findsNothing);
  });

  testWidgets('compact layout fits a dark Chinese mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: _compactOverrides());
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          locale: Locale('zh', 'CN'),
          themeMode: ThemeMode.dark,
          child: CompactDashboard(showDesktopNetworkOptions: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('出站模式'), findsOneWidget);
    expect(tester.takeException(), null);
  });

  testWidgets('desktop network and mode controls update their providers', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: _compactOverrides());
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: CompactDashboard(showDesktopNetworkOptions: true),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('compact-system-proxy-switch')));
    await tester.pump();
    expect(container.read(networkSettingProvider).systemProxy, false);

    await tester.tap(find.byKey(const ValueKey('compact-tun-switch')));
    await tester.pump();
    expect(container.read(patchClashConfigProvider).tun.enable, true);

    await tester.tap(find.text('Global'));
    await tester.pump();
    expect(container.read(patchClashConfigProvider).mode, Mode.global);
  });

  testWidgets('node selector updates the current profile selection', (
    tester,
  ) async {
    final profile = Profile.normal(
      label: 'Profile',
    ).copyWith(currentGroupName: 'Proxy', selectedMap: {'Proxy': 'Node A'});
    const group = Group(
      type: GroupType.Selector,
      name: 'Proxy',
      now: 'Node A',
      all: [
        Proxy(name: 'Node A', type: 'Shadowsocks'),
        Proxy(name: 'Node B', type: 'WireGuard'),
      ],
    );
    late _RecordingProxiesAction proxiesAction;
    final container = ProviderContainer(
      overrides: [
        ..._compactOverrides(profiles: [profile], groups: [group]),
        currentProfileIdProvider.overrideWithBuild((_, _) => profile.id),
        groupsProvider.overrideWithValue([group]),
        proxiesActionProvider.overrideWith(() {
          proxiesAction = _RecordingProxiesAction();
          return proxiesAction;
        }),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: CompactDashboard(showDesktopNetworkOptions: false),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('compact-proxy-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Node B', findRichText: true));
    await tester.pumpAndSettle();

    expect(proxiesAction.changedGroup, 'Proxy');
    expect(proxiesAction.changedProxy, 'Node B');
    expect(
      container.read(profilesProvider).first.selectedMap['Proxy'],
      'Node B',
    );
  });
}

List<Override> _compactOverrides({
  List<Profile> profiles = const [],
  List<Group> groups = const [],
}) {
  return [
    dashboardStateProvider.overrideWithValue(
      const DashboardState(dashboardWidgets: []),
    ),
    profilesProvider.overrideWith(() => _TestProfiles(profiles)),
    isStartProvider.overrideWithValue(false),
    runTimeProvider.overrideWithBuild((_, _) => null),
    suspendProvider.overrideWithValue(false),
    currentGroupsStateProvider.overrideWithValue(GroupsState(value: groups)),
  ];
}

class _TestApp extends StatelessWidget {
  final Widget child;
  final Locale? locale;
  final ThemeMode themeMode;

  const _TestApp({
    required this.child,
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalState.navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) {
        globalState.measure = Measure.of(context, 1);
        globalState.theme = CommonTheme.of(context, 1);
        return child!;
      },
      home: child,
    );
  }
}

class _TestProfiles extends Profiles {
  final List<Profile> initial;

  _TestProfiles([this.initial = const []]);

  @override
  List<Profile> build() => initial;
}

class _RecordingProxiesAction extends ProxiesAction {
  String? changedGroup;
  String? changedProxy;

  @override
  void changeProxyDebounce(String groupName, String proxyName) {
    changedGroup = groupName;
    changedProxy = proxyName;
  }
}
