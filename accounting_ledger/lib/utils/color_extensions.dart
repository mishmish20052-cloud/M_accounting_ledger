// lib/utils/color_extensions.dart
import 'dart:ui' as ui;

/// امتداد لإصلاح مشكلة الدالة `toARGB32` في إصدارات Flutter الأحدث.
extension ColorExtensions on ui.Color {
  /// تحويل لون Flutter (الذي قد يكون بصيغة wide-gamut) إلى عدد صحيح بصيغة 32-bit ARGB.
  int toARGB32() {
    // المعادلة المستخدمة: (alpha.toInt() << 24) | (red.toInt() << 16) | (green.toInt() << 8) | blue.toInt()
    // حيث النطاق الطبيعي لقيم alpha, red, green, blue هو 0.0 إلى 1.0.
    return (alpha.toInt() << 24) |
           (red.toInt() << 16) |
           (green.toInt() << 8) |
           blue.toInt();
  }
}
