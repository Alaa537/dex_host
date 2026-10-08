import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'router.dart';
import '../core/localization/strings.dart';
import '../core/theme/app_theme.dart';

class DexHostApp extends ConsumerWidget {
  const DexHostApp({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'DEX Host', debugShowCheckedModeBanner: false, theme: AppTheme.dark(), routerConfig: createRouter(ref.read(storageProvider)), supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [AppLocalizationsDelegate(), GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
  );
}
