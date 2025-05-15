import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng lostAndFoundLocation = LatLng(21.4221382, 39.8222999);
  LocationData? _userLocation;
  bool _isInMakkah = true;
  late GoogleMapController _mapController;
  String? _selectedPlace = 'Lost & Found Office';

  final Location location = Location();

  final Map<String, Map<String, dynamic>> haramLocationsMap = {
    'Tawaf Area': {'lat': 21.4223, 'lng': 39.8262, 'ar': 'صحن الطواف'},
    'Sa’i Area': {'lat': 21.4226, 'lng': 39.8270, 'ar': 'المسعى'},
    'Mezzanine Floor': {'lat': 21.4227, 'lng': 39.8267, 'ar': 'دور الميزانين'},
    'Ground Floor': {'lat': 21.4228, 'lng': 39.8265, 'ar': 'الدور الأرضي'},
    'First Floor': {'lat': 21.4230, 'lng': 39.8263, 'ar': 'الدور الأول'},
    'Second Floor': {'lat': 21.4231, 'lng': 39.8260, 'ar': 'الدور الثاني'},
    'Roof': {'lat': 21.4233, 'lng': 39.8258, 'ar': 'السقف'},
    'King Abdulaziz Gate': {'lat': 21.4217, 'lng': 39.8269, 'ar': 'باب الملك عبدالعزيز'},
    'King Fahd Gate': {'lat': 21.4235, 'lng': 39.8275, 'ar': 'باب الملك فهد'},
    'Umrah Gate': {'lat': 21.4229, 'lng': 39.8280, 'ar': 'باب العمرة'},
    'Marwah Gate': {'lat': 21.4238, 'lng': 39.8271, 'ar': 'باب المروة'},
    'Salam Gate': {'lat': 21.4236, 'lng': 39.8260, 'ar': 'باب السلام'},
    'North Square': {'lat': 21.4240, 'lng': 39.8265, 'ar': 'الساحة الشمالية'},
    'South Square': {'lat': 21.4215, 'lng': 39.8257, 'ar': 'الساحة الجنوبية'},
    'West Square': {'lat': 21.4222, 'lng': 39.8249, 'ar': 'الساحة الغربية'},
    'East Square': {'lat': 21.4225, 'lng': 39.8285, 'ar': 'الساحة الشرقية'},
    'Women Gates': {'lat': 21.4221, 'lng': 39.8270, 'ar': 'بوابات النساء'},
    'North Toilets': {'lat': 21.4242, 'lng': 39.8267, 'ar': 'دورات المياه - الشمالية'},
    'South Toilets': {'lat': 21.4213, 'lng': 39.8253, 'ar': 'دورات المياه - الجنوبية'},
    'West Toilets': {'lat': 21.4220, 'lng': 39.8247, 'ar': 'دورات المياه - الغربية'},
    'Elevators': {'lat': 21.4226, 'lng': 39.8268, 'ar': 'المصاعد'},
    'Escalators': {'lat': 21.4224, 'lng': 39.8266, 'ar': 'السلالم الكهربائية'},
    'Lost & Found Office': {
      'lat': 21.4221382,
      'lng': 39.8222999,
      'ar': 'مكتب المفقودات',
      'highlight': true,
      'desc_ar': 'يقع مكتب الأمانات في الزاوية الجنوبية الغربية من الحرم. يمكنك زيارته لاستلام أو تسليم المفقودات.',
      'desc_en': 'Located in the southwestern corner of the Haram. Visit it to claim or deliver lost items.'
    },
    'Security Office': {'lat': 21.4231, 'lng': 39.8256, 'ar': 'مكتب الأمن'},
  };

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    final userLocation = await location.getLocation();
    final isMakkah = userLocation.latitude != null &&
        userLocation.longitude != null &&
        userLocation.latitude! >= 21.3 &&
        userLocation.latitude! <= 21.5 &&
        userLocation.longitude! >= 39.7 &&
        userLocation.longitude! <= 39.9;

    setState(() {
      _userLocation = userLocation;
      _isInMakkah = isMakkah;
    });
  }

  void _moveToLocation(String key) {
    final target = haramLocationsMap[key];
    if (target != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(
        LatLng(target['lat'], target['lng']),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      appBar: AppBar(
        title: Text('lost_and_found_map'.tr(), style: TextStyle(fontFamily: fontFamily, color: Colors.white)),
        backgroundColor: const Color(0xFF4B2E2B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: lostAndFoundLocation,
              zoom: 17,
            ),
            mapType: MapType.satellite,
            myLocationEnabled: _userLocation != null && _isInMakkah,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            markers: haramLocationsMap.entries.map((entry) {
              return Marker(
                markerId: MarkerId(entry.key),
                position: LatLng(entry.value['lat'], entry.value['lng']),
                infoWindow: InfoWindow(title: lang == 'ar' ? entry.value['ar'] : entry.key),
                icon: entry.value['highlight'] == true
                    ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
                    : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              );
            }).toSet(),
          ),
          if (!_isInMakkah)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('tracking_available_makkah_only'),
                        style: TextStyle(fontFamily: fontFamily, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('select_location'), style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPlace,
                      underline: const SizedBox(),
                      items: haramLocationsMap.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(
                            lang == 'ar' ? haramLocationsMap[key]!['ar'] : key,
                            style: TextStyle(fontFamily: fontFamily),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPlace = val;
                          _moveToLocation(val!);
                        });
                      },
                    ),
                    if (_selectedPlace == 'Lost & Found Office')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == 'ar'
                                    ? haramLocationsMap['Lost & Found Office']!['desc_ar']
                                    : haramLocationsMap['Lost & Found Office']!['desc_en'],
                                style: TextStyle(fontFamily: fontFamily, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await launchUrl(Uri.parse("https://maps.google.com/?q=21.4221382,39.8222999"));
                                },
                                icon: const Icon(Icons.directions),
                                label: Text(tr('open_in_maps'), style: TextStyle(fontFamily: fontFamily)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B2E2B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
