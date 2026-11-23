import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'repositories/quotation_repository.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/quotation_list_viewmodel.dart';
import 'views/home/home_shell.dart';
import 'views/quotation_detail/quotation_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
  runApp(const QuotationApp());
}

class QuotationApp extends StatefulWidget {
  const QuotationApp({super.key});

  @override
  State<QuotationApp> createState() => _QuotationAppState();
}

class _QuotationAppState extends State<QuotationApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleLink(initialLink);

      _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
    } catch (e) {
      debugPrint('Deep link init failed: $e');
    }
  }

  void _handleLink(Uri uri) {
    final quotationId = _quotationIdFrom(uri);
    if (quotationId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => QuotationDetailScreen(quotationId: quotationId),
        ),
      );
    });
  }

  /// Supports quotationapp://quotation/{id} and quotationapp:///quotation/{id}
  int? _quotationIdFrom(Uri uri) {
    if (uri.scheme != 'quotationapp') return null;
    final parts = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];
    if (parts.length >= 2 && parts[0] == 'quotation') {
      return int.tryParse(parts[1]);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      home: MultiProvider(
        providers: [
          Provider<QuotationRepository>(create: (_) => QuotationRepository()),
          ChangeNotifierProvider<QuotationListViewModel>(
            create: (context) => QuotationListViewModel(
              repository: context.read<QuotationRepository>(),
            ),
          ),
          ChangeNotifierProvider<HomeViewModel>(
            create: (context) => HomeViewModel(
              repository: context.read<QuotationRepository>(),
            )..load(),
          ),
        ],
        child: const HomeShell(),
      ),
    );
  }
}
