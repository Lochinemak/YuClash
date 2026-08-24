import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error.dart';

Future<void> showV2boardAccountDialog(BuildContext context) async {
  await globalState.showCommonDialog<void>(
    context: context,
    child: const V2boardAccountDialog(),
  );
}

class V2boardAccountDialog extends ConsumerWidget {
  const V2boardAccountDialog({super.key});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(v2boardActionProvider.notifier).refreshSubscription();
      if (context.mounted) {
        context.showNotifier(context.appLocalizations.subscriptionUpdated);
      }
    } catch (_) {}
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    await ref.read(v2boardActionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(v2boardActionProvider);
    final session = state.session;
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.v2boardAccount,
      actions: [
        TextButton(
          onPressed: state.loading ? null : () => _logout(context, ref),
          child: Text(appLocalizations.logout),
        ),
        FilledButton.icon(
          onPressed: state.loading ? null : () => _refresh(context, ref),
          icon: state.loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(appLocalizations.refreshSubscription),
        ),
      ],
      child: session == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alternate_email),
                  title: Text(appLocalizations.email),
                  subtitle: Text(session.email),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(appLocalizations.serverAddress),
                  subtitle: Text(session.baseUrl),
                ),
                if (state.error != null)
                  Text(
                    v2boardErrorText(context, state.error!),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
              ],
            ),
    );
  }
}
