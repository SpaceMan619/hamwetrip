import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// What a completed poll form produced.
class NewPollInput {
  const NewPollInput({required this.question, required this.options});

  final String question;
  final List<String> options;
}

/// What a completed expense form produced.
class NewExpenseInput {
  const NewExpenseInput({
    required this.description,
    required this.amount,
    required this.category,
    required this.categoryEmoji,
  });

  final String description;
  final double amount;
  final String category;
  final String categoryEmoji;
}

/// Asks for a poll question and its options.
///
/// Returns null if the person backs out. Validation is done here rather than in
/// the controller so the form can point at the offending field, and so a poll
/// with a blank question or a single option is never sent to Firestore at all.
Future<NewPollInput?> showCreatePollForm(BuildContext context) {
  return showDialog<NewPollInput>(
    context: context,
    builder: (context) => const _CreatePollDialog(),
  );
}

/// Asks for an expense description, amount and category.
Future<NewExpenseInput?> showAddExpenseForm(BuildContext context) {
  return showDialog<NewExpenseInput>(
    context: context,
    builder: (context) => const _AddExpenseDialog(),
  );
}

/// Asks for a single line of text, returning null if the person backs out or
/// leaves it empty.
///
/// The dialog owns its [TextEditingController] rather than the caller. That
/// matters: `showDialog`'s future completes the moment the route is popped, but
/// the dialog stays mounted through its exit animation. Disposing a controller
/// straight after the await leaves a live TextField holding a dead controller,
/// and the failed teardown trips a framework assertion. Owning it here means it
/// is disposed when the route is genuinely gone.
Future<String?> showSingleFieldPrompt(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _SingleFieldDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

class _SingleFieldDialog extends StatefulWidget {
  const _SingleFieldDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;

  @override
  State<_SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<_SingleFieldDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// What a completed itinerary form produced.
class NewItineraryItemInput {
  const NewItineraryItemInput({
    required this.dayId,
    required this.time,
    required this.title,
    required this.location,
    required this.description,
    required this.emoji,
    required this.type,
  });

  final String dayId;
  final String time;
  final String title;
  final String location;
  final String description;
  final String emoji;
  final String type;
}

/// Asks which day an activity belongs to, and what it is.
///
/// [days] is a list of day id and label pairs. An activity is appended to a
/// day that already exists, so the form picks one rather than offering a free
/// date; with no days to choose from it returns null immediately.
Future<NewItineraryItemInput?> showAddItineraryItemForm(
  BuildContext context,
  List<({String id, String label})> days,
) {
  if (days.isEmpty) return Future.value(null);
  return showDialog<NewItineraryItemInput>(
    context: context,
    builder: (context) => _AddItineraryItemDialog(days: days),
  );
}

class _CreatePollDialog extends StatefulWidget {
  const _CreatePollDialog();

  @override
  State<_CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<_CreatePollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _question = TextEditingController();

  // Two options to begin with, because a poll with one is not a choice.
  final _options = [TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    _question.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewPollInput(
        question: _question.text.trim(),
        options: _options
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New poll'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _question,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'When should we leave?',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ask something.'
                    : null,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _options.length; i++)
                TextFormField(
                  controller: _options[i],
                  decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                  // The first two are required; any extras may be left blank
                  // and are dropped on submit.
                  validator: (value) =>
                      i < 2 && (value == null || value.trim().isEmpty)
                      ? 'Give at least two options.'
                      : null,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _options.length >= 5
                      ? null
                      : () => setState(
                          () => _options.add(TextEditingController()),
                        ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add option'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _AddItineraryItemDialog extends StatefulWidget {
  const _AddItineraryItemDialog({required this.days});

  final List<({String id, String label})> days;

  @override
  State<_AddItineraryItemDialog> createState() =>
      _AddItineraryItemDialogState();
}

class _AddItineraryItemDialogState extends State<_AddItineraryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _time = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  static const _types = <String, String>{
    'activity': '🎒',
    'transport': '🚌',
    'food': '🍽️',
  };

  late String _dayId = widget.days.first.id;
  String _type = 'activity';

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewItineraryItemInput(
        dayId: _dayId,
        time: _time.text.trim(),
        title: _title.text.trim(),
        location: _location.text.trim(),
        description: _description.text.trim(),
        emoji: _types[_type]!,
        type: _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to the itinerary'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _dayId,
                decoration: const InputDecoration(labelText: 'Day'),
                items: [
                  for (final day in widget.days)
                    DropdownMenuItem(value: day.id, child: Text(day.label)),
                ],
                onChanged: (value) => setState(() => _dayId = value ?? _dayId),
              ),
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What is happening?',
                  hintText: 'Canopy walk',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Give it a name.'
                    : null,
              ),
              TextFormField(
                controller: _time,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: '08:00',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'When is it?'
                    : null,
              ),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Where'),
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Kind'),
                items: [
                  for (final entry in _types.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.value}  ${entry.key}'),
                    ),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();

  static const _categories = <String, String>{
    'Transport': '🚌',
    'Food': '🍽️',
    'Activity': '🎟️',
    'Accommodation': '🏠',
    'Other': '💼',
  };

  String _category = 'Transport';

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewExpenseInput(
        description: _description.text.trim(),
        amount: double.parse(_amount.text.trim()),
        category: _category,
        categoryEmoji: _categories[_category]!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _description,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What was it for?',
                  hintText: 'Minibus to Nyungwe',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Say what this was for.'
                    : null,
              ),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                // Digits only: the Rwandan franc has no subdivision, so an
                // amount with a decimal point is not a real figure here.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  suffixText: 'RWF',
                ),
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim());
                  if (amount == null) return 'Enter an amount.';
                  if (amount <= 0) return 'Enter more than zero.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final entry in _categories.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.value}  ${entry.key}'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
