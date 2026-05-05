String? requiredField(String? v, [String label = 'This field']) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  return null;
}

String? validateEmail(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Email is required';
  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!re.hasMatch(value)) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 8) return 'Use at least 8 characters';
  return null;
}

String? validatePositiveNumber(String? v, {bool allowEmpty = false, String label = 'Value'}) {
  if (v == null || v.trim().isEmpty) {
    return allowEmpty ? null : '$label is required';
  }
  final n = double.tryParse(v.trim());
  if (n == null) return '$label must be a number';
  if (n <= 0) return '$label must be positive';
  return null;
}

String? validateNonNegativeNumber(String? v, {bool allowEmpty = true, String label = 'Value'}) {
  if (v == null || v.trim().isEmpty) {
    return allowEmpty ? null : '$label is required';
  }
  final n = double.tryParse(v.trim());
  if (n == null) return '$label must be a number';
  if (n < 0) return '$label cannot be negative';
  return null;
}
