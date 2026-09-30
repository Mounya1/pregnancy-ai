import 'package:flutter/foundation.dart';
import '../models/medical_report.dart';
import '../models/user_profile.dart';
import 'local_storage_service.dart';

/// Holds the single UserProfile used throughout the app, persisted to local
/// storage. Provided at the app root via ChangeNotifierProvider so any
/// screen can read the current profile or update it and have every other
/// screen (home header, chat requests, meal planner, nutrition targets)
/// stay in sync automatically.
class ProfileController extends ChangeNotifier {
  ProfileController(this._storage);

  final LocalStorageService _storage;
  UserProfile _profile = UserProfile();
  bool _loaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final stored = await _storage.loadProfile();
    if (stored != null) _profile = stored;
    _loaded = true;
    notifyListeners();
    // Reports uploaded before report notes existed count from the next launch
    // on, without the user having to upload them again.
    await refreshReportNotes();
  }

  /// Rebuilds [UserProfile.reportNotes] from the saved reports. Called after a
  /// report is added or deleted, so answers always reflect the current set.
  Future<void> refreshReportNotes() async {
    final notes = reportNotesFrom(await _storage.loadMedicalReports());
    if (listEquals(notes, _profile.reportNotes)) return;
    await update((profile) => profile.copyWith(reportNotes: notes));
  }

  Future<void> update(UserProfile Function(UserProfile current) updater) async {
    _profile = updater(_profile);
    notifyListeners();
    await _storage.saveProfile(_profile);
  }
}
