import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/network_provider.dart';

class NetworkStatusWrapper extends StatelessWidget {
  final Widget child;

  const NetworkStatusWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, _) {
        final isOffline = !networkProvider.isOnline;
        final showOnlineToast = networkProvider.showBackOnlineBanner;

        return Stack(
          children: [
            child,
            if (isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No Internet Connection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'இணைய இணைப்பு இல்லை. Check network.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (networkProvider.isChecking)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            InkWell(
                              onTap: () => networkProvider.retryConnection(),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else if (showOnlineToast)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.wifi_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Back Online / இணைய இணைப்பு கிடைத்தது',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
