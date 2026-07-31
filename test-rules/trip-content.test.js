import { readFileSync } from 'node:fs';
import { after, before, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

/**
 * Security rules for trip content: polls, expenses, balances, payments,
 * itinerary and documents.
 *
 * Every path and field below is taken from the matching repository in
 * lib/data/firebase, so these tests fail if the rules and the code drift apart.
 */

const TRIP = 't_nyungwe';
const OTHER_TRIP = 't_elsewhere';
const MEMBER = 'u_eric';
const OUTSIDER = 'u_jean';

let testEnv;

const asMember = () => testEnv.authenticatedContext(MEMBER).firestore();
const asOutsider = () => testEnv.authenticatedContext(OUTSIDER).firestore();

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-trip-content',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

/** A trip the member belongs to, plus one they do not, with content in each. */
async function seed() {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    for (const tripId of [TRIP, OTHER_TRIP]) {
      await setDoc(doc(db, 'trips', tripId), {
        name: 'Trip',
        destination: 'Rwanda',
        ownerId: MEMBER,
        currency: 'RWF',
        status: 'planning',
      });
      await setDoc(doc(db, 'trips', tripId, 'polls', 'p1'), {
        question: 'When do we leave?',
        options: [{ id: 'o1', label: 'Friday', voteCount: 0 }],
        voterInitials: [],
        isActive: true,
      });
      await setDoc(doc(db, 'trips', tripId, 'expenses', 'e1'), {
        description: 'Transport',
        amount: 5000,
        splitAmongInitials: ['AU', 'EH'],
        isSettled: false,
      });
      await setDoc(doc(db, 'trips', tripId, 'balances', 'b1'), {
        fromInitials: 'EH',
        toInitials: 'AU',
        amount: 2500,
      });
      await setDoc(doc(db, 'trips', tripId, 'payments', 'y1'), {
        amount: 2500,
        status: 'pending',
      });
      await setDoc(doc(db, 'trips', tripId, 'itinerary', 'd1'), {
        date: '2026-10-12',
        items: [{ id: 'i1', title: 'Arrive', isCompleted: false }],
      });
      await setDoc(doc(db, 'trips', tripId, 'documents', 'doc1'), {
        title: 'Booking confirmation',
        category: 'Travel',
      });
    }

    // The member belongs to TRIP only.
    await setDoc(doc(db, 'trips', TRIP, 'members', MEMBER), {
      uid: MEMBER,
      role: 'member',
      displayName: 'Eric Habimana',
      photoUrl: null,
      joinedAt: new Date(),
      balanceMinor: null,
      joinedWithCode: 'HAMWE7',
    });
  });
}

const collections = [
  'polls',
  'expenses',
  'balances',
  'payments',
  'itinerary',
  'documents',
];

describe('trip content is private to the trip', () => {
  for (const name of collections) {
    test(`a member can read ${name}`, async () => {
      await seed();
      await assertSucceeds(
        getDocs(collection(asMember(), 'trips', TRIP, name)),
      );
    });

    test(`a non-member cannot read ${name}`, async () => {
      await seed();
      await assertFails(
        getDocs(collection(asOutsider(), 'trips', TRIP, name)),
      );
    });

    test(`a member of one trip cannot read another trip's ${name}`, async () => {
      await seed();
      // The member belongs to TRIP, not OTHER_TRIP.
      await assertFails(
        getDocs(collection(asMember(), 'trips', OTHER_TRIP, name)),
      );
    });
  }
});

describe('polls', () => {
  test('a member can create a poll', async () => {
    await seed();
    await assertSucceeds(
      setDoc(doc(asMember(), 'trips', TRIP, 'polls', 'p2'), {
        question: 'Where do we eat?',
        options: [{ id: 'o1', label: 'Local', voteCount: 0 }],
        voterInitials: [],
        isActive: true,
      }),
    );
  });

  test('a poll without a question is refused', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asMember(), 'trips', TRIP, 'polls', 'p3'), {
        question: '',
        options: [],
        isActive: true,
      }),
    );
  });

  test('voting may move the tallies and the voter list', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asMember(), 'trips', TRIP, 'polls', 'p1'), {
        options: [{ id: 'o1', label: 'Friday', voteCount: 1 }],
        voterInitials: ['EH'],
      }),
    );
  });

  test('closing a poll may flip isActive', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asMember(), 'trips', TRIP, 'polls', 'p1'), {
        isActive: false,
      }),
    );
  });

  test('a voter cannot rewrite the question', async () => {
    await seed();
    // Otherwise somebody could change what everyone thought they voted on.
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP, 'polls', 'p1'), {
        question: 'Something else entirely',
      }),
    );
  });

  test('a non-member cannot vote', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOutsider(), 'trips', TRIP, 'polls', 'p1'), {
        voterInitials: ['JB'],
      }),
    );
  });
});

describe('expenses', () => {
  test('a member can record an expense', async () => {
    await seed();
    await assertSucceeds(
      setDoc(doc(asMember(), 'trips', TRIP, 'expenses', 'e2'), {
        description: 'Lunch',
        amount: 12000,
        splitAmongInitials: ['AU', 'EH'],
        isSettled: false,
      }),
    );
  });

  test('a negative amount is refused', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asMember(), 'trips', TRIP, 'expenses', 'e3'), {
        description: 'Refund',
        amount: -500,
        splitAmongInitials: [],
      }),
    );
  });

  test('an expense may be settled', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asMember(), 'trips', TRIP, 'expenses', 'e1'), {
        isSettled: true,
      }),
    );
  });

  test('an amount cannot be edited after the fact', async () => {
    await seed();
    // This is what keeps the ledger trustworthy once people have agreed on it.
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP, 'expenses', 'e1'), {
        amount: 999999,
      }),
    );
  });

  test('a non-member cannot record an expense', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asOutsider(), 'trips', TRIP, 'expenses', 'e4'), {
        description: 'Not mine to add',
        amount: 100,
        splitAmongInitials: [],
      }),
    );
  });
});

describe('balances', () => {
  test('a member can settle a balance by removing it', async () => {
    await seed();
    await assertSucceeds(
      deleteDoc(doc(asMember(), 'trips', TRIP, 'balances', 'b1')),
    );
  });

  test('a non-member cannot touch balances', async () => {
    await seed();
    await assertFails(
      deleteDoc(doc(asOutsider(), 'trips', TRIP, 'balances', 'b1')),
    );
  });
});

describe('payments', () => {
  test('a member can move a payment status', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asMember(), 'trips', TRIP, 'payments', 'y1'), {
        status: 'completed',
      }),
    );
  });

  test('the amount cannot be changed once recorded', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP, 'payments', 'y1'), {
        amount: 1,
      }),
    );
  });

  test('settlement history cannot be deleted', async () => {
    await seed();
    // Removing a payment would erase the evidence that somebody paid.
    await assertFails(
      deleteDoc(doc(asMember(), 'trips', TRIP, 'payments', 'y1')),
    );
  });

  test('a non-member cannot move a payment status', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOutsider(), 'trips', TRIP, 'payments', 'y1'), {
        status: 'completed',
      }),
    );
  });
});

describe('itinerary', () => {
  test('a member can edit the items of a day', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asMember(), 'trips', TRIP, 'itinerary', 'd1'), {
        items: [{ id: 'i1', title: 'Arrive', isCompleted: true }],
      }),
    );
  });

  test('the date of a day cannot be changed by an item edit', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP, 'itinerary', 'd1'), {
        date: '2027-01-01',
      }),
    );
  });

  test('a non-member cannot edit the itinerary', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOutsider(), 'trips', TRIP, 'itinerary', 'd1'), {
        items: [],
      }),
    );
  });
});

describe('documents', () => {
  test('a member can add and remove a document record', async () => {
    await seed();
    await assertSucceeds(
      setDoc(doc(asMember(), 'trips', TRIP, 'documents', 'doc2'), {
        title: 'Insurance',
        category: 'Travel',
      }),
    );
    await assertSucceeds(
      deleteDoc(doc(asMember(), 'trips', TRIP, 'documents', 'doc1')),
    );
  });

  test('a document without a title is refused', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asMember(), 'trips', TRIP, 'documents', 'doc3'), {
        title: '',
        category: 'Travel',
      }),
    );
  });

  test('a document record cannot be retitled', async () => {
    await seed();
    // Otherwise one member could silently rename another member's upload.
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP, 'documents', 'doc1'), {
        title: 'Renamed',
      }),
    );
  });

  test('a non-member cannot add a document', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asOutsider(), 'trips', TRIP, 'documents', 'doc4'), {
        title: 'Intruder',
        category: 'Travel',
      }),
    );
  });
});
