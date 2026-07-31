import { readFileSync } from 'node:fs';
import { after, before, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

/**
 * Security rules tests for HamweTrip.
 *
 * These matter more than usual on this project: Cloud Functions are not
 * available, so every write is made by a client and the rules are the only
 * thing standing between a member and someone else's data.
 */

const TRIP = 't_nyungwe';
const ORGANIZER = 'u_aline';
const MEMBER = 'u_eric';
const OUTSIDER = 'u_jean';
const CODE = 'HAMWE7';

const future = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
const past = new Date(Date.now() - 24 * 60 * 60 * 1000);

let testEnv;

const asOrganizer = () => testEnv.authenticatedContext(ORGANIZER).firestore();
const asMember = () => testEnv.authenticatedContext(MEMBER).firestore();
const asOutsider = () => testEnv.authenticatedContext(OUTSIDER).firestore();
const asAnonymous = () => testEnv.unauthenticatedContext().firestore();

function memberDoc(uid, role, code = null) {
  return {
    uid,
    role,
    displayName: `User ${uid}`,
    photoUrl: null,
    joinedAt: new Date(),
    balanceMinor: null,
    joinedWithCode: code,
  };
}

function inviteDoc(overrides = {}) {
  return {
    tripId: TRIP,
    createdBy: ORGANIZER,
    maxUses: 5,
    usedCount: 0,
    revoked: false,
    createdAt: new Date(),
    expiresAt: future,
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-hamwetrip',
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

/** Reseeds a trip with an organizer, one member, and one live invite. */
async function seed() {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'trips', TRIP), {
      name: 'Nyungwe National Park',
      destination: 'Rwanda',
      ownerId: ORGANIZER,
      currency: 'RWF',
      status: 'planning',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await setDoc(
      doc(db, 'trips', TRIP, 'members', ORGANIZER),
      memberDoc(ORGANIZER, 'organizer'),
    );
    await setDoc(
      doc(db, 'trips', TRIP, 'members', MEMBER),
      memberDoc(MEMBER, 'member', CODE),
    );
    await setDoc(doc(db, 'invites', CODE), inviteDoc());
    await setDoc(doc(db, 'users', ORGANIZER), {
      displayName: 'Aline Uwase',
      email: 'aline@example.com',
      phone: '0788123456',
      notificationsEnabled: true,
    });
  });
}

describe('trips', () => {
  test('a member can read the trip', async () => {
    await seed();
    await assertSucceeds(getDoc(doc(asMember(), 'trips', TRIP)));
  });

  test('a non-member cannot read the trip', async () => {
    await seed();
    await assertFails(getDoc(doc(asOutsider(), 'trips', TRIP)));
  });

  test('an anonymous user cannot read the trip', async () => {
    await seed();
    await assertFails(getDoc(doc(asAnonymous(), 'trips', TRIP)));
  });

  test('only an organizer can edit trip settings', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asOrganizer(), 'trips', TRIP), { name: 'Renamed' }),
    );
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP), { name: 'Hijacked' }),
    );
  });

  test('ownership cannot be reassigned by a field edit', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOrganizer(), 'trips', TRIP), { ownerId: MEMBER }),
    );
  });

  test('trips cannot be deleted, only archived', async () => {
    await seed();
    await assertFails(deleteDoc(doc(asOrganizer(), 'trips', TRIP)));
    await assertSucceeds(
      updateDoc(doc(asOrganizer(), 'trips', TRIP), { status: 'archived' }),
    );
  });

  test('a creator cannot read their trip before creating it', async () => {
    await seed();
    // Regression guard. An idempotency pre-check that reads trips/{requestId}
    // before writing is denied for the very person about to create it —
    // `allow get` needs isMember(tripId), and nobody is a member yet. A
    // createTrip built on such a read can never create anything.
    await assertFails(getDoc(doc(asOutsider(), 'trips', 't_not_yet')));
  });

  test('creating a trip and its organizer membership in one batch works', async () => {
    await seed();
    // Rules evaluate each write against the state from *before* the batch, so
    // the member document is created while its trip still does not exist.
    const db = asOutsider();
    const batch = writeBatch(db);
    batch.set(doc(db, 'trips', 't_new'), {
      name: 'Lake Kivu',
      destination: 'Rubavu',
      ownerId: OUTSIDER,
      currency: 'RWF',
      status: 'planning',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    batch.set(
      doc(db, 'trips', 't_new', 'members', OUTSIDER),
      memberDoc(OUTSIDER, 'organizer'),
    );
    await assertSucceeds(batch.commit());
  });

  test('a trip cannot be created naming someone else as owner', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asOutsider(), 'trips', 't_forged'), {
        name: 'Forged',
        destination: 'Nowhere',
        ownerId: ORGANIZER,
        currency: 'RWF',
        status: 'planning',
      }),
    );
  });
});

describe('users', () => {
  test('a user can read their own profile', async () => {
    await seed();
    await assertSucceeds(getDoc(doc(asOrganizer(), 'users', ORGANIZER)));
  });

  test('a trip-mate cannot read another profile', async () => {
    await seed();
    // Names and photos come from the denormalized copies on member documents,
    // which keeps emails and phone numbers unreachable.
    await assertFails(getDoc(doc(asMember(), 'users', ORGANIZER)));
  });

  test('the user collection cannot be enumerated', async () => {
    await seed();
    await assertFails(getDocs(collection(asOrganizer(), 'users')));
  });

  test('a user cannot change the email their account is keyed on', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOrganizer(), 'users', ORGANIZER), {
        email: 'someone-else@example.com',
      }),
    );
  });
});

describe('membership', () => {
  test('members can list the roster', async () => {
    await seed();
    await assertSucceeds(
      getDocs(collection(asMember(), 'trips', TRIP, 'members')),
    );
  });

  test('a non-member cannot list the roster', async () => {
    await seed();
    await assertFails(
      getDocs(collection(asOutsider(), 'trips', TRIP, 'members')),
    );
  });

  test('a member cannot promote themselves', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asMember(), 'trips', TRIP, 'members', MEMBER), {
        role: 'organizer',
      }),
    );
  });

  test('a member can refresh their own denormalized name', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asMember(), 'trips', TRIP, 'members', MEMBER), {
        displayName: 'Eric H.',
      }),
    );
  });

  test('an organizer can change roles', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asOrganizer(), 'trips', TRIP, 'members', MEMBER), {
        role: 'editor',
      }),
    );
  });

  test('a member cannot remove someone else', async () => {
    await seed();
    await assertFails(
      deleteDoc(doc(asMember(), 'trips', TRIP, 'members', ORGANIZER)),
    );
  });

  test('a member can leave, and an organizer can remove them', async () => {
    await seed();
    await assertSucceeds(
      deleteDoc(doc(asMember(), 'trips', TRIP, 'members', MEMBER)),
    );
    await seed();
    await assertSucceeds(
      deleteDoc(doc(asOrganizer(), 'trips', TRIP, 'members', MEMBER)),
    );
  });

  test('a leave event cannot be filed after the membership is gone', async () => {
    await seed();
    const db = asMember();
    await assertSucceeds(deleteDoc(doc(db, 'trips', TRIP, 'members', MEMBER)));
    // Regression guard: the activity rule needs isMember(tripId), which a
    // departing member no longer satisfies. leaveTrip must enlist the event in
    // the same transaction as the delete, where both are evaluated against the
    // state from before the commit.
    await assertFails(
      setDoc(doc(db, 'trips', TRIP, 'activity', 'leave1'), {
        type: 'member_removed',
        actorId: MEMBER,
        actorName: 'Eric',
        summary: 'Eric left the trip',
        entityId: MEMBER,
        createdAt: new Date(),
      }),
    );
  });

  test('a leave event and the delete succeed together in one transaction', async () => {
    await seed();
    const db = asMember();
    const batch = writeBatch(db);
    batch.set(doc(db, 'trips', TRIP, 'activity', 'leave2'), {
      type: 'member_removed',
      actorId: MEMBER,
      actorName: 'Eric',
      summary: 'Eric left the trip',
      entityId: MEMBER,
      createdAt: new Date(),
    });
    batch.delete(doc(db, 'trips', TRIP, 'members', MEMBER));
    await assertSucceeds(batch.commit());
  });

  test('watchMyTrips: the collection-group query is allowed when scoped to self', async () => {
    await seed();
    const db = asMember();
    await assertSucceeds(
      getDocs(
        query(collectionGroup(db, 'members'), where('uid', '==', MEMBER)),
      ),
    );
  });

  test('an unscoped collection-group query over members is refused', async () => {
    await seed();
    // Otherwise it would enumerate the membership of every trip in the system.
    await assertFails(getDocs(collectionGroup(asMember(), 'members')));
  });

  test('a collection-group query scoped to someone else is refused', async () => {
    await seed();
    const db = asMember();
    await assertFails(
      getDocs(
        query(collectionGroup(db, 'members'), where('uid', '==', ORGANIZER)),
      ),
    );
  });
});

describe('joining with an invite', () => {
  test('a valid code lets an outsider write their own membership', async () => {
    await seed();
    await assertSucceeds(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'member', CODE),
      ),
    );
  });

  test('joining with no code at all is refused', async () => {
    await seed();
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'member', null),
      ),
    );
  });

  test('an expired code is refused', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'invites', CODE),
        inviteDoc({ expiresAt: past }),
      );
    });
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'member', CODE),
      ),
    );
  });

  test('a revoked code is refused', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'invites', CODE),
        inviteDoc({ revoked: true }),
      );
    });
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'member', CODE),
      ),
    );
  });

  test('an exhausted code is refused', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'invites', CODE),
        inviteDoc({ maxUses: 2, usedCount: 2 }),
      );
    });
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'member', CODE),
      ),
    );
  });

  test("a code for a different trip cannot buy entry to this one", async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'invites', 'OTHER1'),
        inviteDoc({ tripId: 't_somewhere_else' }),
      );
    });
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'member', 'OTHER1'),
      ),
    );
  });

  test('joining cannot smuggle in an organizer role', async () => {
    await seed();
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(OUTSIDER, 'organizer', CODE),
      ),
    );
  });

  test('a membership cannot be written on behalf of someone else', async () => {
    await seed();
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', 'u_someone'),
        memberDoc('u_someone', 'member', CODE),
      ),
    );
  });

  test('the uid field must match the document id', async () => {
    await seed();
    // Otherwise a forged uid field would make the collection-group query — and
    // the rule that guards it — point at the wrong person.
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'members', OUTSIDER),
        memberDoc(ORGANIZER, 'member', CODE),
      ),
    );
  });
});

describe('invites', () => {
  test('any signed-in user can fetch one invite by exact code', async () => {
    await seed();
    await assertSucceeds(getDoc(doc(asOutsider(), 'invites', CODE)));
  });

  test('the invite collection cannot be enumerated', async () => {
    await seed();
    // An unscoped list would turn this into a directory of every trip.
    await assertFails(getDocs(collection(asOutsider(), 'invites')));
    await assertFails(getDocs(collection(asOrganizer(), 'invites')));
  });

  test('an organizer can list the codes for their own trip', async () => {
    await seed();
    // Backs watchInvites() on the invite screen.
    await assertSucceeds(
      getDocs(
        query(
          collection(asOrganizer(), 'invites'),
          where('tripId', '==', TRIP),
          where('revoked', '==', false),
        ),
      ),
    );
  });

  test('a plain member cannot list invite codes', async () => {
    await seed();
    await assertFails(
      getDocs(query(collection(asMember(), 'invites'), where('tripId', '==', TRIP))),
    );
  });

  test('an organizer cannot list another trip\'s codes', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'invites', 'OTHER2'),
        inviteDoc({ tripId: 't_not_mine' }),
      );
    });
    await assertFails(
      getDocs(
        query(collection(asOrganizer(), 'invites'), where('tripId', '==', 't_not_mine')),
      ),
    );
  });

  test('only an organizer can create an invite', async () => {
    await seed();
    await assertSucceeds(
      setDoc(doc(asOrganizer(), 'invites', 'NEWONE'), inviteDoc()),
    );
    await assertFails(
      setDoc(doc(asMember(), 'invites', 'MEMBR1'), inviteDoc()),
    );
  });

  test('an invite cannot be created pre-used', async () => {
    await seed();
    await assertFails(
      setDoc(
        doc(asOrganizer(), 'invites', 'PREUSD'),
        inviteDoc({ usedCount: 4 }),
      ),
    );
  });

  test('a joiner may increment usedCount by exactly one', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asOutsider(), 'invites', CODE), { usedCount: 1 }),
    );
  });

  test('a joiner cannot rewind or inflate the counter', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOutsider(), 'invites', CODE), { usedCount: 0 }),
    );
    await assertFails(
      updateDoc(doc(asOutsider(), 'invites', CODE), { usedCount: 99 }),
    );
  });

  test('a joiner cannot extend the expiry while claiming a use', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asOutsider(), 'invites', CODE), {
        usedCount: 1,
        expiresAt: new Date(Date.now() + 999 * 24 * 60 * 60 * 1000),
      }),
    );
  });

  test('an organizer can revoke', async () => {
    await seed();
    await assertSucceeds(
      updateDoc(doc(asOrganizer(), 'invites', CODE), { revoked: true }),
    );
  });

  test('a member cannot revoke', async () => {
    await seed();
    await assertFails(
      updateDoc(doc(asMember(), 'invites', CODE), { revoked: true }),
    );
  });

  test('invites cannot be deleted', async () => {
    await seed();
    await assertFails(deleteDoc(doc(asOrganizer(), 'invites', CODE)));
  });
});

describe('activity', () => {
  const event = (actorId) => ({
    type: 'expense_added',
    actorId,
    actorName: 'Someone',
    summary: 'Someone added an expense',
    entityId: 'e1',
    createdAt: new Date(),
  });

  test('a member can file an event naming themselves', async () => {
    await seed();
    await assertSucceeds(
      setDoc(doc(asMember(), 'trips', TRIP, 'activity', 'a1'), event(MEMBER)),
    );
  });

  test('a member cannot file an event as someone else', async () => {
    await seed();
    await assertFails(
      setDoc(doc(asMember(), 'trips', TRIP, 'activity', 'a2'), event(ORGANIZER)),
    );
  });

  test('a non-member cannot file or read events', async () => {
    await seed();
    await assertFails(
      setDoc(
        doc(asOutsider(), 'trips', TRIP, 'activity', 'a3'),
        event(OUTSIDER),
      ),
    );
    await assertFails(
      getDocs(collection(asOutsider(), 'trips', TRIP, 'activity')),
    );
  });

  test('history is append-only', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'trips', TRIP, 'activity', 'a4'),
        event(MEMBER),
      );
    });
    await assertFails(
      updateDoc(doc(asOrganizer(), 'trips', TRIP, 'activity', 'a4'), {
        summary: 'Rewritten',
      }),
    );
    await assertFails(
      deleteDoc(doc(asOrganizer(), 'trips', TRIP, 'activity', 'a4')),
    );
  });
});

// Polls, expenses, balances, payments, itinerary and documents used to be
// denied here as unimplemented placeholders. They are now live, and their rules
// are covered in trip-content.test.js.
