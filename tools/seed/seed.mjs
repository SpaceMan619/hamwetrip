/**
 * Fills the gaps the app cannot fill itself, for a demo trip in hamwetrip-dev.
 *
 * ## Why this exists at all
 *
 * The app creates its own accounts, trips, polls, expenses and documents. None
 * of that needs a script. Three collections are different: `payments`,
 * `balances` and the itinerary's day documents have no create method anywhere
 * in the repositories, so nothing in the interface can ever write them. On a
 * new trip those three screens render empty, which the old hardcoded sample
 * data used to hide.
 *
 * This script therefore does as little as possible. It signs in as an ordinary
 * user, finds the trip that user already has, and adds content. It creates an
 * account or a trip only if none exists yet, and says so when it does.
 *
 * It runs through the client SDK, not the Admin SDK, so every write is subject
 * to the same security rules as the app. No service account key is involved,
 * and a successful run is live evidence that the deployed rules permit what the
 * app needs.
 *
 * ## Usage
 *
 *     npm install
 *     npm run seed                  # uses the trip the account already has
 *     npm run seed -- <tripId>      # or target a specific trip
 *
 * Override the login with SEED_EMAIL and SEED_PASSWORD if you want a different
 * account.
 */

import { initializeApp } from 'firebase/app';
import {
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import {
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  query,
  serverTimestamp,
  setDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

// Client configuration, copied from hamwetrip/lib/firebase_options.dart. These
// are public identifiers rather than secrets; access is controlled by rules.
const firebaseConfig = {
  apiKey: 'AIzaSyBpTYAooYwM5EP4exMOl9yZk9V_SV9cveE',
  appId: '1:402708743076:android:6076144a233488479cf731',
  messagingSenderId: '402708743076',
  projectId: 'hamwetrip-dev',
};

const EMAIL = process.env.SEED_EMAIL ?? 'jotham@example.com';
const PASSWORD = process.env.SEED_PASSWORD ?? 'hamwe1234';
const DISPLAY_NAME = 'Jotham Rutijana';
const INITIALS = 'JR';
const PREFERRED_CODE = 'HAMWE7';

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

/** Signs in, creating the account only if it does not exist yet. */
async function signIn() {
  try {
    const cred = await signInWithEmailAndPassword(auth, EMAIL, PASSWORD);
    console.log(`Signed in as ${EMAIL}`);
    return { uid: cred.user.uid, created: false };
  } catch (error) {
    if (
      error.code === 'auth/user-not-found' ||
      error.code === 'auth/invalid-credential'
    ) {
      const cred = await createUserWithEmailAndPassword(auth, EMAIL, PASSWORD);
      console.log(`No such account, so created ${EMAIL}`);
      console.log('  (the app can do this itself from the sign up screen)');
      return { uid: cred.user.uid, created: true };
    }
    throw error;
  }
}

/**
 * Finds the trips this user belongs to, exactly the way the app does: a
 * collection group query over every `members` subcollection.
 */
async function findMyTrips(uid) {
  const snap = await getDocs(
    query(collectionGroup(db, 'members'), where('uid', '==', uid)),
  );
  return snap.docs.map((d) => d.ref.parent.parent.id);
}

async function createTrip(uid) {
  const tripRef = doc(collection(db, 'trips'));
  const batch = writeBatch(db);
  batch.set(tripRef, {
    name: 'Nyungwe National Park',
    destination: 'Rwanda',
    ownerId: uid,
    currency: 'RWF',
    status: 'planning',
    startDate: isoDay(14),
    endDate: isoDay(20),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  // The trip and the organizer's membership must land together: the rules only
  // allow the organizer branch of the membership create while the trip does not
  // yet exist, which is the state a batch is evaluated against.
  batch.set(doc(db, 'trips', tripRef.id, 'members', uid), {
    uid,
    role: 'organizer',
    displayName: DISPLAY_NAME,
    photoUrl: null,
    joinedAt: serverTimestamp(),
    balanceMinor: null,
    joinedWithCode: null,
  });
  await batch.commit();
  return tripRef.id;
}

/**
 * Makes sure there is a usable invite code for this trip.
 *
 * The preferred code may already exist and point at a different trip, from an
 * earlier run. The rules deliberately forbid rewriting an invite, so in that
 * case a fresh code is generated rather than forced.
 */
async function ensureInvite(tripId, uid) {
  const existing = await getDoc(doc(db, 'invites', PREFERRED_CODE));
  if (existing.exists()) {
    if (existing.data().tripId === tripId) return PREFERRED_CODE;
    console.log(
      `  ${PREFERRED_CODE} already points at another trip, generating a new code`,
    );
  }

  const code = existing.exists() ? randomCode() : PREFERRED_CODE;
  await setDoc(doc(db, 'invites', code), {
    tripId,
    createdBy: uid,
    maxUses: 5,
    usedCount: 0,
    revoked: false,
    createdAt: serverTimestamp(),
    expiresAt: null,
  });
  return code;
}

/** Six characters from an alphabet with no 0/O or 1/I/L to confuse anyone. */
function randomCode() {
  const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

/** Today plus [days], as the ISO string most models store. */
function isoDay(days = 0) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString();
}

/** Today plus [days], as the plain yyyy-mm-dd an itinerary day uses. */
function plainDay(days = 0) {
  return isoDay(days).slice(0, 10);
}

async function main() {
  const { uid, created } = await signIn();

  // Keep the profile document consistent whether the account came from the app
  // or from the branch above.
  await setDoc(
    doc(db, 'users', uid),
    {
      displayName: DISPLAY_NAME,
      email: EMAIL,
      phone: '0788123456',
      photoUrl: null,
      notificationsEnabled: true,
      ...(created ? { createdAt: serverTimestamp() } : {}),
    },
    { merge: true },
  );

  const requested = process.argv[2];
  let tripId = requested;

  if (!tripId) {
    const mine = await findMyTrips(uid);
    if (mine.length > 0) {
      tripId = mine[0];
      console.log(`Using the trip this account already has: ${tripId}`);
    } else {
      tripId = await createTrip(uid);
      console.log(`No trip on this account yet, so created ${tripId}`);
      console.log('  (the app can do this itself from the create trip screen)');
    }
  } else {
    console.log(`Using the trip you passed: ${tripId}`);
  }

  // Collected rather than written straight away, so existing documents can be
  // skipped below. Overwriting is not an option: the rules restrict updates to
  // the few fields each screen legitimately changes, so a blanket rewrite of an
  // existing poll or expense is correctly refused. Re-running therefore fills
  // gaps instead of clobbering, which also means it is safe to run twice.
  const writes = [];
  const batch = { set: (ref, data) => writes.push([ref, data]) };
  const sub = (name, id) => doc(db, 'trips', tripId, name, id);

  // ---------------------------------------------------------------------
  // The three collections nothing in the app can create. This is the part
  // that actually needs a script.
  // ---------------------------------------------------------------------

  batch.set(sub('balances', 'b_eric'), {
    fromInitials: 'EH',
    fromName: 'Eric Habimana',
    toInitials: INITIALS,
    toName: DISPLAY_NAME,
    amount: 17333,
  });
  batch.set(sub('balances', 'b_chantal'), {
    fromInitials: 'CM',
    fromName: 'Chantal Mukamana',
    toInitials: INITIALS,
    toName: DISPLAY_NAME,
    amount: 4667,
  });
  batch.set(sub('balances', 'b_jean'), {
    fromInitials: 'JB',
    fromName: 'Jean Bosco',
    toInitials: INITIALS,
    toName: DISPLAY_NAME,
    amount: 45000,
  });

  batch.set(sub('payments', 'y_eric'), {
    name: 'Eric Habimana',
    initials: 'EH',
    maskedPhone: '078X-XXX-567',
    amount: 17333,
    type: 'receive',
    status: 'pending',
  });
  batch.set(sub('payments', 'y_chantal'), {
    name: 'Chantal Mukamana',
    initials: 'CM',
    maskedPhone: '078X-XXX-891',
    amount: 4667,
    type: 'receive',
    status: 'completed',
  });
  batch.set(sub('payments', 'y_jean'), {
    name: 'Jean Bosco',
    initials: 'JB',
    maskedPhone: '078X-XXX-234',
    amount: 45000,
    type: 'receive',
    status: 'pending',
  });

  batch.set(sub('itinerary', 'd_one'), {
    dayTitle: 'Day 1, arrival',
    date: plainDay(14),
    items: [
      {
        id: 'i_depart',
        time: '07:00',
        title: 'Leave Kigali',
        location: 'Nyabugogo bus park',
        description: 'Minibus is booked, be there fifteen minutes early.',
        emoji: '🚌',
        type: 'transport',
        isCompleted: false,
      },
      {
        id: 'i_lunch',
        time: '12:30',
        title: 'Lunch stop in Huye',
        location: 'Huye town',
        description: 'Roughly an hour.',
        emoji: '🍽️',
        type: 'food',
        isCompleted: false,
      },
      {
        id: 'i_checkin',
        time: '16:00',
        title: 'Check in at the guesthouse',
        location: 'Gisakura',
        description: 'Two rooms booked under Jotham.',
        emoji: '🏠',
        type: 'activity',
        isCompleted: false,
      },
    ],
  });
  batch.set(sub('itinerary', 'd_two'), {
    dayTitle: 'Day 2, the forest',
    date: plainDay(15),
    items: [
      {
        id: 'i_canopy',
        time: '08:00',
        title: 'Canopy walk',
        location: 'Nyungwe canopy',
        description: 'Guide meets us at the visitor centre.',
        emoji: '🌉',
        type: 'activity',
        isCompleted: false,
      },
      {
        id: 'i_tea',
        time: '15:00',
        title: 'Tea plantation visit',
        location: 'Gisakura tea estate',
        description: 'Short walk from the guesthouse.',
        emoji: '🍵',
        type: 'activity',
        isCompleted: false,
      },
    ],
  });

  // ---------------------------------------------------------------------
  // The rest is optional. The app can create all of it, and doing so on
  // camera is the better demo. It is here so the screens are not bare
  // before you start.
  // ---------------------------------------------------------------------

  batch.set(sub('polls', 'p_departure'), {
    question: 'When should we leave Kigali?',
    category: 'Transport',
    categoryEmoji: '🚌',
    options: [
      { id: 'o1', label: 'Friday afternoon', emoji: '🌇', voteCount: 2 },
      { id: 'o2', label: 'Saturday morning', emoji: '🌅', voteCount: 1 },
      { id: 'o3', label: 'Saturday evening', emoji: '🌙', voteCount: 0 },
    ],
    totalMembers: 4,
    deadline: isoDay(3),
    isActive: true,
    voterInitials: ['EH', 'CM', 'JB'],
    createdBy: INITIALS,
  });
  batch.set(sub('polls', 'p_dinner'), {
    question: 'Where do we eat on the first night?',
    category: 'Food',
    categoryEmoji: '🍽️',
    options: [
      { id: 'o1', label: 'Guesthouse kitchen', emoji: '🏠', voteCount: 3 },
      { id: 'o2', label: 'Restaurant in town', emoji: '🍲', voteCount: 1 },
    ],
    totalMembers: 4,
    deadline: isoDay(-1),
    isActive: false,
    voterInitials: ['JR', 'EH', 'CM', 'JB'],
    createdBy: INITIALS,
  });

  batch.set(sub('expenses', 'e_transport'), {
    description: 'Minibus hire to Nyungwe',
    amount: 120000,
    paidByInitials: INITIALS,
    paidByName: DISPLAY_NAME,
    categoryEmoji: '🚌',
    category: 'Transport',
    splitAmongInitials: ['JR', 'EH', 'CM', 'JB'],
    date: isoDay(-2),
    isSettled: false,
    createdAt: serverTimestamp(),
  });
  batch.set(sub('expenses', 'e_groceries'), {
    description: 'Groceries for the guesthouse',
    amount: 38000,
    paidByInitials: 'EH',
    paidByName: 'Eric Habimana',
    categoryEmoji: '🛒',
    category: 'Food',
    splitAmongInitials: ['JR', 'EH', 'CM'],
    date: isoDay(-1),
    isSettled: false,
    createdAt: serverTimestamp(),
  });
  batch.set(sub('expenses', 'e_park'), {
    description: 'Park entry fees',
    amount: 60000,
    paidByInitials: 'CM',
    paidByName: 'Chantal Mukamana',
    categoryEmoji: '🎟️',
    category: 'Activity',
    splitAmongInitials: ['JR', 'EH', 'CM', 'JB'],
    date: isoDay(0),
    isSettled: false,
    createdAt: serverTimestamp(),
  });

  batch.set(sub('documents', 'doc_booking'), {
    title: 'Guesthouse booking confirmation',
    category: 'Accommodation',
    type: 'pdf',
    uploadedBy: DISPLAY_NAME,
    uploadedByInitials: INITIALS,
    fileSize: '248 KB',
    date: isoDay(-5),
    createdAt: serverTimestamp(),
  });
  batch.set(sub('documents', 'doc_permits'), {
    title: 'Park entry permits',
    category: 'Tickets',
    type: 'pdf',
    uploadedBy: 'Chantal Mukamana',
    uploadedByInitials: 'CM',
    fileSize: '1.1 MB',
    date: isoDay(-3),
    createdAt: serverTimestamp(),
  });
  batch.set(sub('documents', 'doc_insurance'), {
    title: 'Travel insurance',
    category: 'Insurance',
    type: 'image',
    uploadedBy: 'Eric Habimana',
    uploadedByInitials: 'EH',
    fileSize: '640 KB',
    date: isoDay(-2),
    createdAt: serverTimestamp(),
  });

  const missing = [];
  for (const [ref, data] of writes) {
    const snap = await getDoc(ref);
    if (!snap.exists()) missing.push([ref, data]);
  }

  if (missing.length === 0) {
    console.log('Everything was already present, nothing to write.');
  } else {
    const commit = writeBatch(db);
    for (const [ref, data] of missing) commit.set(ref, data);
    await commit.commit();
    console.log(
      `Wrote ${missing.length} document(s), skipped ${
        writes.length - missing.length
      } already present.`,
    );
  }

  const code = await ensureInvite(tripId, uid);

  console.log('');
  console.log('Seeded successfully.');
  console.log(`  trip id     ${tripId}`);
  console.log(`  sign in as  ${EMAIL} / ${PASSWORD}`);
  console.log(`  invite code ${code}`);
  console.log('');
  console.log('  Written because the app cannot: 3 balances, 3 payments,');
  console.log('  2 itinerary days.');
  console.log('  Written for convenience: 2 polls, 3 expenses, 3 documents,');
  console.log('  all of which the app can create itself on camera.');
  process.exit(0);
}

main().catch((error) => {
  console.error('');
  console.error('Seeding failed:', error.code ?? '', error.message ?? error);
  if (String(error).includes('permission-denied')) {
    console.error(
      'A permission error here means the deployed rules refuse something the ' +
        'app would also need. Check firestore.rules.',
    );
  }
  process.exit(1);
});
