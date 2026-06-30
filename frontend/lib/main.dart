import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/event_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/profile/profile_screen.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: const CalendarApp(),
    ),
  );
}

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Inicializar auth (intenta cargar usuario desde token guardado)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().init();
    });

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: context.read<AuthProvider>(),
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;

        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (isUnknown) return null; // Splash mientras carga
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/calendar';
        return null;
      },
      routes: [
        // Auth
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

        // Main shell con bottom nav
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
                path: '/calendar',
                builder: (_, __) => const CalendarScreen()),
            GoRoute(
                path: '/agenda',
                builder: (_, __) => const AgendaScreen()),
            GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Calendar App',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Shell con AppBar dinámica + BottomNavigationBar
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/calendar', label: 'Calendario', icon: Icons.calendar_month),
    (path: '/agenda', label: 'Agenda', icon: Icons.view_week),
    (path: '/profile', label: 'Perfil', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex =
        _tabs.indexWhere((t) => location.startsWith(t.path)).clamp(0, 2);

    final titles = ['Calendario', 'Agenda', 'Mi perfil'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          if (currentIndex != 2) // No mostrar en profile
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/profile'),
              tooltip: 'Perfil',
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
