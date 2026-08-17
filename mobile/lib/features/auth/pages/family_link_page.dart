import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/main_navigation_bar.dart';

class FamilyLinkPage extends StatefulWidget {
  const FamilyLinkPage({super.key});

  @override
  State<FamilyLinkPage> createState() => _FamilyLinkPageState();
}

class _FamilyLinkPageState extends State<FamilyLinkPage> {
  final _nameController = TextEditingController();
  final _elderUidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _receiveNotifications = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _elderUidController.dispose();
    super.dispose();
  }

  String? _validateNotEmpty(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  String? _validateElderUid(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Informe o id do idoso.';
    // basic uid validation: at least 6 characters
    if (normalized.length < 6) return 'Informe um id de idoso válido.';
    return null;
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final elderUid = _elderUidController.text.trim();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid.trim().isEmpty) {
        throw Exception('Usuário familiar não autenticado.');
      }

      // Ensure the family user has an institution associated (must have been provided at registration)
      final familyDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!familyDoc.exists || familyDoc.data() == null) {
        throw Exception('Perfil do familiar não encontrado.');
      }

      final familyData = familyDoc.data()!;
      final familyInstitutionId = familyData['institutionId']?.toString();
      if (familyInstitutionId == null || familyInstitutionId.isEmpty) {
        throw Exception('O responsável não está vinculado a uma instituição válida.');
      }

      // Link by elder uid
      await AuthService.instance.linkFamilyMemberToElderByUid(
        familyUid: currentUser.uid,
        elderUid: elderUid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idoso vinculado com sucesso!')),
      );

      // Navigate to family home (pass elder name as extra)
      context.go(RouteNames.familyHome, extra: name);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF39B2D),
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
                        'Olá, Enzo!',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: sizes.lg),

                      // Elder name
                      Text(
                        'Qual é o nome do parente que seja vincular?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: sizes.lg),
                      TextFormField(
                        controller: _nameController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        validator: (v) => _validateNotEmpty(v, 'Informe o nome do parente.'),
                        decoration: InputDecoration(
                          hintText: 'Nome do parente',
                          filled: true,
                          fillColor: const Color(0xFFEAEAEA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: sizes.lg,
                            vertical: sizes.md,
                          ),
                        ),
                      ),

                      SizedBox(height: sizes.lg),

                      // Elder id field
                      Text(
                        'Id do idoso (uid)',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: sizes.lg),
                      TextFormField(
                        controller: _elderUidController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        validator: _validateElderUid,
                        decoration: InputDecoration(
                          hintText: 'Id do idoso',
                          filled: true,
                          fillColor: const Color(0xFFEAEAEA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
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
                          color: const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(30),
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

            // bottom navigation bar
            MainNavigationBar(
              currentIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
