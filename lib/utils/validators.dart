class AppValidators {
  static String? requiredField(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? usernameOrEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username or email is required';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? registerNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Register number is required';
    }
    if (value.trim().length < 3) {
      return 'Please enter a valid register number';
    }
    return null;
  }

  static String? roomNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Room number is required';
    }
    return null;
  }

  static String? capacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Capacity is required';
    }
    final num = int.tryParse(value.trim());
    if (num == null || num <= 0) {
      return 'Capacity must be a positive number';
    }
    if (num > 20) {
      return 'Capacity cannot exceed 20 students per room';
    }
    return null;
  }
}
