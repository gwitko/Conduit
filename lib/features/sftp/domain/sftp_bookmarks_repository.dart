abstract class SftpBookmarksRepository {
  Future<List<String>> load(String hostId);

  Future<void> save(String hostId, List<String> paths);
}
