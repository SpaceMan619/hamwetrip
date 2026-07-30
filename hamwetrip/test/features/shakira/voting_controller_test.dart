import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/controllers/demo_voting_controller.dart';
import 'package:hamwetrip/features/shakira/data/demo/mock_polls.dart';

void main() {
  late DemoVotingController controller;

  setUp(() {
    controller = DemoVotingController();
  });

  group('DemoVotingController', () {
    test('initial load should have 4 polls (3 active, 1 inactive)', () {
      expect(controller.polls.length, mockPolls.length);
      // poll_3 has isActive: false, so it counts as closed initially
      expect(controller.activePollCount, 3);
      expect(controller.closedPollCount, 1);
    });

    test('single-choice vote should update state correctly', () {
      // poll_1 is single choice. "Friday afternoon" has 3 votes initially
      controller.vote('poll_1', 'p1_o2');

      expect(controller.hasVoted('poll_1'), true);

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_1');
      expect(state.isOptionSelected('p1_o2'), true);
      expect(state.voteCountFor('p1_o2'), 4); // 3 + 1
    });

    test('single-choice re-vote should deselect previous option', () {
      // "Friday morning" has 2 votes initially
      controller.vote('poll_1', 'p1_o1');
      // "Friday afternoon" has 3 votes initially
      controller.vote('poll_1', 'p1_o2');

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_1');

      // Morning should be deselected and back to 2
      expect(state.isOptionSelected('p1_o1'), false);
      expect(state.voteCountFor('p1_o1'), 2);

      // Afternoon should be selected and at 4
      expect(state.isOptionSelected('p1_o2'), true);
      expect(state.voteCountFor('p1_o2'), 4);
    });

    test('multi-choice should allow selecting multiple options', () {
      // poll_2 is multi-choice ("Select all that apply")
      controller.vote('poll_2', 'p2_o1'); // Market (4 votes)
      controller.vote('poll_2', 'p2_o3'); // Gorilla trekking (3 votes)

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_2');

      expect(state.isOptionSelected('p2_o1'), true);
      expect(state.voteCountFor('p2_o1'), 5); // 4 + 1

      expect(state.isOptionSelected('p2_o3'), true);
      expect(state.voteCountFor('p2_o3'), 4); // 3 + 1

      // Night life should be untouched
      expect(state.isOptionSelected('p2_o4'), false);
      expect(state.voteCountFor('p2_o4'), 2);
    });

    test('multi-choice toggle should deselect option', () {
      controller.vote('poll_2', 'p2_o1');
      controller.vote('poll_2', 'p2_o1'); // Toggle off

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_2');
      expect(state.isOptionSelected('p2_o1'), false);
      expect(state.voteCountFor('p2_o1'), 4); // Back to original
    });

    test('inactive poll (isActive: false) should reject votes', () {
      // poll_3 has isActive: false in mock data
      controller.vote('poll_3', 'p3_o1');

      expect(controller.hasVoted('poll_3'), false);
      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_3');
      expect(state.voteCountFor('p3_o1'), 4); // Unchanged
    });

    test('closePoll should update counts', () {
      controller.closePoll('poll_4');
      expect(controller.activePollCount, 2);
      expect(controller.closedPollCount, 2);
    });

    test('deletePoll should remove it from the list', () {
      controller.deletePoll('poll_4');
      expect(controller.polls.length, 3);
      expect(controller.polls.any((s) => s.poll.id == 'poll_4'), false);
    });

    test('search should filter polls by question', () {
      controller.search('date');
      expect(controller.polls.length, 1);
      expect(controller.polls.first.poll.question.contains('date'), true);
    });

    test('search should filter polls by category', () {
      controller.search('budget');
      expect(controller.polls.length, 1);
      expect(controller.polls.first.poll.category, 'Budget');
    });

    test('clearSearch should restore all polls', () {
      controller.search('date');
      expect(controller.polls.length, 1);
      controller.clearSearch();
      expect(controller.polls.length, 4);
    });

    test('getVotePercentage should calculate correctly', () {
      controller.vote('poll_1', 'p1_o2');
      // Total votes: 2 + 4 + 1 = 7. p1_o2 has 4. (4 / 7) * 100 = 57.14%
      final pct = controller.getVotePercentage('poll_1', 'p1_o2');
      expect(pct, closeTo(57.14, 0.01));
    });
  });
}
