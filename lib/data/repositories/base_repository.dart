/// Base repository interface defining common CRUD operations.
///
/// This abstract class provides a contract for all repositories to follow,
/// ensuring consistent data access patterns across the application.
abstract class BaseRepository<T, ID> {
  /// Get all items
  Future<List<T>> getAll();

  /// Get a single item by its ID
  Future<T?> getById(ID id);

  /// Create a new item
  Future<T> create(T item);

  /// Update an existing item
  Future<T> update(T item);

  /// Delete an item by its ID
  Future<bool> delete(ID id);
}
