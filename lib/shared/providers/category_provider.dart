import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import 'repository_providers.dart';

import 'dart:async';

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  FutureOr<List<Category>> build() async {
    final repository = ref.read(categoryRepositoryProvider);
    return repository.getCategories();
  }

  Future<void> addCategory(Category category) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.addCategory(category);
      return repository.getCategories();
    });
  }

  Future<void> deleteCategory(String id) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.deleteCategory(id);
      return repository.getCategories();
    });
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(() {
      return CategoryNotifier();
    });
