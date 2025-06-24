class Utils {
  static const String baseUrl = 'http://182.93.94.210:3066';

  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('http://') || url.startsWith('https://')) return true;
    if (url.startsWith('/')) return true;
    return false;
  }

  static String getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }
}