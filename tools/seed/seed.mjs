/**
 * Seeds a demo trip in hamwetrip-dev with content for every screen.
 *
 * Three screens have no way to create their own records from the app: the MoMo
 * summary, the balances list and the itinerary all read data that nothing in
 * the interface writes. On a brand new trip they render empty. This script
 * fills them so a demo shows a populated app.
 *
 * It runs through the **client** SDK and signs in as an ordinary user, so
 * every write below is subject to the same security rules as the app. That is
 * deliberate: no service account key is needed, nothing secret is involved, and
 * a successful run is live proof that the deployed rules permit exactly what
 * the app needs.
 *
 * Usage, from this directory:
 *
 *   npm install
 *   npm run seed
 *
 * It prints the trip id it created. Sign into the app with the same account to
 * see it.
 */

import { initializeApp } from 'firebase/app';
import {
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import {
  collection,
  doc,
  getFirestore,
  serverTimestamp,
  setDoc,
  writeBatch,
} from 'firebase/firestore';

// Client configuration, copied from hamwetrip/lib/firebase_options.dart. These
// are public identifiers rather than secrets; access is controlled by the
// security rules.
const firebaseConfig = {
  apiKey: 'AIzaSyBpTYAooYwM5EP4exMOl9yZk9V_SV9cveE',
  appId: '1:402708743076:android:6076144a233488479cf731',
  messagingSenderId: '402708743076',
  projectId: 'hamwetrip-dev',
};

// The demo account. Change these if you want the seeded trip to belong to a
// different login.
const EMAIL = process.env.SEED_EMAIL ?? 'aline@example.com';
const PASSWORD = process.env.SEED_PASSWORD ?? 'hamwe1234';
const DISPLAY_NAME = 'Aline Uwase';
const INITIALS = 'AU';

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

/** Signs in, creating the account on first run. */
async function signIn() {
  try {
    const cred = await signInWithEmailAndPassword(auth, EMAIL, PASSWORD);
    console.log(`Signed in as ${EMAIL}`);
    return cred.user.uid;
  } catch (error) {
    if (
      error.code === 'auth/user-not-found' ||
      error.code === 'auth/invalid-credential'
    ) {
      const cred = await createUserWithEmailAndPassword(auth, EMAIL, PASSWORD);
      console.log(`Created account ${EMAIL}`);
      return cred.user.uid;
    }
    throw error;
  }
}

/** Today plus [days], as the ISO string the models store. */
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
  const uid = await signIn();

  // The profile document. signUp in the app does this; doing it here keeps the
  // seeded account consistent whether it was created by the app or by us.
  await setDoc(
    doc(db, 'users', uid),
    {
      displayName: DISPLAY_NAME,
      email: EMAIL,
      phone: '0788123456',
      photoUrl: null,
      notificationsEnabled: true,
      createdAt: serverTimestamp(),
    },
    { merge: true },
  );

  // The trip and its organizer membership go in one batch, matching what
  // createTrip does in the app. The rules only allow the organizer branch of
  // the membership create while the trip does not yet exist, which is exactly
  // the state a batch is evaluated against.
  const tripRef = doc(collection(db, 'trips'));
  const tripId = tripRef.id;

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
  batch.set(doc(db, 'trips', tripId, 'members', uid), {
    uid,
    role: 'organizer',
    displayName: DISPLAY_NAME,
    photoUrl: null,
    joinedAt: serverTimestamp(),
    balanceMinor: null,
    joinedWithCode: null,
  });
  await batch.commit();
  console.log(`Created trip ${tripId}`);

  const content = writeBatch(db);
  const sub = (name, id) => doc(db, 'trips', tripId, name, id);

  // Voting. One open poll with votes already on it, and one closed poll, so
  // both tabs have something in them.
  content.set(sub('polls', 'p_departure'), {
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
  content.set(sub('polls', 'p_dinner'), {
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
    voterInitials: ['AU', 'EH', 'CM', 'JB'],
    createdBy: INITIALS,
  });

  // Expenses.
  content.set(sub('expenses', 'e_transport'), {
    description: 'Minibus hire to Nyungwe',
    amount: 120000,
    paidByInitials: INITIALS,
    paidByName: DISPLAY_NAME,
    categoryEmoji: '🚌',
    category: 'Transport',
    splitAmongInitials: ['AU', 'EH', 'CM', 'JB'],
    date: isoDay(-2),
    isSettled: false,
    createdAt: serverTimestamp(),
  });
  content.set(sub('expenses', 'e_groceries'), {
    description: 'Groceries for the guesthouse',
    amount: 38000,
    paidByInitials: 'EH',
    paidByName: 'Eric Habimana',
    categoryEmoji: '🛒',
    category: 'Food',
    splitAmongInitials: ['AU', 'EH', 'CM'],
    date: isoDay(-1),
    isSettled: false,
    createdAt: serverTimestamp(),
  });
  content.set(sub('expenses', 'e_park'), {
    description: 'Park entry fees',
    amount: 60000,
    paidByInitials: 'CM',
    paidByName: 'Chantal Mukamana',
    categoryEmoji: '🎟️',
    category: 'Activity',
    splitAmongInitials: ['AU', 'EH', 'CM', 'JB'],
    date: isoDay(0),
    isSettled: false,
    createdAt: serverTimestamp(),
  });

  // Balances. Nothing in the app creates these, so the settlement view is
  // empty without them.
  content.set(sub('balances', 'b_eric'), {
    fromInitials: 'EH',
    fromName: 'Eric Habimana',
    toInitials: INITIALS,
    toName: DISPLAY_NAME,
    amount: 17333,
  });
  content.set(sub('balances', 'b_chantal'), {
    fromInitials: 'CM',
    fromName: 'Chantal Mukamana',
    toInitials: INITIALS,
    toName: DISPLAY_NAME,
    amount: 4667,
  });
  content.set(sub('balances', 'b_jean'), {
    fromInitials: 'JB',
    fromName: 'Jean Bosco',
    toInitials: INITIALS,
    toName: DISPLAY_NAME,
    amount: 45000,
  });

  // MoMo payments. Also never created by the app.
  content.set(sub('payments', 'y_eric'), {
    name: 'Eric Habimana',
    initials: 'EH',
    maskedPhone: '078X-XXX-567',
    amount: 17333,
    type: 'receive',
    status: 'pending',
  });
  content.set(sub('payments', 'y_chantal'), {
    name: 'Chantal Mukamana',
    initials: 'CM',
    maskedPhone: '078X-XXX-891',
    amount: 4667,
    type: 'receive',
    status: 'completed',
  });
  content.set(sub('payments', 'y_jean'), {
    name: 'Jean Bosco',
    initials: 'JB',
    maskedPhone: '078X-XXX-234',
    amount: 45000,
    type: 'receive',
    status: 'pending',
  });

  // Itinerary. createItem in the app needs a day that already exists, and
  // nothing creates days, so these two are what make that screen usable.
  content.set(sub('itinerary', 'd_one'), {
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
        description: 'Two rooms booked under Aline.',
        emoji: '🏠',
        type: 'activity',
        isCompleted: false,
      },
    ],
  });
  content.set(sub('itinerary', 'd_two'), {
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

  // Documents.
  content.set(sub('documents', 'doc_booking'), {
    title: 'Guesthouse booking confirmation',
    category: 'Accommodation',
    type: 'pdf',
    uploadedBy: DISPLAY_NAME,
    uploadedByInitials: INITIALS,
    fileSize: '248 KB',
    date: isoDay(-5),
    createdAt: serverTimestamp(),
  });
  content.set(sub('documents', 'doc_permits'), {
    title: 'Park entry permits',
    category: 'Tickets',
    type: 'pdf',
    uploadedBy: 'Chantal Mukamana',
    uploadedByInitials: 'CM',
    fileSize: '1.1 MB',
    date: isoDay(-3),
    createdAt: serverTimestamp(),
  });
  content.set(sub('documents', 'doc_insurance'), {
    title: 'Travel insurance',
    category: 'Insurance',
    type: 'image',
    uploadedBy: 'Eric Habimana',
    uploadedByInitials: 'EH',
    fileSize: '640 KB',
    date: isoDay(-2),
    createdAt: serverTimestamp(),
  });

  // An invite code, so joining from a second device can be demonstrated.
  await setDoc(doc(db, 'invites', 'HAMWE7'), {
    tripId,
    createdBy: uid,
    maxUses: 5,
    usedCount: 0,
    revoked: false,
    createdAt: serverTimestamp(),
    expiresAt: null,
  });

  await content.commit();

  console.log('');
  console.log('Seeded successfully.');
  console.log(`  trip id     ${tripId}`);
  console.log(`  sign in as  ${EMAIL} / ${PASSWORD}`);
  console.log('  invite code HAMWE7');
  console.log('');
  console.log('  2 polls, 3 expenses, 3 balances, 3 payments,');
  console.log('  2 itinerary days, 3 documents');
  process.exit(0);
}

main().catch((error) => {
  console.error('');
  console.error('Seeding failed:', error.code ?? '', error.message ?? error);
  if (String(error).includes('permission-denied')) {
    console.error(
      'A permission error here means the deployed rules do not allow ' +
        'something the app also needs. Check firestore.rules.',
    );
  }
  process.exit(1);
});
