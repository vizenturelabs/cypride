import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        title: const Text('My Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle dark theme'),
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light
                      );
                    },
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('System Default'),
              subtitle: const Text('Follow system appearance settings'),
              trailing: Icon(Icons.brightness_4),
              onTap: () {
                context.read<ThemeProvider>().setThemeMode(ThemeMode.system);
              },
            ),
          ],
        ),
      ),
    );
  }
}