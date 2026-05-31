import '../models/expansion_progress.dart';
import '../sources/mock_progress_source.dart';

abstract class ProgressRepository {
  Future<List<ExpansionProgress>> getProgress();
}

class MockProgressRepository implements ProgressRepository {
  @override
  Future<List<ExpansionProgress>> getProgress() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockProgressSource.getProgress();
  }
}
