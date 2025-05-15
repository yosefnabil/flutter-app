import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:audioplayers/audioplayers.dart';

import 'haram_locations.dart';
import 'report_categories.dart';

final GlobalKey _bottomSheetKey = GlobalKey();
bool _isSaving = false;
bool _isSavingImage = false;

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _timeController = TextEditingController();

  String _reportType = 'missing';
  String _category = 'electronics';
  String? _selectedLocation;
  String? _userPhone;
  File? _selectedImage;
  DateTime? _selectedDateTime;

  GlobalKey _qrKey = GlobalKey();
  String? _generatedDocId;
  String? _qrImageUrl;

  final Map<Color, String> _colorMap = {
    Colors.red: 'color_red'.tr(),
    Colors.blue: 'color_blue'.tr(),
    Colors.green: 'color_green'.tr(),
    Colors.yellow: 'color_yellow'.tr(),
    Colors.orange: 'color_orange'.tr(),
    Colors.purple: 'color_purple'.tr(),
    Colors.black: 'color_black'.tr(),
    Colors.white: 'color_white'.tr(),
    Colors.brown: 'color_brown'.tr(),
    Colors.grey: 'color_grey'.tr(),

    // iPhone-like colors
    const Color(0xFF1C1C1E): 'Graphite',           // رمادي آيفون غامق
    const Color(0xFF9EB7E5): 'Sierra Blue',         // أزرق آيفون
    const Color(0xFFF5F5DC): 'Starlight',           // ستارلايت
    const Color(0xFF121212): 'Midnight',            // أسود مزرق
    const Color(0xFF4C6444): 'iPhone Green',        // أخضر آيفون
    const Color(0xFFD6C7E0): 'iPhone Purple',       // أرجواني آيفون

    // Bank card colors
    const Color(0xFFC0C0C0): 'Silver Card',         // فضي
    const Color(0xFFFFD700): 'Gold Card',           // ذهبي
            // أسود
    const Color(0xFF001F3F): 'Navy Blue Card',      // أزرق داكن
    const Color(0xFF228B22): 'Green Card',          // أخضر
    const Color(0xFFFF69B4): 'Pink Card',           // وردي
    const Color(0xFFCD7F32): 'Bronze Card',         // برونزي
    const Color(0xFFB87333): 'Copper Card',         // نحاسي
  };


  @override
  void initState() {
    super.initState();
    _fetchUserPhone();
  }

  Future<void> _fetchUserPhone() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['phone'] != null) {
        setState(() => _userPhone = doc['phone']);
      }
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Cairo'),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Cairo'),
          ),
          child: child!,
        ),
      );
      if (time != null) {
        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          _selectedDateTime = dt;
          _timeController.text = DateFormat.yMd(context.locale.languageCode).add_jm().format(dt);
        });
      }
    }
  }
  String generateReportNumber() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final random = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    return '$day$month$random';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedImage == null ||
        _selectedLocation == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('required_field'.tr(), style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 140,
          height: 140,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Lottie.asset('assets/lottie/loader.json', width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    try {
      final reportNumber = generateReportNumber(); // ✅ توليد رقم البلاغ
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('report_images/$imageName');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      // ✅ حفظ البلاغ باستخدام reportNumber كـ Document ID
      final reportDocRef = FirebaseFirestore.instance.collection('reports').doc(reportNumber);

      await reportDocRef.set({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _category,
        'color': _colorController.text,
        'location': _selectedLocation,
        'time': _selectedDateTime?.toIso8601String(),
        'type': _reportType,
        'imageUrl': imageUrl,
        'userId': uid,
        'contactNumber': _userPhone,
        'status': 'processing',
        'created_at': FieldValue.serverTimestamp(),
        'reportNumber': reportNumber,
      });

      _generatedDocId = reportNumber; // ✅ نستخدم نفس الرقم كـ ID

      final qrBytes = await _captureQR();
      final qrRef = FirebaseStorage.instance.ref().child('qr_codes/$reportNumber.png');
      await qrRef.putData(qrBytes);
      _qrImageUrl = await qrRef.getDownloadURL();

      await reportDocRef.update({'qrUrl': _qrImageUrl});

      Navigator.pop(context);
      _showSuccessDialog(reportNumber); // ✅ تمرير الرقم لعرضه في واجهة النجاح
    } catch (e, stack) {
      Navigator.pop(context);
      print("❌ حصل خطأ: $e");
      print("📛 StackTrace:\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_try_again'.tr(), style: TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

// 🇬🇧🇸🇦 Translated QR and Image Saving Logic with Localization
  bool _isSavingImage = false; // Temporary flag to hide buttons while saving

  Future<void> _saveFullBottomSheetAsImage(GlobalKey boundaryKey) async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('permission_photos_needed'), style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // slight delay for UI to update

      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await FlutterImageGallerySaver.saveImage(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('report_saved_success'), style: TextStyle(fontFamily: 'Cairo'))),
      );
    } catch (e) {
      print('❌ Error while saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('save_failed'), style: TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

  Future<bool> _requestPhotoPermission() async {
    if (await Permission.photos.isGranted) return true;
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) await openAppSettings();
    return false;
  }

  Future<void> _saveQrToGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return;
    }

    try {
      final Uint8List bytes = await _captureQR();
      await FlutterImageGallerySaver.saveImage(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('qr_saved_success'), style: TextStyle(fontFamily: 'Cairo'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('error_saving_qr'), style: TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

  Future<Uint8List> _captureQR() async {
    final painter = QrPainter(
      data: _generatedDocId ?? '',
      version: QrVersions.auto,
      gapless: false,
      color: Colors.black,
      emptyColor: Colors.white,
    );

    final image = await painter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _showSuccessDialog(String reportNumber) {
    final player = AudioPlayer();
    player.play(AssetSource('sounds/successb.mp3'));
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';
    final GlobalKey _dialogKey = GlobalKey();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.bottomCenter,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Material(
              color: Colors.transparent,
              child: RepaintBoundary(
                key: _dialogKey,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B2E2B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                        const Icon(Icons.check_circle, color: Colors.white, size: 64),
                        const SizedBox(height: 12),
                        Text(
                          tr('report_sent_success'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tr('report_number')}: $reportNumber',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4B2E2B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _generatedDocId ?? '',
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // هنا بناءً على نوع البلاغ تظهر رسالة مخصصة
                        if (_reportType == 'found') ...[
                          Text(
                            tr('keep_qr_instruction'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: fontFamily, color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('show_to_officer_instruction'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: fontFamily, color: Colors.white70),
                          ),
                        ] else ...[
                          Text(
                            tr('qr_instruction'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: fontFamily, color: Colors.white70),
                          ),
                        ],

                        const SizedBox(height: 20),

                        _styledDetail(tr('title'), _titleController.text, fontFamily),
                        _styledDetail(
                          tr('category'),
                          reportCategories(context).firstWhere((e) => e['value'] == _category)['label']!,
                          fontFamily,
                        ),
                        _styledDetail(tr('location'), _selectedLocation ?? '', fontFamily),
                        if (_userPhone != null)
                          _styledDetail(tr('contact_number'), _userPhone!, fontFamily),
                        if (_selectedDateTime != null)
                          _styledDetail(
                            _reportType == 'missing' ? tr('lost_time') : tr('found_time'),
                            DateFormat.yMd(lang).add_jm().format(_selectedDateTime!),
                            fontFamily,
                          ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  setDialogState(() => _isSavingImage = true);
                                  await _saveFullBottomSheetAsImage(_dialogKey);
                                  setDialogState(() => _isSavingImage = false);
                                },
                                icon: const Icon(Icons.save_alt),
                                label: Text(tr('save_as_image'), style: TextStyle(fontFamily: fontFamily)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareReport,
                                icon: const Icon(Icons.share),
                                label: Text(tr('share'), style: TextStyle(fontFamily: fontFamily)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }




  Widget _styledDetail(String label, String value, String fontFamily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: fontFamily)),
          Expanded(child: Text(value, style: TextStyle(fontFamily: fontFamily))),
        ],
      ),
    );
  }




  Future<void> _shareReport() async {
    final text = '''
${'report_type'.tr()}: ${_reportType == 'missing' ? 'report_missing'.tr() : 'report_found'.tr()}
${'title'.tr()}: ${_titleController.text}
${'description'.tr()}: ${_descriptionController.text}
${'category'.tr()}: ${reportCategories(context).firstWhere((e) => e['value'] == _category)['label']}
${'color'.tr()}: ${_colorController.text}
${'location'.tr()}: $_selectedLocation
${_userPhone != null ? "📞 ${_userPhone!}" : ""}
QR Code: ${_qrImageUrl ?? ''}
''';

    await Share.share(text);
  }

  Widget _buildDetailRow(String label, String value, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text('$label:', style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontFamily: fontFamily))),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final fontFamily = lang == 'ar' ? 'Cairo' : 'OpenSans';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B2E2B),
        title: Text('add_report'.tr(), style: TextStyle(fontFamily: fontFamily, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('report_info'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
              const SizedBox(height: 16),
              Text('report_type'.tr(), style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Center(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'missing', label: Text('report_missing'.tr(), style: TextStyle(fontFamily: fontFamily))),
                    ButtonSegment(value: 'found', label: Text('report_found'.tr(), style: TextStyle(fontFamily: fontFamily))),
                  ],
                  selected: {_reportType},
                  onSelectionChanged: (val) => setState(() => _reportType = val.first),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xFF4B2E2B)),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('title'.tr(), _titleController, fontFamily, icon: Icons.title),
              const SizedBox(height: 12),
              _buildTextField('description'.tr(), _descriptionController, fontFamily, maxLines: 3, icon: Icons.description),
              const SizedBox(height: 12),
              _buildDropdown(
                'category'.tr(),
                _category,
                reportCategories(context).map((item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(item['label']!, style: TextStyle(color: Colors.black, fontFamily: fontFamily)),
                  );
                }).toList(),
                    (val) => setState(() => _category = val),
                fontFamily,
                icon: Icons.category,
              ),
              const SizedBox(height: 12),
              Text('select_color'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: fontFamily)),
              const SizedBox(height: 8),
              _buildTextField('color'.tr(), _colorController, fontFamily, icon: Icons.palette),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorMap.entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      _colorController.text = context.locale.languageCode == 'ar' ? entry.value : entry.value.toLowerCase();
                    },
                    child: CircleAvatar(backgroundColor: entry.key, radius: 16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                _reportType == 'missing' ? 'expected_place'.tr() : 'found_place'.tr(),
                _selectedLocation,
                getHaramLocations(context).map((loc) {
                  return DropdownMenuItem<String>(
                    value: loc,
                    child: Text(loc, style: TextStyle(color: Colors.black, fontFamily: fontFamily)),
                  );
                }).toList(),
                    (val) => setState(() => _selectedLocation = val),
                fontFamily,
                icon: Icons.location_on,
              ),
              if (_reportType == 'missing' || _reportType == 'found') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _pickDateTime,
                  decoration: _inputDecoration(
                    _reportType == 'missing' ? 'lost_time'.tr() : 'found_time'.tr(),
                    fontFamily,
                    Icons.access_time,
                  ),
                  style: TextStyle(fontFamily: fontFamily),
                ),
              ],

              if (_userPhone != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  enabled: false,
                  initialValue: _userPhone,
                  decoration: _inputDecoration('contact_number'.tr(), fontFamily, Icons.phone),
                  style: TextStyle(fontFamily: fontFamily),
                ),
              ],
              const SizedBox(height: 24),
              Text('attach_image'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _pickImage(source: ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: Text('pick_gallery'.tr(), style: TextStyle(fontFamily: fontFamily)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _pickImage(source: ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text('take_photo'.tr(), style: TextStyle(fontFamily: fontFamily)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover, height: 160, width: double.infinity),
                ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: Text('submit'.tr(), style: TextStyle(fontFamily: fontFamily, color: Colors.white)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B2E2B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller, String fontFamily,
      {int maxLines = 1, IconData? icon}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, fontFamily, icon),
      style: TextStyle(fontFamily: fontFamily),
      validator: (val) => val == null || val.isEmpty ? 'required_field'.tr() : null,
    );
  }

  Widget _buildDropdown(String label, dynamic value, List<DropdownMenuItem> items,
      void Function(dynamic) onChanged, String fontFamily,
      {IconData? icon}) {
    return DropdownButtonFormField(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: _inputDecoration(label, fontFamily, icon),
      style: TextStyle(color: Colors.black, fontFamily: fontFamily),
      validator: (val) => val == null ? 'required_field'.tr() : null,
    );
  }

  InputDecoration _inputDecoration(String label, String fontFamily, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: fontFamily),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF4B2E2B)) : null,
      filled: true,
      fillColor: Colors.brown[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}


