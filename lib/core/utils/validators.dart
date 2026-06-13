class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email gerekli';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Geçerli bir email girin';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli';
    if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'Ad Soyad gerekli';
    if (value.trim().length < 2) return 'Geçerli bir isim girin';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName gerekli';
    return null;
  }
}
