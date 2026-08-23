import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../views/v2board/error.dart';

class V2boardGate extends ConsumerStatefulWidget {
  final Widget child;

  const V2boardGate({super.key, required this.child});

  @override
  ConsumerState<V2boardGate> createState() => _V2boardGateState();
}

class _V2boardGateState extends ConsumerState<V2boardGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(v2boardActionProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(v2boardActionProvider);
    if (!state.initialized) {
      return const Material(child: Center(child: CommonCircleLoading()));
    }
    if (state.session != null) {
      return widget.child;
    }
    return V2boardLoginPage(state: state);
  }
}

class V2boardLoginPage extends ConsumerStatefulWidget {
  final V2boardAccountState state;

  const V2boardLoginPage({super.key, required this.state});

  @override
  ConsumerState<V2boardLoginPage> createState() => _V2boardLoginPageState();
}

class _V2boardLoginPageState extends ConsumerState<V2boardLoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serverController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: v2boardBaseUrl);
  }

  Future<void> _submit() async {
    if (widget.state.loading || !_formKey.currentState!.validate()) {
      return;
    }
    try {
      await ref
          .read(v2boardActionProvider.notifier)
          .login(
            baseUrl: _serverController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 72,
                          height: 72,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        appName,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLocalizations.v2boardAccount,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _serverController,
                        enabled: !widget.state.loading,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        inputFormatters: TextInputLimits.limit(
                          TextInputLimits.url,
                        ),
                        autofillHints: const [AutofillHints.url],
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.dns_outlined),
                          border: const OutlineInputBorder(),
                          labelText: appLocalizations.serverAddress,
                        ),
                        validator: (value) {
                          try {
                            normalizeV2boardBaseUrl(value ?? '');
                            return null;
                          } catch (_) {
                            return appLocalizations.invalidV2boardServerUrl;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        enabled: !widget.state.loading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.alternate_email),
                          border: const OutlineInputBorder(),
                          labelText: appLocalizations.email,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return appLocalizations.emailTip;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !widget.state.loading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? appLocalizations.show
                                : appLocalizations.hide,
                            onPressed: widget.state.loading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                          labelText: appLocalizations.password,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return appLocalizations.emptyTip(
                              appLocalizations.password,
                            );
                          }
                          return null;
                        },
                      ),
                      if (widget.state.error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          v2boardErrorText(context, widget.state.error!),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: widget.state.loading ? null : _submit,
                          icon: widget.state.loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(appLocalizations.login),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
