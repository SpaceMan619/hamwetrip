import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_error.dart';
import 'view_state.dart';

/// A [ViewState] paired with a submission flag.
///
/// The two are orthogonal: a screen can be sitting on [ViewData] (its list
/// loaded fine) while [isSubmitting] is true because the user just tapped
/// "leave trip" and a mutation is in flight. Folding submission into
/// [ViewState] itself would force every mutating action to re-render the
/// whole screen as loading, losing the content underneath the button spinner.
@immutable
class ControllerState<T> {
  const ControllerState({required this.view, this.isSubmitting = false});

  final ViewState<T> view;
  final bool isSubmitting;

  ControllerState<T> copyWith({ViewState<T>? view, bool? isSubmitting}) {
    return ControllerState<T>(
      view: view ?? this.view,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Shared shape for every screen controller: loading/data/empty/error plus
/// submission, so screens read one consistent state machine regardless of
/// which repository backs them.
abstract class BaseController<T> extends StateNotifier<ControllerState<T>> {
  // Deliberately not `const`. A const expression cannot reference a type
  // parameter, so `const ControllerState(view: ViewLoading())` infers
  // ControllerState<Never> — which type-checks here, because
  // ControllerState<Never> is a subtype of ControllerState<T>, but leaves
  // every controller holding a <Never>-typed state at runtime. The first
  // setData then fails inside copyWith with "ViewData<Foo> is not a subtype
  // of ViewState<Never>?". Spelling out <T> keeps the state properly typed.
  BaseController() : super(ControllerState<T>(view: ViewLoading<T>()));

  var _disposed = false;

  /// Whether [data] should present as [ViewEmpty] rather than [ViewData].
  /// Defaults to "never empty" — override for list-shaped state.
  bool isEmpty(T data) => false;

  void setLoading() => _emit(state.copyWith(view: const ViewLoading()));

  void setData(T data) {
    _emit(
      state.copyWith(view: isEmpty(data) ? ViewEmpty<T>() : ViewData<T>(data)),
    );
  }

  void setError(AppError error) =>
      _emit(state.copyWith(view: ViewError<T>(error)));

  /// Runs [action] with [isSubmitting] true for its duration, independent of
  /// the underlying [ViewState]. Use for button-triggered mutations —
  /// createTrip, joinTrip, leaveTrip — so the screen can show a spinner on
  /// the control that was tapped without losing whatever it was displaying.
  Future<R> submit<R>(Future<R> Function() action) async {
    _emit(state.copyWith(isSubmitting: true));
    try {
      return await action();
    } finally {
      _emit(state.copyWith(isSubmitting: false));
    }
  }

  void _emit(ControllerState<T> next) {
    if (_disposed) return;
    state = next;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
