import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/v2board/account.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile root scaffold opens the account drawer', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(ViewMode.mobile, const Size(412, 915));
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: AppSidebarContainer(
            child: CommonScaffold(title: 'Page', body: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byType(V2boardAccountPanel), findsOneWidget);
    expect(tester.takeException(), null);
  });

  testWidgets('desktop account button expands and closes the detail panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(ViewMode.desktop, const Size(1000, 700));
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: AppSidebarContainer(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final accountButton = find.ancestor(
      of: find.byType(V2boardAccountAvatar),
      matching: find.byType(IconButton),
    );
    await tester.tap(accountButton);
    await tester.pumpAndSettle();

    expect(find.byType(V2boardAccountPanel), findsOneWidget);
    expect(tester.getSize(find.byType(V2boardAccountPanel)).width, 320);

    await tester.tap(accountButton);
    await tester.pumpAndSettle();
    expect(find.byType(V2boardAccountPanel), findsNothing);

    await tester.tap(accountButton);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(V2boardAccountPanel), findsNothing);
    expect(tester.takeException(), null);
  });

  testWidgets('laptop width overlays the account panel without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(680, 580);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(ViewMode.laptop, const Size(680, 580));
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: AppSidebarContainer(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final accountButton = find.ancestor(
      of: find.byType(V2boardAccountAvatar),
      matching: find.byType(IconButton),
    );
    await tester.tap(accountButton);
    await tester.pumpAndSettle();

    expect(find.byType(V2boardAccountPanel), findsOneWidget);
    expect(tester.getSize(find.byType(V2boardAccountPanel)).width, 320);
    expect(tester.takeException(), null);
  });
}

ProviderContainer _container(ViewMode viewMode, Size viewSize) {
  final navigationItem = NavigationItem(
    icon: const Icon(Icons.space_dashboard),
    label: PageLabel.dashboard,
    builder: (_) => const SizedBox.shrink(),
  );
  return ProviderContainer(
    overrides: [
      navigationStateProvider.overrideWithValue(
        NavigationState(
          pageLabel: PageLabel.dashboard,
          navigationItems: [navigationItem],
          viewMode: viewMode,
          locale: 'en',
          currentIndex: 0,
        ),
      ),
      viewSizeProvider.overrideWithBuild((_, _) => viewSize),
      v2boardActionProvider.overrideWithValue(
        V2boardAccountState(session: _session(), initialized: true),
      ),
    ],
  );
}

V2boardSession _session() {
  return const V2boardSession(
    baseUrl: 'https://panel.example/',
    email: 'user@example.com',
    authData: 'session-token',
    subscriptionUrl: 'https://subscribe.example/client?token=abc',
    accountOverview: V2boardAccountOverview(
      email: 'user@example.com',
      avatarUrl: '',
      planName: 'Premium',
      upload: 1024,
      download: 2048,
      total: 8192,
      expire: null,
      onlineDevices: 1,
      deviceLimit: 3,
    ),
  );
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

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
      builder: (context, child) {
        globalState.measure = Measure.of(context, 1);
        globalState.theme = CommonTheme.of(context, 1);
        return child!;
      },
      home: child,
    );
  }
}
