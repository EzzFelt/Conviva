import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/button_widget.dart';

class FamilyLinkPage extends StatefulWidget {
  const FamilyLinkPage({super.key});

  @override
  State<FamilyLinkPage> createState() => _FamilyLinkPageState();
}

class _FamilyLinkPageState extends State<FamilyLinkPage> {
  final _elderCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _receiveNotifications = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _elderCodeController.dispose();
    super.dispose();
  }

  String? _validateElderCode(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return 'Informe o código do idoso.';
    if (!RegExp(r'^ELD[A-Z0-9]+$').hasMatch(normalized)) return 'Use um código no formato ELD4321.';
    return null;
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final elderCode = _elderCodeController.text.trim().toUpperCase();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid.trim().isEmpty) {
        throw Exception('Usuário familiar não autenticado.');
      }

      final elderData = await AuthService.instance.linkFamilyMemberToElder(
        familyUid: currentUser.uid,
        elderLinkCode: elderCode,
        receiveNotifications: _receiveNotifications,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idoso vinculado com sucesso!')),
      );

      context.go(
        RouteNames.familyHome,
        extra: elderData['name']?.toString() ?? 'Idoso',
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is Exception ? error.toString().replaceFirst('Exception: ', '') : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final familyName = FirebaseAuth.instance.currentUser?.displayName?.trim();

    return Scaffold(
      backgroundColor: context.appGradientColors.bottom,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  sizes.lg,
                  sizes.lg,
                  sizes.lg,
                  sizes.xl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: sizes.sm),
                      Text(
                        familyName == null || familyName.isEmpty
                            ? 'Olá!'
                            : 'Olá, $familyName!',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: sizes.lg),

                      Text(
                        'Código de acesso do idoso',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: sizes.lg),
                      TextFormField(
                        controller: _elderCodeController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: _validateElderCode,
                        decoration: InputDecoration(
                          hintText: 'ELD4321',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              sizes.radiusFull,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: sizes.lg,
                            vertical: sizes.md,
                          ),
                        ),
                      ),

                      SizedBox(height: sizes.xl),
                      Text(
                        'Deseja receber notificações sobre atualizações do parente?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: sizes.md),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: sizes.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            sizes.radiusFull,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _receiveNotifications,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: true,
                                child: Text('Sim, quero receber'),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text('Não quero receber'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _receiveNotifications = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: sizes.xl),
                      ButtonWidget(
                        label: _isSubmitting ? 'Vinculando...' : 'Vincular Parente',
                        variant: ButtonVariant.primary,
                        onPressed: _isSubmitting ? null : _continue,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
