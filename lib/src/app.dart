import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'router/app_router.dart';

class SpendGremlinApp extends StatelessWidget {
  const SpendGremlinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter();
    return MaterialApp.router(
      title: 'Spend Gremlin',
      theme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

