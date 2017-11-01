import 'package:code_buffer/code_buffer.dart';
import 'package:zeta/zeta.dart';

main() {
  var p = program([
    // Comments can be single or multiple lines.
    comment('Booleans'),

    // Two ways to assign values
    reference('trueBool').assign(literal(true)),
    assign('falseBool', literal(false)),

    // Manual line breaks
    lineBreak,

    // Long comments
    comment('Strings\narrays\nobjects'),

    // More assignments
    reference('myObject').assign(object({
      'a': literal(1),
      'b': literal(true),
      'c': literal(525),
      'd': array([
        literal(1),
        literal('two'),
        literal(3.0),
      ]),
      'e': raw('@rawExpr'),
      'f': reference('someRef'),
    })),

    // Function declaration
    reference('sum').assign(function(
      'sum',
      // Two arguments
      params: ['x', 'y'],

      // Three local variables
      numLocals: 3,

      // Entry point
      entry: entry(
        name: 'sum_entry',
        instrs: [
          op('get_local', idx: 0),
          op('get_local', idx: 1),
          op('add_i32'),
          op('ret'),
        ],
      ),
    )),

    // Export definition
    object({
      'str': reference('myString'),
      'main': reference('main'),
    }),
  ]);

  var buf = new CodeBuffer();
  p.compile(buf);
  print(buf);
}
