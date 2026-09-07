import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Debug-only DEMO EMPLOYEE seeder (PRD §48).
///
/// IMPORTANT — WHY THIS TOOL ONLY CREATES EMPLOYEES:
/// Per firestore.rules, a client can only ever create its OWN user
/// profile, and only with role == 'employee' (PRD §6, §44 — no
/// self-elevation to supervisor, no arbitrary client writes to
/// `wards`). That is a deliberate security boundary, not an oversight,
/// so this tool does not attempt to create the supervisor account,
/// wards, or demo task/issue records — those legitimately require
/// elevated (Admin SDK) access and are seeded instead by
/// `scripts/seed_admin.js` (server-side, run once by you with a
/// service account — see README "Seed Data").
///
/// This tool creates two employee accounts, each in its own isolated
/// secondary FirebaseApp instance so creating them never disturbs the
/// primary app's auth session (creating a user via
/// `createUserWithEmailAndPassword` auto-signs the app in as that
/// user, which would otherwise tear down this very screen mid-run,
/// since AuthGate swaps the whole widget tree on sign-in).
///
/// Only ever wired up from a debug-mode-gated screen — see
/// lib/dev/seed_data_screen.dart — never shown in a release build.
class SeedDataTool {
  static const _secondaryAppName = 'wardclean-seed';

  /// Creates two demo employee accounts. Run `scripts/seed_admin.js`
  /// FIRST so the wards these employees reference already exist.
  /// Returns a human-readable log, including the generated login
  /// credentials — the ONLY time they are ever surfaced, so the caller
  /// must show/copy them immediately.
  Future<List<String>> run() async {
    final log = <String>[];

    final employees = [
      {
        'name': 'Demo Employee One',
        'id': 'EMP001',
        'ward': 'ward_02',
        'email': 'employee1@wardclean.demo',
      },
      {
        'name': 'Demo Employee Two',
        'id': 'EMP002',
        'ward': 'ward_01',
        'email': 'employee2@wardclean.demo',
      },
    ];

    for (final e in employees) {
      // Fresh secondary app per user: after createUserWithEmailAndPassword
      // the secondary app's auth is left signed in as that user, which is
      // fine because we immediately write that same user's own profile
      // document (satisfies the security rule: request.auth.uid == uid),
      // then tear the whole secondary app down before moving to the next.
      final app = await Firebase.initializeApp(
        name: '$_secondaryAppName-${e['id']}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      final db = FirebaseFirestore.instanceFor(app: app);
      const password = 'Password123!';

      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: e['email']!,
          password: password,
        );
        final uid = credential.user!.uid;

        await db.collection('users').doc(uid).set({
          'uid': uid,
          'name': e['name'],
          'email': e['email'],
          'employeeId': e['id'],
          'role': 'employee',
          'assignedWard': e['ward'],
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        log.add('Employee created: ${e['email']} / $password');
      } on FirebaseAuthException catch (ex) {
        if (ex.code == 'email-already-in-use') {
          log.add('${e['email']} already exists — skipping.');
        } else {
          log.add('Failed to create ${e['email']}: ${ex.message}');
        }
      } catch (ex) {
        log.add('Failed to create ${e['email']}: $ex');
      } finally {
        await auth.signOut();
        await app.delete();
      }
    }

    log.add('--- Done. Copy these credentials now — they will not be shown again. ---');
    log.add('For wards, the supervisor account, and demo task/issue records, '
        'run scripts/seed_admin.js instead (see README "Seed Data").');
    return log;
  }
}
