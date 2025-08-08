

extension StripHtml on String {
  String get stripHtml => replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
}