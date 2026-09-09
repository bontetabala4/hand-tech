import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/hardware_providers.dart';
import '../providers/auth_provider.dart';

class HardwareHeader extends ConsumerWidget {
  const HardwareHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryLevel = ref.watch(glassBatteryLevelProvider);
    final isCameraActive = ref.watch(isCameraActiveProvider);
    final isBluetoothConnected = ref.watch(isBluetoothConnectedProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Battery
              Row(
                children: [
                  Icon(
                    batteryLevel > 20 ? Icons.battery_full : Icons.battery_alert,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$batteryLevel%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Signal / Connectivity
              Row(
                children: [
                  Icon(
                    isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: isBluetoothConnected ? AppTheme.statusConnected : AppTheme.statusDisconnected,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  // Camera Status
                  Icon(
                    Icons.videocam,
                    color: isCameraActive ? AppTheme.statusConnected : AppTheme.statusWarning,
                    size: 20,
                  ),
                ],
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppTheme.accentBlue),
                    onPressed: () {
                      // TODO: Navigate to pairing/settings
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: AppTheme.statusDisconnected),
                    onPressed: () {
                      ref.read(authStateProvider.notifier).signOut();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
