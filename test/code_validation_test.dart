import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/services/verification_service.dart';

void main() {
  group('Day 20 — normalizeAndValidate() Pure Unit Tests (Table-Driven)', () {
    // 500-character malicious string test vector
    final String longString = 'FD-FT-00123-${'A' * 500}';

    // Table of input -> expected normalized string (or null if invalid)
    final List<Map<String, dynamic>> testCases = [
      // 1. Valid codes
      {
        'label': 'Valid standard fertilizer code',
        'input': 'FD-FT-00123-A7X9KM',
        'expected': 'FD-FT-00123-A7X9KM',
      },
      {
        'label': 'Valid standard pesticide code',
        'input': 'FD-PS-98765-Z2Y3X4',
        'expected': 'FD-PS-98765-Z2Y3X4',
      },
      {
        'label': 'Valid code with 7-char checksum (Day 18 extension)',
        'input': 'FD-FT-00123-A7X9KM7',
        'expected': 'FD-FT-00123-A7X9KM7',
      },

      // 2. Case and whitespace normalization
      {
        'label': 'Lowercase code',
        'input': 'fd-ft-00123-a7x9km',
        'expected': 'FD-FT-00123-A7X9KM',
      },
      {
        'label': 'Code with leading and trailing spaces',
        'input': '   FD-FT-00123-A7X9KM   ',
        'expected': 'FD-FT-00123-A7X9KM',
      },
      {
        'label': 'Lowercase code with leading/trailing whitespace & tabs',
        'input': '\t fd-ps-55555-b8k2m9 \n',
        'expected': 'FD-PS-55555-B8K2M9',
      },

      // 3. Empty, whitespace-only, and null-like inputs
      {
        'label': 'Empty string',
        'input': '',
        'expected': null,
      },
      {
        'label': 'Whitespace only',
        'input': '      ',
        'expected': null,
      },
      {
        'label': 'String literal "null"',
        'input': 'null',
        'expected': null,
      },
      {
        'label': 'String literal "undefined"',
        'input': 'undefined',
        'expected': null,
      },

      // 4. Injections, illegal paths, URLs, and Emojis
      {
        'label': 'Full web URL in QR code',
        'input': 'https://farmerdost.com/verify?code=FD-FT-00123-A7X9KM',
        'expected': null,
      },
      {
        'label': 'HTTP URL',
        'input': 'http://malicious-site.com/fake',
        'expected': null,
      },
      {
        'label': 'Text with illegal forward slash "/" (path breaker)',
        'input': 'FD/FT/00123/A7X9KM',
        'expected': null,
      },
      {
        'label': 'Text with illegal backslash "\\"',
        'input': r'FD\FT\00123\A7X9KM',
        'expected': null,
      },
      {
        'label': 'Code containing Unicode emoji',
        'input': 'FD-FT-00123-🌾🌽🚜',
        'expected': null,
      },
      {
        'label': '500-character payload injection attempt',
        'input': longString,
        'expected': null,
      },

      // 5. Schema and format deviations
      {
        'label': 'Wrong namespace prefix (e.g. AB instead of FD)',
        'input': 'AB-FT-00123-A7X9KM',
        'expected': null,
      },
      {
        'label': 'Wrong type letters (e.g. XX instead of FT/PS)',
        'input': 'FD-XX-00123-A7X9KM',
        'expected': null,
      },
      {
        'label': 'Too-short serial counter (3 digits instead of 5)',
        'input': 'FD-FT-123-A7X9KM',
        'expected': null,
      },
      {
        'label': 'Too-short serial counter (4 digits instead of 5)',
        'input': 'FD-FT-1234-A7X9KM',
        'expected': null,
      },
      {
        'label': 'Too-short random component (3 chars instead of 6+)',
        'input': 'FD-FT-00123-ABC',
        'expected': null,
      },
      {
        'label': 'Too-short random component (5 chars instead of 6+)',
        'input': 'FD-FT-00123-A7X9K',
        'expected': null,
      },
      {
        'label': 'Multiple codes pasted together',
        'input': 'FD-FT-00123-A7X9KMFD-FT-00123-A7X9KM',
        'expected': null,
      },
      {
        'label': 'Multiple codes separated by spaces',
        'input': 'FD-FT-00123-A7X9KM FD-PS-98765-Z2Y3X4',
        'expected': null,
      },
    ];

    for (final tc in testCases) {
      test('Table Case: ${tc['label']}', () {
        final rawInput = tc['input'] as String;
        final expected = tc['expected'] as String?;

        final actual = normalizeAndValidate(rawInput);

        expect(
          actual,
          equals(expected),
          reason: 'Failed for input: "$rawInput". Expected "$expected", got "$actual".',
        );
      });
    }

    test('Table Case: null input argument', () {
      expect(normalizeAndValidate(null), isNull);
    });
  });
}
