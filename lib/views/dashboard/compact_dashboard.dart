import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CompactDashboard extends ConsumerWidget {
  final bool? showDesktopNetworkOptions;

  const CompactDashboard({super.key, this.showDesktopNetworkOptions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ConnectionPanel(),
              const SizedBox(height: 14),
              const _ProxyPanel(),
              if (showDesktopNetworkOptions ?? system.isDesktop) ...[
                const SizedBox(height: 14),
                const _DesktopNetworkPanel(),
              ],
              const SizedBox(height: 14),
              const _ModePanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionPanel extends ConsumerWidget {
  const _ConnectionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStart = ref.watch(isStartProvider);
    final runTime = ref.watch(runTimeProvider);
    final suspend = ref.watch(suspendProvider);
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );
    final appLocalizations = context.appLocalizations;
    final status = suspend
        ? appLocalizations.suspended
        : isStart
        ? appLocalizations.connected
        : appLocalizations.disconnected;
    return _DashboardPanel(
      child: Row(
        children: [
          _PanelIcon(
            icon: isStart ? Icons.power : Icons.power_off,
            active: isStart,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizations.connection,
                  style: context.textTheme.titleMedium?.toSoftBold,
                ),
                const SizedBox(height: 4),
                Text(
                  isStart && !suspend
                      ? '$status · ${utils.getTimeText(runTime)}'
                      : status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.toLight,
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('compact-running-switch'),
            value: isStart,
            onChanged: hasProfile
                ? (_) => ref.read(commonActionProvider.notifier).toggleRunning()
                : null,
          ),
        ],
      ),
    );
  }
}

class _ProxyPanel extends ConsumerWidget {
  const _ProxyPanel();

  void _showSelector(BuildContext context, String groupName) {
    showSheet(
      context: context,
      props: const SheetProps(isScrollControlled: true),
      builder: (_) {
        return AdaptiveSheetScaffold(
          title: context.appLocalizations.selectNode,
          body: QuickProxySelector(initialGroupName: groupName),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final groups = ref.watch(currentGroupsStateProvider).value;
    final currentGroupName = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    final group =
        groups.getGroup(currentGroupName ?? '') ??
        (groups.isEmpty ? null : groups.first);
    final selectedName = group == null
        ? null
        : ref.watch(selectedProxyNameProvider(group.name));
    final enabled = mode != Mode.direct && group != null;
    return _DashboardPanel(
      interactionKey: const ValueKey('compact-proxy-selector'),
      onTap: enabled ? () => _showSelector(context, group.name) : null,
      child: Row(
        children: [
          const _PanelIcon(icon: Icons.dns_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group?.name ?? context.appLocalizations.proxyGroup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.toLight,
                ),
                const SizedBox(height: 4),
                EmojiText(
                  mode == Mode.direct
                      ? Intl.message(Mode.direct.name)
                      : selectedName ??
                            context.appLocalizations.noAvailableProxies,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.toSoftBold,
                ),
              ],
            ),
          ),
          if (enabled) const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _DesktopNetworkPanel extends ConsumerWidget {
  const _DesktopNetworkPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tun = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    return _DashboardPanel(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final horizontal = constraints.maxWidth >= 560;
          final children = [
            _NetworkSwitch(
              controlKey: const ValueKey('compact-system-proxy-switch'),
              icon: Icons.computer_outlined,
              label: context.appLocalizations.systemProxy,
              value: systemProxy,
              onChanged: (value) {
                ref
                    .read(networkSettingProvider.notifier)
                    .update((state) => state.copyWith(systemProxy: value));
              },
            ),
            if (horizontal)
              const VerticalDivider(width: 1)
            else
              const Divider(),
            _NetworkSwitch(
              controlKey: const ValueKey('compact-tun-switch'),
              icon: Icons.stacked_line_chart,
              label: context.appLocalizations.tun,
              value: tun,
              onChanged: (value) {
                ref
                    .read(patchClashConfigProvider.notifier)
                    .update((state) => state.copyWith.tun(enable: value));
              },
            ),
          ];
          return horizontal
              ? IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: children[0]),
                      children[1],
                      Expanded(child: children[2]),
                    ],
                  ),
                )
              : Column(children: children);
        },
      ),
    );
  }
}

class _ModePanel extends ConsumerWidget {
  const _ModePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.appLocalizations.outboundMode,
            style: context.textTheme.titleMedium?.toSoftBold,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Mode>(
              key: const ValueKey('compact-mode-segment'),
              showSelectedIcon: false,
              segments: Mode.values
                  .map(
                    (item) => ButtonSegment<Mode>(
                      value: item,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(Intl.message(item.name)),
                      ),
                    ),
                  )
                  .toList(),
              selected: {mode},
              onSelectionChanged: (selection) {
                ref
                    .read(setupActionProvider.notifier)
                    .changeMode(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuickProxySelector extends ConsumerStatefulWidget {
  final String initialGroupName;

  const QuickProxySelector({super.key, required this.initialGroupName});

  @override
  ConsumerState<QuickProxySelector> createState() => _QuickProxySelectorState();
}

class _QuickProxySelectorState extends ConsumerState<QuickProxySelector> {
  late String _groupName;

  @override
  void initState() {
    super.initState();
    _groupName = widget.initialGroupName;
  }

  void _changeGroup(String groupName) {
    setState(() {
      _groupName = groupName;
    });
    ref.read(proxiesActionProvider.notifier).updateCurrentGroupName(groupName);
  }

  void _changeProxy(Group group, Proxy proxy) {
    if (!group.type.isComputedSelected && group.type != GroupType.Selector) {
      context.showNotifier(context.appLocalizations.notSelectedTip);
      return;
    }
    final currentProxyName = ref.read(proxyNameProvider(group.name));
    final nextProxyName =
        group.type.isComputedSelected && currentProxyName == proxy.name
        ? ''
        : proxy.name;
    ref
        .read(profilesActionProvider.notifier)
        .updateCurrentSelectedMap(group.name, nextProxyName);
    ref
        .read(proxiesActionProvider.notifier)
        .changeProxyDebounce(group.name, nextProxyName);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(currentGroupsStateProvider).value;
    if (groups.isEmpty) {
      return NullStatus(label: context.appLocalizations.noAvailableProxies);
    }
    final group = groups.getGroup(_groupName) ?? groups.first;
    if (group.name != _groupName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _changeGroup(group.name);
        }
      });
    }
    final selectedName = ref.watch(selectedProxyNameProvider(group.name));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            initialValue: group.name,
            decoration: InputDecoration(
              labelText: context.appLocalizations.proxyGroup,
              border: const OutlineInputBorder(),
            ),
            items: groups
                .map(
                  (item) => DropdownMenuItem(
                    value: item.name,
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _changeGroup(value);
              }
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: group.all.length,
            padding: const EdgeInsets.only(bottom: 24),
            itemBuilder: (_, index) {
              final proxy = group.all[index];
              return _QuickProxyItem(
                group: group,
                proxy: proxy,
                selected: selectedName == proxy.name,
                onTap: () => _changeProxy(group, proxy),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickProxyItem extends ConsumerWidget {
  final Group group;
  final Proxy proxy;
  final bool selected;
  final VoidCallback onTap;

  const _QuickProxyItem({
    required this.group,
    required this.proxy,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: group.testUrl),
    );
    return ListTile(
      selected: selected,
      leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined),
      title: EmojiText(
        proxy.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(proxy.type),
      trailing: delay == null
          ? null
          : Text(
              delay > 0
                  ? '$delay ms'
                  : delay == 0
                  ? '...'
                  : 'Timeout',
              style: context.textTheme.labelMedium?.copyWith(
                color: delay == 0 ? null : utils.getDelayColor(delay),
              ),
            ),
      onTap: onTap,
    );
  }
}

class _NetworkSwitch extends StatelessWidget {
  final Key controlKey;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NetworkSwitch({
    required this.controlKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: controlKey,
      secondary: Icon(icon),
      title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _PanelIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _PanelIcon({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: Material(
        color: active
            ? context.colorScheme.primaryContainer
            : context.colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: Icon(
          icon,
          color: active
              ? context.colorScheme.onPrimaryContainer
              : context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final Key? interactionKey;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _DashboardPanel({
    this.interactionKey,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: interactionKey,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
