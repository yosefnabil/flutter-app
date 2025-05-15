import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

class OfficerQRScanScreen extends StatefulWidget {
  const OfficerQRScanScreen({super.key});

  @override
  State<OfficerQRScanScreen> createState() => _OfficerQRScanScreenState();
}

class _OfficerQRScanScreenState extends State<OfficerQRScanScreen> {
  bool isScanning = true;
  bool hasResult = false;
  bool isSuccess = false;
  bool isFlashOn = false;
  String? message;
  final player = AudioPlayer();
  final MobileScannerController controller = MobileScannerController();

  Future<void> handleQRCode(String url) async {
    setState(() {
      isScanning = false;
      hasResult = false;
      message = null;
    });

    try {
      final reportNumber = url.trim();
      final query = await FirebaseFirestore.instance
          .collection('reports')
          .where('reportNumber', isEqualTo: reportNumber)
          .get();

      if (query.docs.isEmpty) {
        showError(tr('not_found'));
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();
      final type = data['type'];
      final status = data['status'];
      final title = data['title'] ?? tr('no_title');

      if (status == 'delivered') {
        showError(tr('delivered_before', args: [title]));
        return;
      }

      if (type == 'found' && (status == 'تم الاستلام' || status == 'received')) {
        showError(tr('received_before', args: [title]));
        return;
      }

      if (type == 'found') {
        await doc.reference.update({'status': 'تم الاستلام'});
        await player.play(AssetSource('sounds/successb.mp3'));
        showSuccess(tr('received_success', args: [title]));
      } else if (type == 'missing') {
        if (status == 'matched') {
          await doc.reference.update({'status': 'delivered'});
          await player.play(AssetSource('sounds/successb.mp3'));
          showSuccess(tr('delivered_after_match', args: [title]));
        } else if (status == 'تم الاستلام' || status == 'received') {
          await doc.reference.update({'status': 'تم التسليم إلى العميل'});
          await player.play(AssetSource('sounds/successb.mp3'));
          showSuccess(tr('delivered_to_clientt', args: [title]));
        } else {
          showError(tr('cannot_deliver', args: [status]));
        }
      } else {
        showError(tr('unknown_type'));
      }
    } catch (e) {
      showError(tr('error_occurred', args: [e.toString()]));
    }
  }

  void showSuccess(String msg) {
    setState(() {
      hasResult = true;
      isSuccess = true;
      message = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('operation_success'))));
  }

  void showError(String msg) {
    setState(() {
      hasResult = true;
      isSuccess = false;
      message = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('operation_failed'))));
  }

  void resetScanner() {
    setState(() {
      isScanning = true;
      hasResult = false;
      message = null;
    });
  }

  void toggleFlash() {
    isFlashOn = !isFlashOn;
    controller.toggleTorch();
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Directionality(
      textDirection: lang == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F3EF),
        appBar: AppBar(
          title: Text(
            'scan_report'.tr(),
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF4B2E2B),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: toggleFlash,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: isScanning
                  ? Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.first;
                      final String? code = barcode.rawValue;
                      if (code != null) {
                        handleQRCode(code);
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              )
                  : hasResult
                  ? Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          isSuccess
                              ? 'assets/lottie/success.json'
                              : 'assets/lottie/error.json',
                          width: 150,
                          repeat: false,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          message ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B2E2B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: resetScanner,
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                          label: Text(
                            'scan_another'.tr(),
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : Center(
                child: Lottie.asset('assets/lottie/loader.json', width: 150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
