import 'package:checks/checks.dart';
import 'package:dey_dev_utils/contract.dart';
import 'package:test/test.dart';

final class _TestInvariant with Invariant {
  _TestInvariant({this.environment = ContractCheckingEnv.debug});

  final ContractCheckingEnv environment;

  bool isValid = true;
  int invariantCalls = 0;

  @override
  ContractCheckingEnv get contractCheckingEnv => environment;

  @override
  bool invariant() {
    invariantCalls++;
    return isValid;
  }
}

void main() {
  group('runWithChecking', () {
    test('checks preconditions and postconditions around the operation', () {
      final events = <String>[];

      final result = runWithChecking(
        preCondition: () {
          events.add('precondition');
          return true;
        },
        operation: () {
          events.add('operation');
          return 30;
        },
        postCondition: (value) {
          events.add('postcondition');
          return value == 30;
        },
      );

      check(result).equals(30);
      check(events).deepEquals(['precondition', 'operation', 'postcondition']);
    });

    test('does not run the operation when the precondition fails', () {
      var operationCalls = 0;
      var postConditionCalls = 0;

      expect(
        () => runWithChecking(
          preCondition: () => false,
          operation: () {
            operationCalls++;
            return 30;
          },
          postCondition: (_) {
            postConditionCalls++;
            return true;
          },
        ),
        throwsA(
          isA<ContractViolationError>()
              .having((error) => error.kind, 'kind', ViolationKind.preCondition)
              .having(
                (error) => error.message,
                'message',
                'Precondition violated',
              ),
        ),
      );

      check(operationCalls).equals(0);
      check(postConditionCalls).equals(0);
    });

    test('reports postcondition violations after running the operation', () {
      var operationCalls = 0;
      var postConditionCalls = 0;

      expect(
        () => runWithChecking(
          preCondition: () => true,
          operation: () {
            operationCalls++;
            return 30;
          },
          postCondition: (_) {
            postConditionCalls++;
            return false;
          },
        ),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.postCondition,
          ),
        ),
      );

      check(operationCalls).equals(1);
      check(postConditionCalls).equals(1);
    });

    test('propagates callback exceptions without running later callbacks', () {
      var postConditionCalls = 0;

      expect(
        () => runWithChecking(
          preCondition: () => true,
          operation: () => throw StateError('operation failed'),
          postCondition: (_) {
            postConditionCalls++;
            return true;
          },
        ),
        throwsStateError,
      );

      check(postConditionCalls).equals(0);
    });
  });

  group('Invariant', () {
    test('defaults to debug checking', () {
      check(
        _TestInvariant().contractCheckingEnv,
      ).equals(ContractCheckingEnv.debug);
    });

    test('pre and post accept satisfied conditions', () {
      final invariant = _TestInvariant();
      var messageCalls = 0;

      invariant
        ..pre(
          condition: true,
          message: () {
            messageCalls++;
            return 'precondition failed';
          },
        )
        ..post(
          condition: true,
          message: () {
            messageCalls++;
            return 'postcondition failed';
          },
        );

      check(messageCalls).equals(0);
    });

    test('debug pre and post throw assertion errors when conditions fail', () {
      final invariant = _TestInvariant();

      expect(
        () => invariant.pre(condition: false, message: () => 'precondition'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => invariant.post(condition: false, message: () => 'postcondition'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('production pre and post throw typed contract violations', () {
      final invariant = _TestInvariant(
        environment: ContractCheckingEnv.production,
      );

      expect(
        () => invariant.pre(condition: false, message: () => 'invalid input'),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.preCondition,
          ),
        ),
      );
      expect(
        () => invariant.post(condition: false, message: () => 'invalid result'),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.postCondition,
          ),
        ),
      );
    });

    test(
      'runWithInvariant returns the body result and checks the invariant',
      () {
        final invariant = _TestInvariant();
        var invariantCalls = 0;

        final result = invariant.runWithInvariant('update', () {
          invariantCalls++;
          return 30;
        });

        check(result).equals(30);
        check(invariantCalls).equals(1);
        check(invariant.invariantCalls).equals(1);
      },
    );

    test('runWithInvariant reports invalid post-operation state', () {
      final invariant = _TestInvariant(
        environment: ContractCheckingEnv.production,
      );

      expect(
        () => invariant.runWithInvariant('update', () {
          invariant.isValid = false;
          return 30;
        }),
        throwsA(
          isA<ContractViolationError>()
              .having((error) => error.kind, 'kind', ViolationKind.invariant)
              .having(
                (error) => error.message,
                'message',
                'Invariant broken after update',
              ),
        ),
      );
    });

    test('debug runWithInvariant asserts when the invariant is broken', () {
      final invariant = _TestInvariant();

      expect(
        () => invariant.runWithInvariant('update', () {
          invariant.isValid = false;
        }),
        throwsA(isA<AssertionError>()),
      );
      check(invariant.invariantCalls).equals(1);
    });

    test('does not check the invariant when the body throws', () {
      final invariant = _TestInvariant();

      expect(
        () => invariant.runWithInvariant('update', () {
          throw StateError('operation failed');
        }),
        throwsStateError,
      );

      check(invariant.invariantCalls).equals(0);
    });
  });

  group('ContractViolationError', () {
    test('exposes its violation kind and message', () {
      final error = ContractViolationError(
        kind: ViolationKind.invariant,
        message: 'invalid state',
      );

      check(error.kind).equals(ViolationKind.invariant);
      check(error.message).equals('invalid state');
      check(
        error.toString(),
      ).equals('ViolationKind.invariant violated: invalid state');
    });
  });
}
