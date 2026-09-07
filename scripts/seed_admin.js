/**
 * WardClean — Admin SDK seed script (PRD §48–49).
 *
 * This is the AUTHORITATIVE seeder. It runs server-side with a Firebase
 * service account, so it legitimately bypasses firestore.rules (Admin
 * SDK always does — that's how every Firebase project is meant to be
 * bootstrapped). It creates:
 *
 *   - 3 wards (Ward 1, Ward 2, Ward 3)
 *   - 1 supervisor account + Firestore profile
 *   - Demo Scenario 3 seed: 3 "Cleaning Quality" issues for
 *     Ward 2 / Room 5, so the Recurring Problem Area screen has
 *     something to show immediately.
 *
 * It deliberately does NOT create employee accounts (use the in-app
 * "Seed Demo Data" debug screen, or the normal registration screen, for
 * those — see README) and does NOT create the Scenario 1/2 demo task,
 * since those are meant to be created live through the app to actually
 * exercise the real-time flow (PRD §49).
 *
 * ------------------------------------------------------------------
 * ACTION REQUIRED FROM YOU before running this:
 *   1. In the Firebase Console: Project Settings → Service Accounts →
 *      "Generate new private key". Save the JSON file somewhere
 *      OUTSIDE this repo (never commit it).
 *   2. npm install firebase-admin   (from the project root)
 *   3. Run:
 *        GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json" \
 *        node scripts/seed_admin.js
 * ------------------------------------------------------------------
 *
 * Never commit a service account key. Never share it. This script
 * never asks you to paste one into chat/code — only to point the
 * GOOGLE_APPLICATION_CREDENTIALS environment variable at your own
 * local file.
 */

const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const auth = admin.auth();

function randomPassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  let out = '';
  for (let i = 0; i < 12; i++) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return out;
}

async function seedWards() {
  const wards = [
    { id: 'ward_01', wardName: 'Ward 1', floor: '1st Floor', description: 'General Ward' },
    { id: 'ward_02', wardName: 'Ward 2', floor: '2nd Floor', description: 'Surgical Ward' },
    { id: 'ward_03', wardName: 'Ward 3', floor: '3rd Floor', description: 'ICU' },
  ];

  for (const w of wards) {
    await db.collection('wards').doc(w.id).set({
      wardId: w.id,
      wardName: w.wardName,
      floor: w.floor,
      description: w.description,
      active: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Ward created: ${w.wardName}`);
  }
}

async function seedSupervisor() {
  const email = 'supervisor@wardclean.demo';
  const password = randomPassword();

  let userRecord;
  try {
    userRecord = await auth.createUser({ email, password });
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      console.log(`${email} already exists — skipping auth creation.`);
      userRecord = await auth.getUserByEmail(email);
    } else {
      throw err;
    }
  }

  await db.collection('users').doc(userRecord.uid).set({
    uid: userRecord.uid,
    name: 'Demo Supervisor',
    email,
    employeeId: 'SUP001',
    role: 'supervisor',
    assignedWard: 'ward_02',
    active: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Supervisor login: ${email} / ${password}`);
  console.log('(Copy this now — it will not be shown again.)');
  return userRecord.uid;
}

async function seedRecurringIssueDemo(reporterUid, reporterName) {
  for (let i = 0; i < 3; i++) {
    await db.collection('issues').add({
      wardId: 'ward_02',
      wardName: 'Ward 2',
      roomOrArea: 'Room 5',
      issueType: 'Cleaning Quality',
      description: `Cleaning quality issue reported during routine check #${i + 1}.`,
      reportedBy: reporterUid,
      reportedByName: reporterName,
      relatedTaskId: null,
      priority: 'medium',
      status: 'open',
      imageUrl: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedAt: null,
    });
  }
  console.log('3 recurring "Cleaning Quality" issues created for Ward 2 / Room 5.');
}

async function main() {
  console.log('Seeding WardClean demo data...\n');
  await seedWards();
  const supervisorUid = await seedSupervisor();
  await seedRecurringIssueDemo(supervisorUid, 'Demo Supervisor');

  console.log('\nDone. Next steps:');
  console.log('  1. Run the app and use "New employee? Create an account" to');
  console.log('     register 1-2 employees (or use the in-app debug seed screen).');
  console.log('  2. Log in as the supervisor above and create a real task via');
  console.log('     "Create Task" to walk through Demo Scenario 1/2 live.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed script failed:', err);
  process.exit(1);
});
