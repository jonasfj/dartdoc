// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:dartdoc/src/comment_references/parser.dart';
import 'package:test/test.dart';

void main() {
  void expectParseEquivalent(String codeRef, List<String> parts,
      {bool constructorHint = false, bool callableHint = false}) {
    var result = CommentReferenceParser(codeRef).parse();
    var hasConstructorHint =
        result.isNotEmpty && result.first is ConstructorHintStartNode;
    var hasCallableHint =
        result.isNotEmpty && result.last is CallableHintEndNode;
    var stringParts = result.whereType<IdentifierNode>().map((i) => i.text);
    expect(stringParts, equals(parts));
    expect(hasConstructorHint, equals(constructorHint));
    expect(hasCallableHint, equals(callableHint));
  }

  void expectParsePassthrough(String codeRef) =>
      expectParseEquivalent(codeRef, [codeRef]);

  void expectParseError(String codeRef) {
    expect(CommentReferenceParser(codeRef).parse().whereType<IdentifierNode>(),
        isEmpty);
  }

  group('Basic comment reference parsing', () {
    test('Check that basic references parse', () {
      expectParseEquivalent('valid', ['valid']);
      expectParseEquivalent('new valid', ['valid'], constructorHint: true);
      expectParseEquivalent('valid()', ['valid'], callableHint: true);
      expectParseEquivalent('const valid()', ['valid'], callableHint: true);
      expectParseEquivalent('final valid', ['valid']);
      expectParseEquivalent('this.is.valid', ['this', 'is', 'valid']);
      expectParseEquivalent('this.is.valid()', ['this', 'is', 'valid'],
          callableHint: true);
      expectParseEquivalent('new this.is.valid', ['this', 'is', 'valid'],
          constructorHint: true);
      expectParseEquivalent('const this.is.valid', ['this', 'is', 'valid']);
      expectParseEquivalent('final this.is.valid', ['this', 'is', 'valid']);
      expectParseEquivalent('var this.is.valid', ['this', 'is', 'valid']);
      expectParseEquivalent('this.is.valid?', ['this', 'is', 'valid']);
      expectParseEquivalent('this.is.valid!', ['this', 'is', 'valid']);
      expectParseEquivalent('this.is.valid<>', ['this', 'is', 'valid']);
      expectParseEquivalent('this.is.valid<stuff>', ['this', 'is', 'valid']);
      expectParseEquivalent('this.is.valid(things)', ['this', 'is', 'valid']);
      expectParseEquivalent('\nthis.is.valid', ['this', 'is', 'valid']);
    });

    test('Check that cases dependent on prefix resolution not firing parse',
        () {
      expectParsePassthrough('constant');
      expectParsePassthrough('newThingy');
      expectParsePassthrough('operatorThingy');
      expectParseEquivalent('operator+', ['+']);
      expectParseError('const()');
      // TODO(jcollins-g): might need to revisit these two with constructor
      // tearoffs?
      expectParsePassthrough('new');
      expectParseError('new()');
    });

    test('Check that operator references parse', () {
      expectParsePassthrough('[]');
      expectParsePassthrough('<=');
      expectParsePassthrough('>=');
      expectParsePassthrough('>');
      expectParsePassthrough('>>');
      expectParsePassthrough('>>>');
      expectParseEquivalent('operator []', ['[]']);
      expectParseEquivalent('operator       []', ['[]']);
      expectParseEquivalent('operator[]', ['[]']);
      expectParseEquivalent('operator <=', ['<=']);
      expectParseEquivalent('operator >=', ['>=']);

      expectParseEquivalent('ThisThingy.operator []', ['ThisThingy', '[]']);
      expectParseEquivalent('ThisThingy.operator [].parameter',
          ['ThisThingy', '[]', 'parameter']);
    });

    test('Basic negative tests', () {
      expectParseError(r'.');
      expectParseError(r'');
      expectParseError('foo(wefoi');
      expectParseError('<MoofMilker>');
      expectParseError('>%');
      expectParseError('>=>');
    });
  });
}
