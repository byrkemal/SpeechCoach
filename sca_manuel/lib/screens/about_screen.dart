import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AboutScreen extends StatelessWidget {
  final LatLng adresKonumu = LatLng(41.43795, 33.76327);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF1E1E2C), Color(0xFF121217)]
                : [Color(0xFF8AA0FF), Color(0xFFC1D4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hakkında",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : theme.colorScheme.primary,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28),
                _buildInfoCard(
                  context,
                  icon: Icons.phone_android,
                  iconColor: theme.colorScheme.primary,
                  title: "Uygulama",
                  content:
                      "Konuşma Koçu - Doğru telaffuz ve konuşma pratiği için geliştirilmiş bir uygulama.",
                  isDark: isDark,
                ),
                SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  icon: Icons.person,
                  iconColor: theme.colorScheme.secondary,
                  title: "Geliştirici",
                  content: "Kemal Bayır - Enes Kamil Boğaz",
                  isDark: isDark,
                ),
                SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  icon: Icons.verified,
                  iconColor: theme.colorScheme.tertiary,
                  title: "Sürüm",
                  content: "1.0.0",
                  isDark: isDark,
                ),
                SizedBox(height: 24),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: adresKonumu,
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId("adres"),
                          position: adresKonumu,
                          infoWindow: InfoWindow(title: "Ofisimiz"),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Center(
                  child: Text(
                    "© 2025 Speech Coach",
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required bool isDark,
  }) {

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2A2D3E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, size: 40, color: iconColor),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
