import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/data/mock/mock_poll_repository.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/controllers/demo_voting_controller.dart';

void main() {
  late MockPollRepository repository;
  late DemoVotingController controller;

  setUp(() {
    repository = MockPollRepository();
    controller = DemoVotingController(
      repository: repository,
      voterInitials: 'ME',
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('DemoVotingController', () {
    test('initial load should have 4 polls (3 active, 1 inactive)', () async {
      // Allow the stream to emit.
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.polls.length, 4);
      expect(controller.activePollCount, 3);
      expect(controller.closedPollCount, 1);
    });

    test('single-choice selection is pending until submitted', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_1', 'p1_o2');

      expect(controller.hasVoted('poll_1'), false);

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_1');
      expect(state.isOptionSelected('p1_o2'), true);
      expect(state.voteCountFor('p1_o2'), 3);

      final success = await controller.submitVote('poll_1');
      expect(success, true);
      expect(controller.hasVoted('poll_1'), true);
    });

    test('single-choice re-vote should deselect previous option', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_1', 'p1_o1');
      controller.selectOption('poll_1', 'p1_o2');

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_1');

      expect(state.isOptionSelected('p1_o1'), false);
      expect(state.voteCountFor('p1_o1'), 2);

      expect(state.isOptionSelected('p1_o2'), true);
      expect(state.voteCountFor('p1_o2'), 3);
    });

    test('multi-choice should allow selecting multiple options', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_2', 'p2_o1');
      controller.selectOption('poll_2', 'p2_o3');

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_2');

      expect(state.isOptionSelected('p2_o1'), true);
      expect(state.voteCountFor('p2_o1'), 4);

      expect(state.isOptionSelected('p2_o3'), true);
      expect(state.voteCountFor('p2_o3'), 3);

      expect(state.isOptionSelected('p2_o4'), false);
      expect(state.voteCountFor('p2_o4'), 2);
    });

    test('multi-choice toggle should deselect option', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_2', 'p2_o1');
      controller.selectOption('poll_2', 'p2_o1');

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_2');
      expect(state.isOptionSelected('p2_o1'), false);
      expect(state.voteCountFor('p2_o1'), 4);
    });

    test('inactive poll (isActive: false) should reject votes', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_3', 'p3_o1');

      expect(controller.hasVoted('poll_3'), false);
      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_3');
      expect(state.voteCountFor('p3_o1'), 4);
    });

    test('closePoll should update counts', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.closePoll('poll_4');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.activePollCount, 2);
      expect(controller.closedPollCount, 2);
    });

    test('deletePoll should remove it from the list', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.deletePoll('poll_4');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.polls.length, 3);
      expect(controller.polls.any((s) => s.poll.id == 'poll_4'), false);
    });

    test('search should filter polls by question', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.search('date');
      expect(controller.polls.length, 1);
      expect(controller.polls.first.poll.question.contains('date'), true);
    });

    test('search should filter polls by category', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.search('budget');
      expect(controller.polls.length, 1);
      expect(controller.polls.first.poll.category, 'Budget');
    });

    test('clearSearch should restore all polls', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.search('date');
      expect(controller.polls.length, 1);
      controller.clearSearch();
      expect(controller.polls.length, 4);
    });

    test('getVotePercentage should calculate correctly', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_1', 'p1_o2');
      await controller.submitVote('poll_1');
      await Future.delayed(const Duration(milliseconds: 10));
      final pct = controller.getVotePercentage('poll_1', 'p1_o2');
      expect(pct, closeTo(57.14, 0.01));
    });

    test('submitted votes cannot be changed or submitted twice', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.selectOption('poll_1', 'p1_o1');
      expect(await controller.submitVote('poll_1'), true);

      controller.selectOption('poll_1', 'p1_o2');
      expect(await controller.submitVote('poll_1'), false);

      final state = controller.polls.firstWhere((s) => s.poll.id == 'poll_1');
      expect(state.isOptionSelected('p1_o1'), true);
      expect(state.isOptionSelected('p1_o2'), false);
    });
  });
}
