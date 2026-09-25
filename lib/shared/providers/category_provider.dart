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

  Future<void> updateCategory(Category category) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.updateCategory(category);
      return repository.getCategories();
    });
  }

  Future<void> reorderCategories(int oldIndex, int newIndex, List<Category> currentList) async {
    final List<Category> reorderedList = List.from(currentList);
    final item = reorderedList.removeAt(oldIndex);
    reorderedList.insert(newIndex, item);

    final updatedCategories = <Category>[];
    for (int i = 0; i < reorderedList.length; i++) {
      final cat = reorderedList[i];
      if (cat.sortOrder != i) {
        updatedCategories.add(
          Category(
            id: cat.id,
            name: cat.name,
            icon: cat.icon,
            type: cat.type,
            sortOrder: i,
            createdAt: cat.createdAt,
            updatedAt: cat.updatedAt,
            isSynced: cat.isSynced,
            deletedAt: cat.deletedAt,
          )
        );
      }
    }

    if (updatedCategories.isEmpty) return;

    // Optimistic UI update
    state = state.whenData((categories) {
      final newCategories = List<Category>.from(categories);
      for (var updatedCat in updatedCategories) {
        final index = newCategories.indexWhere((c) => c.id == updatedCat.id);
        if (index != -1) {
          newCategories[index] = updatedCat;
        }
      }
      newCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return newCategories;
    });

    // Persist to DB
    final repository = ref.read(categoryRepositoryProvider);
    await repository.updateCategoriesOrder(updatedCategories);
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(() {
      return CategoryNotifier();
    });
