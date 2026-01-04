import 'package:farmdashr/data/models/product/product.dart';

/// Extension for ProductCategory to provide UI-specific data.
extension ProductCategoryUI on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.vegetables:
        return 'Vegetables';
      case ProductCategory.fruits:
        return 'Fruits';
      case ProductCategory.bakery:
        return 'Bakery';
      case ProductCategory.dairy:
        return 'Dairy';
      case ProductCategory.meat:
        return 'Meat';
      case ProductCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.vegetables:
        return '🥕';
      case ProductCategory.fruits:
        return '🍎';
      case ProductCategory.bakery:
        return '🍞';
      case ProductCategory.dairy:
        return '🥛';
      case ProductCategory.meat:
        return '🥩';
      case ProductCategory.other:
        return '📦';
    }
  }
}
