import 'package:flutter/material.dart';

import '../../../core/routes/route_names.dart';
import '../../auth/models/account_type.dart';

class MenuItemModel {
  const MenuItemModel({
    required this.title,
    required this.description,
    required this.icon,
    this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? route;
}

List<MenuItemModel> menuItemsForAccount(AccountType accountType) {
  return switch (accountType) {
    AccountType.elder => const [
      MenuItemModel(
        title: 'Rotina',
        description: 'Acesse sua rotina para ver as suas tarefas diárias.',
        icon: Icons.event_note_rounded,
        route: RouteNames.routine,
      ),
      MenuItemModel(
        title: 'Chat',
        description: 'Envie mensagens rápidas para se comunicar.',
        icon: Icons.chat_bubble_rounded,
        route: RouteNames.chat,
      ),
      MenuItemModel(
        title: 'Assistente Virtual',
        description: 'Responda suas dúvidas rapidamente com o Auri.',
        icon: Icons.smart_toy_rounded,
      ),
      MenuItemModel(
        title: 'Central de Denúncias',
        description: 'Faça uma denúncia anônima pessoal ou de terceiros.',
        icon: Icons.report_rounded,
        route: RouteNames.reportStart,
      ),
    ],
    AccountType.caregiver => const [
      MenuItemModel(
        title: 'Residentes',
        description: 'Acesse rapidamente as informações e rotinas dos idosos.',
        icon: Icons.elderly_rounded,
        route: RouteNames.routine,
      ),
      MenuItemModel(
        title: 'Chat - Converse',
        description: 'Envie mensagens rápidas para se comunicar.',
        icon: Icons.forum_rounded,
        route: RouteNames.chat,
      ),
    ],
    AccountType.family => const [
      MenuItemModel(
        title: 'Rotina do parente',
        description: 'Acompanhe as tarefas e atividades do seu parente.',
        icon: Icons.event_note_rounded,
        route: RouteNames.routine,
      ),
      MenuItemModel(
        title: 'Chat - Converse',
        description: 'Converse com o idoso e com seus cuidadores.',
        icon: Icons.forum_rounded,
        route: RouteNames.chat,
      ),
    ],
  };
}
