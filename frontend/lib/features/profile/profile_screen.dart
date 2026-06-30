import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../shared/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
          name: _nameCtrl.text.trim(),
        );
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _editing = false;
      });
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Confirmas que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final eventCount = context.watch<EventProvider>().events.length;
    final joinDate = user != null
        ? DateFormat('MMMM yyyy').format(user.createdAt)
        : '—';

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 36,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Name / edit
                if (_editing)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Nombre'),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _saveProfile,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Guardar'),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _editing = false),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => setState(() => _editing = true),
                        tooltip: 'Editar nombre',
                      ),
                    ],
                  ),

                Text(user.email,
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),

                // Stats card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    child: Row(
                      children: [
                        _StatItem(
                          icon: Icons.event,
                          value: '$eventCount',
                          label: 'Eventos',
                        ),
                        const VerticalDivider(width: 32),
                        _StatItem(
                          icon: Icons.calendar_today,
                          value: joinDate,
                          label: 'Miembro desde',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Settings section
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outlined),
                        title: const Text('Cambiar contraseña'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Versión'),
                        trailing: const Text('1.0.0',
                            style: TextStyle(color: Colors.black45)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Logout
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Cerrar sesión',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Contraseña actual'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Nueva contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              // Llamar al endpoint /users/me/password
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraseña actualizada')),
              );
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}
