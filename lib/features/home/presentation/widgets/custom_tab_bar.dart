import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  const CustomTabBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TabBar(
      controller: controller,
      isScrollable: true,
      indicatorColor: theme.colorScheme.secondary,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.red),
      tabs: const [
        Tab(text: 'Son Çalınanlar'),
        Tab(text: 'En Çok Çalınanlar'),
        Tab(text: 'Tüm Şarkılar'),
        Tab(text: 'Favoriler'),
        Tab(text: 'Albümler'),
        Tab(text: 'Klasörler'),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
