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

  final AppError error;
}
