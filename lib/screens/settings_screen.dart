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
        title: const Text('Settings'),
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
                final isSystemDark =
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark;
                final isDarkModeActive =
                    themeProvider.themeMode == ThemeMode.dark ||
                        (themeProvider.themeMode == ThemeMode.system &&
                            isSystemDark);

                return ListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    themeProvider.themeMode == ThemeMode.system
                        ? 'Following system settings'
                        : 'Manual override',
                  ),
                  trailing: Switch(
                    value: isDarkModeActive,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isSystemMode =
                    themeProvider.themeMode == ThemeMode.system;
                return ListTile(
                  title: const Text('System Default'),
                  subtitle: const Text('Follow system appearance settings'),
                  trailing: isSystemMode
                      ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                      : const Icon(Icons.brightness_4),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.system);
                  },
                );
              },
            ),
            const Divider(height: 32),
            Text(
              'Customization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Dynamic Colors'),
                  subtitle: const Text('Use Android Material You colors'),
                  value: themeProvider.useDynamicColors,
                  onChanged: (value) {
                    themeProvider.setDynamicColors(value);
                  },
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isSystemDark =
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark;
                final isDarkModeActive =
                    themeProvider.themeMode == ThemeMode.dark ||
                        (themeProvider.themeMode == ThemeMode.system && isSystemDark);

                return SwitchListTile(
                  title: const Text('AMOLED Dark Mode'),
                  subtitle: const Text('Pure black background for OLED screens'),
                  value: themeProvider.useAmoled,
                  onChanged: isDarkModeActive
                      ? (value) {
                    themeProvider.setAmoled(value);
                  }
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}