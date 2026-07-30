import 'dart:async';

import '../error/app_error.dart';
import 'base_controller.dart';

/// A [BaseController] that mirrors a single repository [Stream] into
/// [ViewState] — subscribing on construction, translating each event into
/// [BaseController.setData] and each stream error into [BaseController.setError].
///
/// Every read-only screen (the trip list, a member roster, an activity feed)
/// is a repository stream and nothing else, so they all share this one
/// adapter instead of each screen writing its own subscribe/dispose
/// boilerplate.
class StreamViewController<T> extends BaseController<T> {
  StreamViewController(Stream<T> stream, {bool Function(T data)? isEmptyWhen})
    : _isEmptyWhen = isEmptyWhen {
    _subscription = stream.listen(
      setData,
      onError: (Object error, StackTrace _) {
        setError(error is AppError ? error : UnknownError(cause: error));
      },
    );
  }

  final bool Function(T data)? _isEmptyWhen;
  late final StreamSubscription<T> _subscription;

  @override
  bool isEmpty(T data) => _isEmptyWhen?.call(data) ?? false;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
