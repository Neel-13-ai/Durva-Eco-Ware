import 'failure.dart';

class DelegatedErrorNotice {
  const DelegatedErrorNotice({required this.title, required this.detail});
  final String title;
  final String detail;
}

DelegatedErrorNotice classifyDelegatedFailure(Failure failure) {
  if (failure is ServerFailure) {
    switch (failure.statusCode) {
      case 401:
        return const DelegatedErrorNotice(
          title: 'Session Ended',
          detail: 'Please sign in again to continue.',
        );
      case 403:
        return const DelegatedErrorNotice(
          title: 'Access Denied',
          detail: 'You do not have permission to perform this action.',
        );
      case 404:
        return const DelegatedErrorNotice(
          title: 'Resource Unavailable',
          detail: 'The requested resource could not be found.',
        );
    }
  }
  return DelegatedErrorNotice(
    title: 'Operation Failed',
    detail: failure.message,
  );
}
