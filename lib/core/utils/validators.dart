class Validators {
  static String? validatePhilippinesPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final trimmedValue = value.trim();

    // Check if it starts with +63
    if (!trimmedValue.startsWith('+63')) {
      return 'Must start with +63';
    }

    // Remove +63 and check the rest
    final numberPart = trimmedValue.substring(3).trim();

    // Check if empty after prefix
    if (numberPart.isEmpty) {
      return 'Enter valid mobile number';
    }

    // Check if it starts with 9
    if (!numberPart.startsWith('9')) {
      return 'Must start with 9 (e.g. +63 9123456789)';
    }

    // Remove spaces for length check
    final cleanNumber = numberPart.replaceAll(' ', '');

    // Check length (should be 10 digits: 9xxxxxxxxx)
    if (cleanNumber.length != 10) {
      return 'Must be 10 digits (e.g. 9123456789)';
    }

    // Check if all characters are digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanNumber)) {
      return 'Must contain only digits';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Invalid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  static String? validateStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Invalid stock';
    }
    if (stock < 0) {
      return 'Stock cannot be negative';
    }
    return null;
  }
}
