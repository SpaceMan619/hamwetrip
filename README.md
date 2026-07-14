# HamweTrip

HamweTrip is a mobile-first group travel coordination concept designed for friends planning road trips and safaris across East Africa. It brings trip decisions, shared itineraries, expense tracking, payment coordination, and offline travel documents into one connected experience.

This repository contains the user research, design system, high-fidelity interface renders, and browser-based prototype screens produced for an African Leadership University Mobile Application Development project.

## The problem

Group travel planning is commonly fragmented across WhatsApp conversations, mobile-money transfers, maps, booking PDFs, and spreadsheets. That fragmentation creates recurring problems:

- dates and accommodation choices get buried in chat;
- organizers carry most of the planning and financial workload;
- participants lack visibility into costs and payment status;
- important addresses, permits, and itineraries become inaccessible when connectivity drops;
- last-minute changes produce confusion and decision fatigue.

HamweTrip is designed as a single, transparent coordination hub for both organizers and participants.

## Core experience

- **Voting engine:** Group polls for destinations, dates, accommodation, and other shared decisions.
- **Shared travel ledger:** Transparent expense splitting and payment-status tracking without holding users' money.
- **Mobile-money coordination:** Clear MoMo payment instructions, manual confirmation, and organizer verification.
- **Collaborative itinerary:** A shared plan for activities, meeting points, transport, and schedule changes.
- **Offline document vault:** Cached permits, booking documents, addresses, and itineraries for low-connectivity travel.
- **Activity feed:** A readable history of trip updates, member activity, decisions, and payments.

## Design direction

The visual system is reliable, warm, and adventurous. Deep forest green communicates stability, sunset orange highlights energetic actions, and warm sand surfaces keep the interface grounded in its East African travel context. The prototype is mobile-first, uses an 8-pixel spacing rhythm, and prioritizes legibility, accessible touch targets, transparent system status, and offline awareness.

## Prototype coverage

The repository includes 15 interface renders covering:

1. Onboarding
2. Login and sign-up
3. Home feed
4. Trip dashboard
5. Trip creation
6. Member invitations
7. Group voting
8. Poll results
9. Expense splitting
10. Mobile-money payment summary
11. Settlement confirmation
12. Offline document vault
13. Detailed itinerary
14. Trip activity feed
15. Profile and settings

Fourteen screens also have standalone HTML prototypes. The design artifacts are being kept local until the team is ready to add them to the repository.

## Research foundation

The concept is informed by seven interviews with group travelers and organizers. The clearest shared need was one coordinated place for decisions, itinerary visibility, fair cost tracking, upfront estimates, and offline access.

The research produced two primary archetypes:

- **Eric Habimana — the organizer:** Coordinates the group, books transport, tracks contributions, and risks burning out before the trip begins.
- **Sandrine Uwase — the participant:** Wants to join with minimal planning overhead while still understanding the plan, expected cost, and fairness of the split.

The supporting research includes interview transcripts, persona source material, and final persona documents. These artifacts will be added after the team agrees on the repository structure.

## Team

| Member | Documented contribution |
| --- | --- |
| Rajveer Singh Jolly | Frontend development, frontend architecture, and UI design |
| Shakira | Frontend development and UI implementation |
| Kamanzi Gautier | Backend development, integration, and testing |
| Aime | Backend development, integration, and testing |

## Current status

HamweTrip is currently a researched product concept and high-fidelity prototype. This initial repository intentionally contains only this README. The next implementation phase is intended for a Flutter mobile application, beginning with the voting, shared-ledger, collaborative-itinerary, and offline-vault flows.

## Academic context

Created for the African Leadership University Mobile Application Development course, May 2026 term.

No open-source license has been granted. All rights are reserved by the project team.
