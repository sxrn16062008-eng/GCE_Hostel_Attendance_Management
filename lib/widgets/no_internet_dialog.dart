import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/network_provider.dart';

class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const NoInternetDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'இணைய இணைப்பு இல்லை. Please turn on Wi-Fi or Mobile Data to continue using the app.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: networkProvider.isChecking
                    ? null
                    : () async {
                        final isOnline = await networkProvider.retryConnection();
                        if (isOnline && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                icon: networkProvider.isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  networkProvider.isChecking ? 'Checking...' : 'Retry / மீண்டும் முயற்சி',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
