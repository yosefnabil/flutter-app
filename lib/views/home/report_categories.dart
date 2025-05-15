import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

List<Map<String, String>> reportCategories(BuildContext context) {
  final isArabic = context.locale.languageCode == 'ar';

  return [
    {'value': 'electronics', 'label': isArabic ? 'إلكترونيات' : 'Electronics'},
    {'value': 'documents', 'label': isArabic ? 'وثائق وبطاقات' : 'Documents & IDs'},
    {'value': 'jewelry', 'label': isArabic ? 'مجوهرات' : 'Jewelry'},
    {'value': 'clothes', 'label': isArabic ? 'ملابس' : 'Clothing'},
    {'value': 'bags', 'label': isArabic ? 'حقائب' : 'Bags'},
    {'value': 'watches', 'label': isArabic ? 'ساعات' : 'Watches'},
    {'value': 'glasses', 'label': isArabic ? 'نظارات' : 'Glasses'},
    {'value': 'money', 'label': isArabic ? 'نقود' : 'Money'},
    {'value': 'other', 'label': isArabic ? 'أخرى' : 'Other'},
  ];
}
