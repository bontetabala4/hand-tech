import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/glasses_device.dart';
import '../providers/pairing_provider.dart';
import 'glasses_dashboard_screen.dart';

class GlassesPairingScreen extends ConsumerStatefulWidget {
  const GlassesPairingScreen({super.key});

  @override
  ConsumerState<GlassesPairingScreen> createState() => _GlassesPairingScreenState();
}

class _GlassesPairingScreenState extends ConsumerState<GlassesPairingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pairingProvider.notifier).startScanning();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleConnect(GlassesDevice device) {
    HapticFeedback.lightImpact();
    ref.read(pairingProvider.notifier).connect(device);
  }

  @override
  Widget build(BuildContext context) {
    final pairingState = ref.watch(pairingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF808080),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D4D4D),
        title: const Text('Appairage des Lunettes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assistance d\'appairage en cours de développement')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (pairingState.errorMessage != null)
              Container(
                color: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pairingState.errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(pairingProvider.notifier).startScanning();
                      },
                      child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: _buildMainContent(pairingState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(PairingState state) {
    if (state.status == PairingStatus.connected && state.connectedDevice != null) {
      return _buildConnectedView(state);
    }
    
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildRadarAnimation(state.status),
        const SizedBox(height: 40),
        Text(
          state.status == PairingStatus.scanning 
              ? 'Recherche de lunettes à proximité...'
              : 'Appareils détectés',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.scannedDevices.length,
            itemBuilder: (context, index) {
              final device = state.scannedDevices[index];
              final isConnecting = state.status == PairingStatus.connecting && state.connectedDevice?.id == device.id;
              
              return Card(
                color: const Color(0xFF666666),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.bluetooth, color: Colors.white, size: 32),
                  title: Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Icon(Icons.signal_cellular_alt, color: _getRssiColor(device.rssi), size: 16),
                      const SizedBox(width: 4),
                      Text('${device.rssi} dBm', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  trailing: isConnecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => _handleConnect(device),
                          child: const Text('Connecter'),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView(PairingState state) {
    final telemetry = state.telemetry;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 80),
          const SizedBox(height: 16),
          const Text(
            'Connecté avec succès!',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Card(
            color: const Color(0xFF4D4D4D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTelemetryRow(
                    Icons.battery_full,
                    'Batterie',
                    telemetry != null ? '${telemetry.batteryLevel}%' : '--%',
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildTelemetryRow(
                    Icons.system_update,
                    'Firmware',
                    telemetry != null ? telemetry.firmwareVersion : '...',
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildTelemetryRow(
                    Icons.camera_alt,
                    'Double Caméra',
                    telemetry != null 
                        ? (telemetry.isDualCameraActive ? 'Active' : 'Veille') 
                        : '...',
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GlassesDashboardScreen()),
                );
              },
              child: const Text('Accéder au Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRadarAnimation(PairingStatus status) {
    if (status != PairingStatus.scanning && status != PairingStatus.connecting) {
      return const SizedBox(
        width: 150,
        height: 150,
        child: Icon(Icons.bluetooth, size: 64, color: Colors.white54),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150 * _pulseController.value,
              height: 150 * _pulseController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 1 - _pulseController.value),
              ),
            ),
            Container(
              width: 100 * ((_pulseController.value + 0.5) % 1.0),
              height: 100 * ((_pulseController.value + 0.5) % 1.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 1 - ((_pulseController.value + 0.5) % 1.0)),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF38BDF8),
              ),
              child: const Icon(Icons.bluetooth_searching, color: Colors.white, size: 32),
            ),
          ],
        );
      },
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -60) return const Color(0xFF4ADE80);
    if (rssi > -80) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }
}
