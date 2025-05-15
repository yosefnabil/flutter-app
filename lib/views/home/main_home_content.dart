import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:laqya_app/views/home/MapScreen.dart';

class MainHomeContent extends StatelessWidget {
  final String userName;
  const MainHomeContent({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    final haramOfficeLatLng = const LatLng(21.4225, 39.8262);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'welcome'.tr()}, $userName 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
              )),
          const SizedBox(height: 24),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _FeatureCard(
                icon: Icons.add_circle_outline,
                title: tr('add_report'),
                onTap: () => Navigator.pushNamed(context, '/add-report'),
                fontFamily: fontFamily,
              ),
              _FeatureCard(
                icon: Icons.history,
                title: tr('my_reports'),
                onTap: () => Navigator.pushNamed(context, '/my-reports'),
                fontFamily: fontFamily,
              ),
              _FeatureCard(
                icon: Icons.map,
                title: tr('lost_and_found_map'),
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const MapScreen(),
                    transitionsBuilder: (_, animation, __, child) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
                fontFamily: fontFamily,
              ),
              _FeatureCard(
                icon: Icons.info_outline,
                title: tr('instructions'),
                onTap: () => Navigator.pushNamed(context, '/instructions'),
                fontFamily: fontFamily,
              ),
              _FeatureCard(
                icon: Icons.compare_arrows,
                title: tr('matching_items'),
                onTap: () => Navigator.pushNamed(context, '/matching-items'),
                fontFamily: fontFamily,
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text('lost_and_found_location'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
              )),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                AbsorbPointer(
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: haramOfficeLatLng,
                        zoom: 17.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('haram_lost_found'),
                          position: haramOfficeLatLng,
                          infoWindow: InfoWindow(title: tr('lost_and_found_office')),
                        )
                      },
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      liteModeEnabled: true,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const MapScreen(),
                          transitionsBuilder: (_, animation, __, child) => FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      ),
                    ),
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

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String fontFamily;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.fontFamily,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.95);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final double cardWidth = (MediaQuery.of(context).size.width / 2) - 32;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4B2E2B),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Icon(widget.icon, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: widget.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
