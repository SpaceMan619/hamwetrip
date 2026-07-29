import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hamwe_bottom_navigation.dart';

class ScreenExplorer extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
                  const _Field(
                    label: 'Full name',
                    hint: 'Your name',
                    icon: Icons.person_outline_rounded,
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                const _Field(
                  label: 'Email address',
                  hint: 'name@email.com',
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 16),
                const _Field(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.home);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: Text(_isSignUp ? 'Create account' : 'Sign in'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
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

class TripDashboardScreen extends StatelessWidget {
  const TripDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      title: 'Nyungwe Weekend',
      subtitle: 'Oct 12 - Oct 18  •  4 travelers',
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
            note: '4 of 6 people have joined',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.inviteMembers),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.notifications_active_outlined,
            title: 'Trip activity',
            note: '3 new updates today',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.activityFeed),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.edit_calendar_outlined,
            title: 'Edit trip details',
            note: 'Destination, dates and group settings',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.createTrip),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('NEXT UP'),
          const SizedBox(height: 10),
          const _TimelineItem(
            time: '08:00 AM',
            title: 'Kigali to Nyungwe drive',
            detail: 'Meet at Kigali Convention Centre',
          ),
          const _TimelineItem(
            time: '12:30 PM',
            title: 'Lunch at lodge',
            detail: 'Rest and check-in together',
          ),
        ],
      ),
    );
  }
}

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTimeRange? _dates;

  @override
  Widget build(BuildContext context) {
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
            const _Field(
              label: 'Trip name',
              hint: 'e.g. Lake Kivu Retreat',
              icon: Icons.luggage_outlined,
            ),
            const SizedBox(height: 16),
            const _Field(
              label: 'Destination',
              hint: 'Where are you heading?',
              icon: Icons.location_on_outlined,
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
            const SizedBox(height: 16),
            const _Field(
              label: 'Group size',
              hint: 'How many people?',
              icon: Icons.groups_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.dashboard);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: const Text('Save trip details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final _email = TextEditingController();
  final _invites = <String>['shakira@alustudent.com', 'kamanzi@alustudent.com'];

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      title: 'Invite your people',
      subtitle:
          'Everyone gets one shared view of the trip - decisions, plans and costs included.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final email = _email.text.trim();
                if (email.contains('@') && !_invites.contains(email)) {
                  setState(() {
                    _invites.add(email);
                    _email.clear();
                  });
                }
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text('Send invite'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('INVITED MEMBERS'),
          const SizedBox(height: 10),
          for (final email in _invites)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.paleMint,
                  foregroundColor: AppColors.forest,
                  child: Text(email[0].toUpperCase()),
                ),
                title: Text(email),
                subtitle: const Text('Invite sent'),
                trailing: IconButton(
                  onPressed: () => setState(() => _invites.remove(email)),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  static const _items = [
    (
      'Shakira voted for Ruzizi Tented Lodge',
      'Group voting',
      Icons.how_to_vote_outlined,
      '12 min ago',
    ),
    (
      'Kamanzi added a RWF 35,000 transport expense',
      'Shared ledger',
      Icons.account_balance_wallet_outlined,
      '1 hour ago',
    ),
    (
      'Rajveer updated the first-day itinerary',
      'Itinerary',
      Icons.edit_calendar_outlined,
      '3 hours ago',
    ),
    (
      'Aime uploaded the lodge booking',
      'Document vault',
      Icons.upload_file_outlined,
      'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      title: 'Trip activity',
      subtitle:
          'A clear history of what changed and what needs your attention.',
      showBackButton: false,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      child: Column(
        children: [
          for (final item in _items)
            Padding(
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
                        child: Icon(item.$3, color: AppColors.forest),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.$2}  •  ${item.$4}',
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
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      title: 'Profile & settings',
      subtitle: 'Your travel identity, preferences and account controls.',
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.profile,
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.forest,
            child: Text(
              'RM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rajveer Malik',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'rajveer@alustudent.com',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          const _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal details',
            note: 'Name, phone and emergency contact',
          ),
          const _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            note: 'Trip updates and payment reminders',
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
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
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
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 7),
        TextFormField(
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: (value) =>
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

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.title,
    required this.detail,
  });
  final String time;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF5E4B3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            time,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(detail, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.note,
  });
  final IconData icon;
  final String title;
  final String note;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Icon(icon, color: AppColors.forest),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(note),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}
