import 'package:checks/checks.dart';
import 'package:dey_dev_utils/contract.dart';
import 'package:test/test.dart';

final class _TestInvariant with Invariant {
  _TestInvariant({this.checkingMode = ContractCheckingMode.assertionsOnly});

  final ContractCheckingMode checkingMode;

  bool isValid = true;
  int invariantCalls = 0;

  @override
  ContractCheckingMode get contractCheckingMode => checkingMode;

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
          checkingMode: .alwaysThrow,
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
          checkingMode: .alwaysThrow,
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

    test('debug mode reports failed conditions with assertions', () {
      var operationCalls = 0;

      expect(
        () => runWithChecking(
          preCondition: () => false,
          operation: () {
            operationCalls++;
            return 30;
          },
          postCondition: (_) => true,
        ),
        throwsA(isA<AssertionError>()),
      );
      check(operationCalls).equals(0);

      expect(
        () => runWithChecking(
          preCondition: () => true,
          operation: () => 30,
          postCondition: (_) => false,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('production mode returns the operation result when checks pass', () {
      final result = runWithChecking(
        preCondition: () => true,
        operation: () => 30,
        postCondition: (value) => value == 30,
        checkingMode: .alwaysThrow,
      );

      check(result).equals(30);
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
          checkingMode: .alwaysThrow,
        ),
        throwsStateError,
      );

      check(postConditionCalls).equals(0);
    });

    test(
      'runWithCheckingAsync checks callbacks around the awaited operation',
      () async {
        final events = <String>[];

        final result = await runWithCheckingAsync(
          preCondition: () {
            events.add('precondition');
            return true;
          },
          operation: () async {
            events.add('operation');
            return 30;
          },
          postCondition: (value) {
            events.add('postcondition');
            return value == 30;
          },
        );

        check(result).equals(30);
        check(
          events,
        ).deepEquals(['precondition', 'operation', 'postcondition']);
      },
    );

    test('runWithCheckingAsync stops when the precondition fails', () async {
      var operationCalls = 0;
      var postConditionCalls = 0;

      await expectLater(
        runWithCheckingAsync(
          preCondition: () => false,
          operation: () async {
            operationCalls++;
            return 30;
          },
          postCondition: (_) {
            postConditionCalls++;
            return true;
          },
          checkingMode: .alwaysThrow,
        ),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.preCondition,
          ),
        ),
      );

      check(operationCalls).equals(0);
      check(postConditionCalls).equals(0);
    });

    test('runWithCheckingAsync reports postcondition violations', () async {
      var operationCalls = 0;
      var postConditionCalls = 0;

      await expectLater(
        runWithCheckingAsync(
          preCondition: () => true,
          operation: () async {
            operationCalls++;
            return 30;
          },
          postCondition: (_) {
            postConditionCalls++;
            return false;
          },
          checkingMode: .alwaysThrow,
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

    test(
      'runWithCheckingAsync checks callbacks around the awaited operation',
      () async {
        final events = <String>[];

        final result = await runWithCheckingAsync(
          preCondition: () {
            events.add('precondition');
            return true;
          },
          operation: () async {
            events.add('operation');
            return 30;
          },
          postCondition: (value) {
            events.add('postcondition');
            return value == 30;
          },
        );

        check(result).equals(30);
        check(
          events,
        ).deepEquals(['precondition', 'operation', 'postcondition']);
      },
    );

    test('runWithCheckingAsync stops when the precondition fails', () async {
      var operationCalls = 0;
      var postConditionCalls = 0;

      await expectLater(
        runWithCheckingAsync(
          preCondition: () => false,
          operation: () async {
            operationCalls++;
            return 30;
          },
          postCondition: (_) {
            postConditionCalls++;
            return true;
          },
        ),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'kind',
            matches(
              RegExp(ViolationKind.preCondition.name, caseSensitive: false),
            ),
          ),
        ),
      );

      check(operationCalls).equals(0);
      check(postConditionCalls).equals(0);
    });

    test('runWithCheckingAsync reports postcondition violations', () async {
      var operationCalls = 0;
      var postConditionCalls = 0;

      await expectLater(
        runWithCheckingAsync(
          preCondition: () => true,
          operation: () async {
            operationCalls++;
            return 30;
          },
          postCondition: (_) {
            postConditionCalls++;
            return false;
          },
        ),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'kind',
            matches(
              RegExp(ViolationKind.postCondition.name, caseSensitive: false),
            ),
          ),
        ),
      );

      check(operationCalls).equals(1);
      check(postConditionCalls).equals(1);
    });
  });

  group('Invariant', () {
    test('defaults to assertion-only checking', () {
      check(
        _TestInvariant().contractCheckingMode,
      ).equals(ContractCheckingMode.assertionsOnly);
    });

    test('pre and post accept satisfied conditions', () {
      final invariant = _TestInvariant();
      var messageCalls = 0;

      invariant
        ..pre(
          condition: () => true,
          message: () {
            messageCalls++;
            return 'precondition failed';
          },
        )
        ..post(
          condition: () => true,
          message: () {
            messageCalls++;
            return 'postcondition failed';
          },
        );

      check(messageCalls).equals(0);
    });

    test('assertionsOnly pre and post throw when conditions fail', () {
      final invariant = _TestInvariant();

      expect(
        () => invariant.pre(
          condition: () => false,
          message: () => 'precondition',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => invariant.post(
          condition: () => false,
          message: () => 'postcondition',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('alwaysThrow pre and post throw typed contract violations', () {
      final invariant = _TestInvariant(
        checkingMode: ContractCheckingMode.alwaysThrow,
      );

      expect(
        () => invariant.pre(
          condition: () => false,
          message: () => 'invalid input',
        ),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.preCondition,
          ),
        ),
      );
      expect(
        () => invariant.post(
          condition: () => false,
          message: () => 'invalid result',
        ),
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
        checkingMode: ContractCheckingMode.alwaysThrow,
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

    test(
      'assertionsOnly runWithInvariant asserts when the invariant is broken',
      () {
        final invariant = _TestInvariant();

        expect(
          () => invariant.runWithInvariant('update', () {
            invariant.isValid = false;
          }),
          throwsA(isA<AssertionError>()),
        );
        check(invariant.invariantCalls).equals(1);
      },
    );

    test('checks the invariant when the body throws', () {
      final invariant = _TestInvariant();

      expect(
        () => invariant.runWithInvariant('update', () {
          throw StateError('operation failed');
        }),
        throwsStateError,
      );

      check(invariant.invariantCalls).equals(1);
    });

    test('invariant failure takes precedence over a body exception', () {
      final invariant = _TestInvariant(
        checkingMode: ContractCheckingMode.alwaysThrow,
      );

      expect(
        () => invariant.runWithInvariant('update', () {
          invariant.isValid = false;
          throw StateError('operation failed');
        }),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.invariant,
          ),
        ),
      );
      check(invariant.invariantCalls).equals(1);
    });

    test(
      'runWithInvariantAsync checks invariants after success and failure',
      () async {
        final invariant = _TestInvariant();

        final result = await invariant.runWithInvariantAsync(
          'async update',
          () async => 30,
        );

        check(result).equals(30);
        check(invariant.invariantCalls).equals(1);

        await expectLater(
          invariant.runWithInvariantAsync(
            'async update',
            () async => throw StateError('operation failed'),
          ),
          throwsStateError,
        );
        check(invariant.invariantCalls).equals(2);
      },
    );

    test(
      'async invariant failure takes precedence over a body exception',
      () async {
        final invariant = _TestInvariant(
          checkingMode: ContractCheckingMode.alwaysThrow,
        );

        await expectLater(
          invariant.runWithInvariantAsync('async update', () async {
            invariant.isValid = false;
            throw StateError('operation failed');
          }),
          throwsA(
            isA<ContractViolationError>().having(
              (error) => error.kind,
              'kind',
              ViolationKind.invariant,
            ),
          ),
        );
        check(invariant.invariantCalls).equals(1);
      },
    );

    test('verifyInvariant checks the current state', () {
      _TestInvariant(
        checkingMode: ContractCheckingMode.alwaysThrow,
      ).verifyInvariant('manual check');

      final invalidInvariant = _TestInvariant(
        checkingMode: ContractCheckingMode.alwaysThrow,
      )..isValid = false;
      expect(
        () => invalidInvariant.verifyInvariant('manual check'),
        throwsA(
          isA<ContractViolationError>().having(
            (error) => error.kind,
            'kind',
            ViolationKind.invariant,
          ),
        ),
      );
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
      ).equals('${ViolationKind.invariant.name} violated: invalid state');
    });
  });
}
