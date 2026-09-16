import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error.dart';

Future<void> showV2boardAccountDialog(BuildContext context) async {
  await dialogs.showCommonDialog<void>(
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
          : const V2boardAccountOverviewView(),
    );
  }
}

class V2boardAccountAvatar extends StatelessWidget {
  final V2boardSession session;
  final double radius;

  const V2boardAccountAvatar({
    super.key,
    required this.session,
    this.radius = 22,
  });

  Widget _fallback(BuildContext context) {
    final email = session.accountOverview?.email ?? session.email;
    final initial = email.isEmpty ? '?' : email.characters.first.toUpperCase();
    return ColoredBox(
      color: context.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = session.accountOverview?.avatarUrl ?? '';
    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: avatarUrl.isEmpty
            ? _fallback(context)
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(context),
              ),
      ),
    );
  }
}

class V2boardAccountOverviewView extends ConsumerWidget {
  final EdgeInsetsGeometry padding;

  const V2boardAccountOverviewView({super.key, this.padding = EdgeInsets.zero});

  String _expireText(BuildContext context, int? expire) {
    if (expire == null || expire == 0) {
      return context.appLocalizations.infiniteTime;
    }
    return DateTime.fromMillisecondsSinceEpoch(expire * 1000).show;
  }

  Widget _deviceValue(BuildContext context, int online, int? limit) {
    if (limit != null && limit > 0) {
      return Text('$online / $limit', overflow: TextOverflow.ellipsis);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$online / '),
        const Icon(Icons.all_inclusive),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(v2boardActionProvider);
    final session = state.session;
    if (session == null) {
      return const SizedBox.shrink();
    }
    final overview = session.accountOverview;
    final appLocalizations = context.appLocalizations;
    final used = (overview?.upload ?? 0) + (overview?.download ?? 0);
    final total = overview?.total ?? 0;
    final progress = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              V2boardAccountAvatar(session: session, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview?.email ?? session.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.toSoftBold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Uri.tryParse(session.baseUrl)?.host ?? session.baseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.toLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AccountDetailRow(
            icon: Icons.workspace_premium_outlined,
            label: appLocalizations.subscriptionPlan,
            value: Text(
              overview?.planName ?? appLocalizations.noInfo,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizations.trafficUsage,
            style: context.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 8),
          const SizedBox(height: 8),
          Text(
            '${used.traffic.show} / ${total.traffic.show}',
            style: context.textTheme.bodyMedium?.toLight,
          ),
          const SizedBox(height: 20),
          _AccountDetailRow(
            icon: Icons.event_outlined,
            label: appLocalizations.expiration,
            value: Text(
              _expireText(context, overview?.expire),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          _AccountDetailRow(
            icon: Icons.devices_outlined,
            label: appLocalizations.deviceUsage,
            value: _deviceValue(
              context,
              overview?.onlineDevices ?? 0,
              overview?.deviceLimit,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 20),
            Text(
              v2boardErrorText(context, state.error!),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
          if (state.loading) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class V2boardAccountPanel extends ConsumerWidget {
  final VoidCallback? onClose;

  const V2boardAccountPanel({super.key, this.onClose});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(v2boardActionProvider.notifier).refreshSubscription();
      if (context.mounted) {
        context.showNotifier(context.appLocalizations.subscriptionUpdated);
      }
    } catch (_) {}
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(v2boardActionProvider.notifier).logout();
    if (context.mounted) {
      onClose?.call();
    }
  }

  Future<void> _signIn(WidgetRef ref) async {
    await ref.read(v2boardActionProvider.notifier).resetSkip();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(v2boardActionProvider);
    final appLocalizations = context.appLocalizations;
    final signedIn = state.session != null;
    return Material(
      color: context.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      appLocalizations.account,
                      style: context.textTheme.titleLarge,
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: signedIn
                    ? const V2boardAccountOverviewView()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _signIn(ref),
                            icon: const Icon(Icons.login),
                            label: Text(
                              appLocalizations.login,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (signedIn) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: state.loading
                            ? null
                            : () => _logout(context, ref),
                        icon: const Icon(Icons.logout),
                        label: Text(appLocalizations.logout),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: state.loading
                            ? null
                            : () => _refresh(context, ref),
                        icon: const Icon(Icons.sync),
                        label: Text(appLocalizations.update),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _AccountDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textTheme.labelMedium?.toLight),
              const SizedBox(height: 2),
              DefaultTextStyle.merge(
                style: context.textTheme.bodyLarge,
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: context.colorScheme.onSurface,
                    size: 20,
                  ),
                  child: value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
