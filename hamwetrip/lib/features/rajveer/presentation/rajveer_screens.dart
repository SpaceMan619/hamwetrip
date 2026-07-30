import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_routes.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/util/date_format.dart';
import '../../../core/util/error_feedback.dart';
import '../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../domain/models/activity_event.dart';
import '../../../domain/models/invite.dart';
import '../../activity/activity_providers.dart';
import '../../auth/auth_controller.dart';
import '../../home/home_providers.dart';
import '../../profile/profile_providers.dart';
import '../../trips/trip_providers.dart';

/// Reads the trip id a route was pushed with (see e.g.
/// `Navigator.pushNamed(AppRoutes.dashboard, arguments: tripId)`), for
/// screens declared in the static `routes` table rather than built with
/// constructor arguments.
String? _tripIdArgument(BuildContext context) =>
    ModalRoute.of(context)?.settings.arguments as String?;

class ScreenExplorer extends ConsumerWidget {
  const ScreenExplorer({super.key});

  static const _screens = [
    ('Onboarding', AppRoutes.onboarding, Icons.waving_hand_outlined),
    ('Login and sign-up', AppRoutes.login, Icons.login_rounded),
    ('Home feed', AppRoutes.home, Icons.home_rounded),
    ('Trip dashboard', AppRoutes.dashboard, Icons.map_outlined),
    ('Create trip', AppRoutes.createTrip, Icons.add_location_alt_outlined),
    ('Invite members', AppRoutes.inviteMembers, Icons.group_add_outlined),
    (
      'Activity feed',
      AppRoutes.activityFeed,
      Icons.notifications_active_outlined,
    ),
    ('Profile and settings', AppRoutes.profile, Icons.person_outline_rounded),

    // --- Shakira Trip Screens ---
    (
      'Detailed itinerary',
      AppRoutes.detailedItinerary,
      Icons.edit_calendar_outlined,
    ),
    ('Document vault', AppRoutes.documentVault, Icons.folder_shared_outlined),
    (
      'Expense splitting',
      AppRoutes.expenseSplitting,
      Icons.receipt_long_outlined,
    ),
    ('Group voting', AppRoutes.groupVoting, Icons.how_to_vote_outlined),
    ('MoMo summary', AppRoutes.momoSummary, Icons.phone_android_outlined),
    ('Poll results', AppRoutes.pollResults, Icons.poll_outlined),
    (
      'Settlement confirmation',
      AppRoutes.settlementConfirmation,
      Icons.check_circle_outline_rounded,
    ),
  ];

  /// Routes whose screen reads a trip id from the route arguments — see
  /// `_tripIdArgument`. Passing the signed-in user's most recent trip here
  /// means jumping straight to these from the explorer shows real data
  /// instead of the screen's "no trip" fallback.
  static const _tripScopedRoutes = {
    AppRoutes.dashboard,
    AppRoutes.inviteMembers,
    AppRoutes.activityFeed,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(myTripsControllerProvider);
    final tripId = switch (tripsState.view) {
      ViewData(:final data) when data.isNotEmpty => data.first.id,
      _ => null,
    };

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        decoration: const BoxDecoration(
          color: AppColors.warmSand,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .74,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Rajveer - screen explorer',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open any completed frontend flow without backend data.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                for (final screen in _screens)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.paleMint,
                      foregroundColor: AppColors.forest,
                      child: Icon(screen.$3),
                    ),
                    title: Text(
                      screen.$1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      screen.$2,
                      (route) => route.isFirst,
                      arguments: _tripScopedRoutes.contains(screen.$2)
                          ? tripId
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var _page = 0;

  static const _pages = [
    (
      'Plan together',
      'Turn the noisy group chat into a calm, shared travel plan.',
      Icons.route_rounded,
    ),
    (
      'Keep costs fair',
      'See every expense, contribution and Mobile Money request in one place.',
      Icons.account_balance_wallet_outlined,
    ),
    (
      'Travel with confidence',
      'Keep your itinerary and important documents ready, even when signal drops.',
      Icons.offline_bolt_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.login),
                  child: const Text('Skip'),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEAC97D), AppColors.forest],
                  ),
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Icon(page.$3, size: 118, color: Colors.white),
              ),
              const SizedBox(height: 38),
              Text(page.$1, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(page.$2, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Row(
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    width: _page == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == index ? AppColors.forest : AppColors.line,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _page == 2
                      ? Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.login)
                      : setState(() => _page++),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: Text(_page == 2 ? 'Get started' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  var _isSignUp = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final ok = _isSignUp
        ? await controller.signUp(
            email: email,
            password: password,
            displayName: _nameController.text.trim(),
          )
        : await controller.signIn(email: email, password: password);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }
    final view = ref.read(authControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showInfoSnackBar(context, 'Enter your email above first.');
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.sendPasswordReset(email: email);
    if (!mounted) return;
    if (ok) {
      showInfoSnackBar(context, 'Check $email for a reset link.');
    } else {
      final view = ref.read(authControllerProvider).view;
      if (view.error case final error?) showAppErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      authControllerProvider.select((state) => state.isSubmitting),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const _BrandMark(),
                const SizedBox(height: 42),
                Text(
                  _isSignUp ? 'Join the journey' : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Create an account to start planning together.'
                      : 'Sign in to see what your group is planning.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 30),
                if (_isSignUp)
                  _Field(
                    label: 'Full name',
                    hint: 'Your name',
                    icon: Icons.person_outline_rounded,
                    controller: _nameController,
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                _Field(
                  label: 'Email address',
                  hint: 'name@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  controller: _passwordController,
                  validator: (value) => value == null || value.length < 6
                      ? 'At least 6 characters'
                      : null,
                ),
                if (!_isSignUp) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isSubmitting ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isSignUp ? 'Create account' : 'Sign in'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : 'New to HamweTrip? Create an account',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolves which trip to show: the id the route was pushed with (Home's
/// active-trip card, Create Trip's success path, the dashboard's own Invite
/// and Activity tiles), or — when navigated to with no argument, as the
/// bottom navigation's "Trips" tab does — the signed-in user's most recent
/// trip.
class TripDashboardScreen extends ConsumerWidget {
  const TripDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeTripId = _tripIdArgument(context);
    if (routeTripId != null) return _TripDashboardBody(tripId: routeTripId);

    final tripsState = ref.watch(myTripsControllerProvider);
    return switch (tripsState.view) {
      ViewData(:final data) when data.isNotEmpty => _TripDashboardBody(
        tripId: data.first.id,
      ),
      ViewLoading() => const _DashboardScaffold(
        child: Center(child: CircularProgressIndicator()),
      ),
      _ => const _NoTripDashboard(),
    };
  }
}

class _TripDashboardBody extends ConsumerWidget {
  const _TripDashboardBody({required this.tripId});

  final String tripId;

  Future<void> _renameTrip(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename trip'),
        content: TextField(controller: nameController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (newName == null || newName.isEmpty || newName == currentName) return;
    if (!context.mounted) return;

    final ok = await ref
        .read(tripDetailsControllerProvider.notifier)
        .updateTrip(tripId: tripId, name: newName);
    if (!context.mounted || ok) return;
    final view = ref.read(tripDetailsControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripControllerProvider(tripId));
    if (tripState.view is ViewError<dynamic>) {
      final error = (tripState.view as ViewError<dynamic>).error;
      return _DashboardScaffold(
        child: _DashboardMessage(message: error.message),
      );
    }

    final trip = switch (tripState.view) {
      ViewData(:final data) => data,
      _ => null,
    };
    if (tripState.view is! ViewLoading && trip == null) {
      // Deleted, or the caller lost access — TripRepository.watchTrip's
      // contract says this reads the same as "no longer reachable", not as
      // still loading.
      return const _NoTripDashboard();
    }
    if (trip == null) {
      return const _DashboardScaffold(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final membersState = ref.watch(tripMembersControllerProvider(tripId));
    final travellerCount = switch (membersState.view) {
      ViewData(:final data) => data.length,
      _ => 0,
    };

    final membershipState = ref.watch(myMembershipControllerProvider(tripId));
    final isOrganizer = switch (membershipState.view) {
      ViewData(:final data) => data?.role.canManageMembership ?? false,
      _ => false,
    };

    return _ScreenScaffold(
      title: trip.name,
      subtitle:
          '${formatDateRange(trip.startDate, trip.endDate)}  •  '
          '$travellerCount ${travellerCount == 1 ? 'traveler' : 'travelers'}',
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      child: Column(
        children: [
          const _HeroPanel(
            title: 'The adventure is coming together',
            subtitle:
                'All your trip updates, decisions and next steps live here.',
            icon: Icons.park_outlined,
          ),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.group_add_outlined,
            title: 'Invite your group',
            note: travellerCount == 1
                ? 'Just you so far'
                : '$travellerCount people have joined',
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.inviteMembers, arguments: tripId),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.notifications_active_outlined,
            title: 'Trip activity',
            note: 'See what changed',
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.activityFeed, arguments: tripId),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.how_to_vote_outlined,
            title: 'Group voting',
            note: 'Make trip decisions together',
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.groupVoting, arguments: tripId),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.route_outlined,
            title: 'Detailed itinerary',
            note: 'See the plan day by day',
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.detailedItinerary, arguments: tripId),
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.edit_calendar_outlined,
              title: 'Edit trip details',
              note: 'Rename this trip',
              onTap: () => _renameTrip(context, ref, trip.name),
            ),
          ],
          const SizedBox(height: 26),
          const _SectionLabel('STATUS'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              trip.status.wire,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTripDashboard extends StatelessWidget {
  const _NoTripDashboard();

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold(
      child: _DashboardMessage(
        message:
            "You don't have a trip to show yet. Create one from the home "
            'screen, or ask an organizer for an invite code.',
      ),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      title: 'Trip dashboard',
      subtitle: 'Everything about this trip, in one place.',
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      child: child,
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.terrain_outlined, color: AppColors.forest, size: 36),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTimeRange? _dates;

  // Generated once when the form opens, not on each tap — see
  // TripRepository.createTrip's contract on requestId: repeating a create
  // with the same id must return the existing trip rather than making a
  // second one, which is what makes a double-tapped submit button safe.
  final _requestId = Uuid().v4();

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(createTripControllerProvider.notifier);
    final trip = await controller.create(
      name: _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      requestId: _requestId,
      startDate: _dates?.start,
      endDate: _dates?.end,
    );

    if (!mounted) return;
    if (trip != null) {
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.dashboard, arguments: trip.id);
      return;
    }
    final view = ref.read(createTripControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      createTripControllerProvider.select((state) => state.isSubmitting),
    );

    return _ScreenScaffold(
      title: 'Create a trip',
      subtitle:
          'Start with the essentials. Your group can shape the rest together.',
      showBackButton: false,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Trip name',
              hint: 'e.g. Lake Kivu Retreat',
              icon: Icons.luggage_outlined,
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Destination',
              hint: 'Where are you heading?',
              icon: Icons.location_on_outlined,
              controller: _destinationController,
            ),
            const SizedBox(height: 16),
            Text('Dates', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 7),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _dates == null
                    ? 'Choose travel dates'
                    : '${_dates!.start.day}/${_dates!.start.month} - ${_dates!.end.day}/${_dates!.end.month}',
              ),
              onPressed: () async {
                final dates = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 3),
                  initialDateRange: _dates,
                );
                if (dates != null) setState(() => _dates = dates);
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save trip details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InviteMembersScreen extends ConsumerStatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  ConsumerState<InviteMembersScreen> createState() =>
      _InviteMembersScreenState();
}

class _InviteMembersScreenState extends ConsumerState<InviteMembersScreen> {
  String? _lastGeneratedCode;

  Future<void> _generateCode(String tripId) async {
    final invite = await ref
        .read(inviteActionsControllerProvider.notifier)
        .create(tripId: tripId);
    if (!mounted) return;
    if (invite != null) {
      setState(() => _lastGeneratedCode = invite.code);
      return;
    }
    final view = ref.read(inviteActionsControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  Future<void> _revoke(String tripId, String code) async {
    final ok = await ref
        .read(inviteActionsControllerProvider.notifier)
        .revoke(tripId: tripId, code: code);
    if (!mounted) return;
    if (_lastGeneratedCode == code) setState(() => _lastGeneratedCode = null);
    if (!ok) {
      final view = ref.read(inviteActionsControllerProvider).view;
      if (view.error case final error?) showAppErrorSnackBar(context, error);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showInfoSnackBar(context, 'Code $code copied.');
  }

  @override
  Widget build(BuildContext context) {
    final tripId = _tripIdArgument(context);
    if (tripId == null) {
      return const _ScreenScaffold(
        title: 'Invite your people',
        subtitle: 'Open this from a trip to manage its invite codes.',
        child: SizedBox.shrink(),
      );
    }

    final membershipState = ref.watch(myMembershipControllerProvider(tripId));
    final isOrganizer = switch (membershipState.view) {
      ViewData(:final data) => data?.role.canManageMembership ?? false,
      _ => false,
    };

    final invitesState = ref.watch(tripInvitesControllerProvider(tripId));
    final isSubmitting = ref.watch(
      inviteActionsControllerProvider.select((state) => state.isSubmitting),
    );

    final invitesList = switch (invitesState.view) {
      ViewLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      ViewEmpty() => const Text(
        'No active invite codes yet.',
        style: TextStyle(color: AppColors.muted),
      ),
      ViewError(:final error) => Text(
        error.message,
        style: const TextStyle(color: AppColors.muted),
      ),
      ViewData(:final data) => Column(
        children: [
          for (final invite in data)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.paleMint,
                  foregroundColor: AppColors.forest,
                  child: Icon(Icons.confirmation_number_outlined),
                ),
                title: Text(
                  invite.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                subtitle: Text(
                  invite.maxUses == Invite.unlimitedUses
                      ? '${invite.usedCount} joined  •  no limit'
                      : '${invite.usedCount} of ${invite.maxUses} used',
                ),
                trailing: isOrganizer
                    ? IconButton(
                        onPressed: () => _revoke(tripId, invite.code),
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
        ],
      ),
    };

    return _ScreenScaffold(
      title: 'Invite your people',
      subtitle:
          'Everyone gets one shared view of the trip - decisions, plans and costs included.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastGeneratedCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share this code',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastGeneratedCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyCode(_lastGeneratedCode!),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (isOrganizer)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : () => _generateCode(tripId),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_link_rounded),
                label: const Text('Generate invite code'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                ),
              ),
            ),
          const SizedBox(height: 28),
          const _SectionLabel('ACTIVE INVITE CODES'),
          const SizedBox(height: 10),
          invitesList,
        ],
      ),
    );
  }
}

/// With a trip id in the route, shows that trip's activity
/// (`tripActivityControllerProvider`). Without one — reached from the bottom
/// navigation rather than a trip's dashboard — shows the merged cross-trip
/// feed (`myActivityControllerProvider`), which is the home-feed case task 6
/// asks for.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = _tripIdArgument(context);
    final activityState = tripId == null
        ? ref.watch(myActivityControllerProvider)
        : ref.watch(tripActivityControllerProvider(tripId));

    final content = switch (activityState.view) {
      ViewLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      ViewEmpty() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Nothing has happened here yet.',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      ViewError(:final error) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          error.message,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      ViewData(:final data) => Column(
        children: [for (final event in data) _ActivityRow(event: event)],
      ),
    };

    return _ScreenScaffold(
      title: tripId == null ? 'All activity' : 'Trip activity',
      subtitle:
          'A clear history of what changed and what needs your attention.',
      showBackButton: tripId != null,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      child: content,
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final ActivityEvent event;

  IconData get _icon => switch (event.type.entityKind) {
    ActivityEntityKind.trip => Icons.terrain_outlined,
    ActivityEntityKind.member => Icons.group_outlined,
    ActivityEntityKind.poll => Icons.how_to_vote_outlined,
    ActivityEntityKind.expense => Icons.account_balance_wallet_outlined,
    ActivityEntityKind.payment => Icons.payments_outlined,
    ActivityEntityKind.itinerary => Icons.edit_calendar_outlined,
    ActivityEntityKind.document => Icons.upload_file_outlined,
    ActivityEntityKind.none => Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final createdAt = event.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.paleMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.forest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.summary,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt == null ? 'Just now' : _relativeTime(createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().toUtc().difference(time.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  }
  return DateFormat('MMM d').format(time.toLocal());
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: nameController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (newName == null || newName.isEmpty || newName == currentName) return;
    if (!context.mounted) return;

    final ok = await ref
        .read(profileActionsControllerProvider.notifier)
        .updateProfile(displayName: newName);
    if (!context.mounted || ok) return;
    final view = ref.read(profileActionsControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final ok = await ref
        .read(profileActionsControllerProvider.notifier)
        .setNotificationsEnabled(enabled);
    if (!context.mounted || ok) return;
    final view = ref.read(profileActionsControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(profileActionsControllerProvider.notifier)
        .signOut();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    }
    final view = ref.read(profileActionsControllerProvider).view;
    if (view.error case final error?) showAppErrorSnackBar(context, error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = switch (profileState.view) {
      ViewData(:final data) => data,
      _ => null,
    };
    final isSubmitting = ref.watch(
      profileActionsControllerProvider.select((state) => state.isSubmitting),
    );

    final displayName = (profile?.displayName ?? '').trim().isNotEmpty
        ? profile!.displayName
        : 'Traveller';

    return _ScreenScaffold(
      title: 'Profile & settings',
      subtitle: 'Your travel identity, preferences and account controls.',
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.profile,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.forest,
            child: Text(
              profile?.initials ?? '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.email ?? '',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal details',
            note: 'Tap to edit your name',
            onTap: profile == null
                ? null
                : () => _editDisplayName(context, ref, profile.displayName),
          ),
          _NotificationsTile(
            enabled: profile?.notificationsEnabled ?? true,
            onChanged: profile == null
                ? null
                : (value) => _toggleNotifications(context, ref, value),
          ),
          const _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Language and region',
            note: 'English • Rwanda',
          ),
          const _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy and data',
            note: 'Control how your data is used',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : () => _signOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9A2424),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenScaffold extends StatelessWidget {
  const _ScreenScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = true,
    this.bottomNavigation,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;
  final Widget? bottomNavigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmSand,
        surfaceTintColor: Colors.transparent,
        leading: showBackButton
            ? IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigation,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      CircleAvatar(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        child: Icon(Icons.route_rounded),
      ),
      SizedBox(width: 10),
      Text(
        'HamweTrip',
        style: TextStyle(
          color: AppColors.forest,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.controller,
    this.validator,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator:
              validator ??
              (value) =>
                  value == null || value.trim().isEmpty ? 'Enter $label' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE6BF73), AppColors.forest],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 38),
        const SizedBox(height: 54),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white, height: 1.4),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.paleMint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.forest),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(note),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.muted,
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.note,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String note;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      leading: Icon(icon, color: AppColors.forest),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(note),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _NotificationsTile extends StatelessWidget {
  const _NotificationsTile({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: const Icon(
        Icons.notifications_none_rounded,
        color: AppColors.forest,
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Trip updates and payment reminders'),
      // No explicit active color: Material 3's default Switch already reads
      // colorScheme.primary, which AppTheme sets to AppColors.forest.
      trailing: Switch(value: enabled, onChanged: onChanged),
    ),
  );
}
