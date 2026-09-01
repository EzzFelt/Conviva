import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/border_card_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/menu_item_model.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  Future<void> _goHome(
    BuildContext context,
    UserSession session,
  ) async {
    await AuthenticatedUserNavigator.open(context, session);
  }

  void _openItem(BuildContext context, MenuItemModel item) {
    final route = item.route;
    if (route != null) {
      context.go(route);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} estará disponível em breve.')),
    );
  }

  Widget _accountIllustration(
    BuildContext context,
    MenuItemModel item,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Container(
      width: sizes.xxl + sizes.lg,
      height: sizes.xxl + sizes.lg,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(sizes.radiusMd),
      ),
      alignment: Alignment.center,
      child: Icon(
        item.icon,
        size: sizes.icon(sizes.xl + sizes.sm),
        color: colorScheme.primary,
      ),
    );
  }

  Widget _content(
    BuildContext context,
    UserSession session,
  ) {
    final sizes = context.appSizes;
    final items = menuItemsForAccount(session.accountType);
    final isCompact = session.accountType == AccountType.elder;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.appGradientColors.bottom,
              context.appGradientColors.top,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageHeaderWidget(
                title: 'Menu',
                onBackPressed: () {
                  _goHome(context, session);
                },
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    sizes.md,
                    sizes.md,
                    sizes.md,
                    sizes.xxl * 3,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(height: sizes.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return BorderCardWidget(
                      title: item.title,
                      description: item.description,
                      leading: isCompact
                          ? null
                          : _accountIllustration(context, item),
                      minimumHeight: isCompact
                          ? sizes.xxl + sizes.xl + sizes.sm
                          : sizes.xxl * 2 + sizes.lg,
                      onTap: () => _openItem(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(currentUserProvider);
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: sessionState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(sizes.lg),
            child: Text(
              error.toString().replaceFirst('Bad state: ', ''),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Usuário não autenticado.'));
          }

          return _content(context, session);
        },
      ),
    );
  }
}
