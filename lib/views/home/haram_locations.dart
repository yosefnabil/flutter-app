// haram_locations.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

List<String> getHaramLocations(BuildContext context) {
  final isArabic = context.locale.languageCode == 'ar';

  return isArabic
      ? [
    'صحن الطواف',
    'المسعى',
    'باب الملك عبدالعزيز',
    'باب الملك فهد',
    'باب السلام',
    'دور الميزانين',
    'الدور الأرضي',
    'الدور الأول',
    'الدور الثاني',
    'السطح',
    'الساحة الشمالية',
    'الساحة الجنوبية',
    'الساحة الغربية',
    'الساحة الشرقية',
    'المصاعد',
    'السلالم الكهربائية',
    'دورات المياه - رجال',
    'دورات المياه - نساء',
    'مكتبة الحرم',
    'مكتب التائهين',
    'قسم المفقودات',
    'مكتب الأمن',
    'ممر العربات',
    'مكان الصلاة - نساء',
    'مكان الصلاة - رجال',
    'مناطق الانتظار',
  ]
      : [
    'Tawaf Area',
    'Sa’i Area',
    'King Abdulaziz Gate',
    'King Fahd Gate',
    'Al-Salam Gate',
    'Mezzanine Floor',
    'Ground Floor',
    'First Floor',
    'Second Floor',
    'Rooftop',
    'North Yard',
    'South Yard',
    'West Yard',
    'East Yard',
    'Elevators',
    'Escalators',
    'Toilets - Men',
    'Toilets - Women',
    'Haram Library',
    'Lost Person Office',
    'Lost & Found',
    'Security Office',
    'Wheelchair Path',
    'Prayer Area - Women',
    'Prayer Area - Men',
    'Waiting Areas',
  ];
}
