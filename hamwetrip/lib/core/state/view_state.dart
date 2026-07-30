import 'package:flutter/foundation.dart';

import '../error/app_error.dart';

/// The four states any screen backed by a repository stream or one-shot read
/// can be in.
///
/// Sealed so a `switch` in a screen's build method is exhaustive and the
/// compiler catches a state the widget forgot to render.
@immutable
sealed class ViewState<T> {
  const ViewState();

  /// The failure when this is a [ViewError], and null otherwise.
  ///
  /// Screens need this because type promotion cannot reach [ViewError.error]
  /// from a typed state. Testing `state is ViewError<dynamic>` does not
  /// promote a `ViewState<Trip>`: promotion only applies when the tested type
  /// is a subtype of the declared one, and `ViewError<dynamic>` extends
  /// `ViewState<dynamic>`, which is not a subtype of `ViewState<Trip>`.
  ///
  /// Repeating the element type at every call site would work, but reads
  /// badly and breaks the moment a provider's type changes. This getter is
  /// the same check without the ceremony.
  AppError? get error => null;
}

/// Nothing has arrived yet — the initial state before the first emission.
final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

/// The load succeeded, and there is nothing to show — an empty trip list, an
/// empty activity feed. Distinct from [ViewData] so a screen can render a
/// dedicated empty-state illustration instead of an empty list widget.
final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

/// The load succeeded and produced content.
final class ViewData<T> extends ViewState<T> {
  const ViewData(this.data);

  final T data;
}

/// The load failed. [error] is always safe to render directly.
final class ViewError<T> extends ViewState<T> {
  const ViewError(this.error);

  @override
  final AppError error;
}
