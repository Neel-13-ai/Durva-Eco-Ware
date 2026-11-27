import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/core/error/failure.dart';
import 'package:durvaeco/core/error/delegated_error_classifier.dart';

void main() {
  group('Failure sanitization and mapping tests', () {
    test('SocketException / Failed host lookup is sanitized to friendly NetworkFailure', () {
      const rawError =
          "ClientException with SocketException: Failed host lookup: 'api-dev.durvaecoware.com' (OS Error: No address associated with hostname, errno = 7), uri=https://api-dev.durvaecoware.com/api/auth/login";

      final failure = Failure.fromException(rawError);

      expect(failure, isA<NetworkFailure>());
      expect(
        failure.message,
        equals('Unable to connect to the server. Please check your internet connection.'),
      );
      expect(failure.rawMessage, equals(rawError));
    });

    test('UnknownFailure automatically sanitizes raw SocketException strings', () {
      const rawMsg =
          "SocketException: OS Error: Network is unreachable, errno = 101, address = api-dev.durvaecoware.com";
      const failure = UnknownFailure(rawMsg);

      expect(
        failure.message,
        equals('Unable to connect to the server. Please check your internet connection.'),
      );
      expect(failure.rawMessage, equals(rawMsg));
    });

    test('ServerFailure automatically sanitizes connection refused error messages', () {
      const rawMsg = "Connection refused while contacting backend";
      const failure = ServerFailure(500, rawMsg);

      expect(
        failure.message,
        equals('Unable to connect to the server. Please check your internet connection.'),
      );
    });

    test('Timeout issues are sanitized to friendly timeout message', () {
      final failure = Failure.fromException('TimeoutException after 0:00:45.000000: Future not completed');

      expect(failure, isA<NetworkFailure>());
      expect(
        failure.message,
        equals('Connection timed out. Please check your network and try again.'),
      );
    });

    test('Legitimate API and validation messages are preserved intact', () {
      const apiError = 'Invalid username or password.';
      const failure = ServerFailure(401, apiError);

      expect(failure.message, equals(apiError));
      expect(failure.statusCode, equals(401));
    });

    test('classifyDelegatedFailure returns appropriate title and detail', () {
      const netFailure = NetworkFailure();
      final notice = classifyDelegatedFailure(netFailure);

      expect(notice.title, equals('Connection Error'));
      expect(
        notice.detail,
        equals('Unable to connect to the server. Please check your internet connection.'),
      );
    });
  });
}
