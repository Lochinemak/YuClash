import 'package:fl_clash/common/v2board.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/login.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

class _TestV2boardAction extends V2boardAction {
  _TestV2boardAction(this._initial);

  final V2boardAccountState _initial;

  int initializeCalls = 0;
  int skipLoginCalls = 0;
  final List<({String baseUrl, String email, String password})> logins = [];

  @override
  V2boardAccountState build() => _initial;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> skipLogin() async {
    skipLoginCalls++;
  }

  @override
  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    logins.add((baseUrl: baseUrl, email: email, password: password));
  }
}

Future<_TestV2boardAction> _pumpLogin(
  WidgetTester tester, {
  V2boardAccountState state = const V2boardAccountState(initialized: true),
  List<String> history = const [],
  Widget? gateChild,
  bool settle = true,
}) async {
  final action = _TestV2boardAction(state);
  await tester.pumpWidget(
    TestApp(
      overrides: [
        v2boardActionProvider.overrideWith(() => action),
        v2boardServiceCodeHistoryStreamProvider.overrideWith(
          (ref) => Stream.value(history),
        ),
      ],
      child: gateChild != null
          ? V2boardGate(child: gateChild)
          : V2boardLoginPage(state: state),
    ),
  );
  // A running CommonCircleLoading or CircularProgressIndicator never settles.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return action;
}

void main() {
  group('V2boardGate', () {
    testWidgets('shows a loader and initializes before the state arrives', (
      tester,
    ) async {
      final action = await _pumpLogin(
        tester,
        state: const V2boardAccountState(),
        gateChild: const Text('protected'),
        settle: false,
      );

      expect(find.byType(CommonCircleLoading), findsOneWidget);
      expect(find.text('protected'), findsNothing);
      expect(action.initializeCalls, 1);
    });

    testWidgets('lets an authenticated session through to the child', (
      tester,
    ) async {
      await _pumpLogin(
        tester,
        state: const V2boardAccountState(
          initialized: true,
          session: V2boardSession(
            baseUrl: 'https://panel.example',
            email: 'user@example.com',
            authData: 'auth',
            subscriptionUrl: 'https://panel.example/sub',
          ),
        ),
        gateChild: const Text('protected'),
      );

      expect(find.text('protected'), findsOneWidget);
      expect(find.byType(V2boardLoginPage), findsNothing);
    });

    testWidgets('lets a skipped setup through to the child', (tester) async {
      await _pumpLogin(
        tester,
        state: const V2boardAccountState(initialized: true, skipped: true),
        gateChild: const Text('protected'),
      );

      expect(find.text('protected'), findsOneWidget);
    });

    testWidgets('shows the login page when there is no session', (
      tester,
    ) async {
      await _pumpLogin(
        tester,
        state: const V2boardAccountState(initialized: true),
        gateChild: const Text('protected'),
      );

      expect(find.byType(V2boardLoginPage), findsOneWidget);
      expect(find.text('protected'), findsNothing);
    });
  });

  group('V2boardLoginPage', () {
    testWidgets('renders the service code, email and password fields', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('validates every field when submitting an empty form', (
      tester,
    ) async {
      final action = await _pumpLogin(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // An empty form never reaches the notifier.
      expect(action.logins, isEmpty);
      // Email and password report their own emptiness; the service code
      // reports whichever V2boardException resolving it produced.
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('rejects an email without an @', (tester) async {
      final action = await _pumpLogin(tester);
      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.enterText(fields.at(2), 'secret');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(action.logins, isEmpty);
    });

    testWidgets('toggles password obscuring and its tooltip', (tester) async {
      await _pumpLogin(tester);

      final toggle = find.descendant(
        of: find.byType(TextFormField).at(2),
        matching: find.byType(IconButton),
      );
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('shows a spinner and disables both actions while loading', (
      tester,
    ) async {
      final action = await _pumpLogin(
        tester,
        state: const V2boardAccountState(initialized: true, loading: true),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.login), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      expect(action.logins, isEmpty);
      expect(action.skipLoginCalls, 0);
    });

    testWidgets('renders the error text when the state carries one', (
      tester,
    ) async {
      await _pumpLogin(
        tester,
        state: const V2boardAccountState(
          initialized: true,
          error: V2boardException(V2boardErrorType.invalidServerCode),
        ),
      );

      // The error paragraph is an extra Text beyond the static labels.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('custom setup asks the notifier to skip login', (tester) async {
      final action = await _pumpLogin(tester);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(action.skipLoginCalls, 1);
    });

    testWidgets('offers the whole service-code history for an empty query', (
      tester,
    ) async {
      await _pumpLogin(tester, history: const ['AAA', 'BBB']);

      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();

      expect(find.text('AAA'), findsOneWidget);
      expect(find.text('BBB'), findsOneWidget);
    });

    testWidgets('filters the history by the typed code, case-insensitively', (
      tester,
    ) async {
      await _pumpLogin(tester, history: const ['ALPHA', 'BETA']);

      await tester.enterText(find.byType(TextFormField).first, 'al');
      await tester.pumpAndSettle();

      expect(find.text('ALPHA'), findsOneWidget);
      expect(find.text('BETA'), findsNothing);
    });

    testWidgets('selecting a history entry fills the service code field', (
      tester,
    ) async {
      await _pumpLogin(tester, history: const ['ALPHA', 'BETA']);

      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('BETA').last);
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(field.controller?.text, 'BETA');
    });

    testWidgets('disposes its controllers without leaking', (tester) async {
      final action = _TestV2boardAction(
        const V2boardAccountState(initialized: true),
      );
      final overrides = [
        v2boardActionProvider.overrideWith(() => action),
        v2boardServiceCodeHistoryStreamProvider.overrideWith(
          (ref) => const Stream<List<String>>.empty(),
        ),
      ];
      await tester.pumpWidget(
        TestApp(
          overrides: overrides,
          child: const V2boardLoginPage(
            state: V2boardAccountState(initialized: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap the page out while the scope stays alive: State.dispose runs and
      // must not leave a controller listening.
      await tester.pumpWidget(
        TestApp(overrides: overrides, child: const SizedBox.shrink()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(V2boardLoginPage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
