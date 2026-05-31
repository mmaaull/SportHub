class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }

    final emailRegex = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.trim().length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  static String? nim(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIM wajib diisi';
    }

    if (value.trim().length < 8) {
      return 'NIM minimal 8 digit';
    }

    return null;
  }

  static String? number(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return '$fieldName harus berupa angka';
    }

    if (number <= 0) {
      return '$fieldName harus lebih dari 0';
    }

    return null;
  }

  static String? time(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }

    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

    if (!timeRegex.hasMatch(value.trim())) {
      return 'Format $fieldName harus HH:mm, contoh 07:00';
    }

    return null;
  }
}