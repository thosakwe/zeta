import 'package:code_buffer/code_buffer.dart';
import 'package:meta/meta.dart';

Program program(Iterable<Statement> statements) => new Program._(statements);

class Program {
  Program._(this.statements);

  final Iterable<Statement> statements;

  void compile(CodeBuffer buffer) {
    for (var stmt in statements) {
      stmt.compile(buffer);
    }
  }
}

abstract class Statement {
  void compile(CodeBuffer buffer);
}

Statement comment(String text) => new _Comment(text);

class _Comment extends Statement {
  final String text;

  _Comment(this.text);

  @override
  void compile(CodeBuffer buffer) {
    var lines =
        text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty);
    if (lines.isEmpty)
      return;
    else if (lines.length == 1)
      buffer.writeln('# $text');
    else {
      buffer.writeln('/*');
      for (var line in lines) buffer.writeln(' * $line');
      buffer.writeln(' */');
    }
  }
}

const Statement lineBreak = const _LineBreak();

class _LineBreak implements Statement {
  const _LineBreak();

  @override
  void compile(CodeBuffer buffer) {
    buffer.writeln(' ');
  }
}

abstract class Expression extends Statement {
  String compileExpression(CodeBuffer buffer);

  @override
  void compile(CodeBuffer buffer) {
    buffer.writeln(compileExpression(buffer) + ';');
  }
}

Expression literal(value) => new _Literal(value);

class _Literal extends Expression {
  final value;

  _Literal(this.value);

  @override
  String compileExpression(CodeBuffer buffer) {
    if (value == true)
      return '\$true';
    else if (value == false)
      return '\$false';
    else if (value is! String) return value.toString();
    return '"' +
        (value as String)
            .replaceAll('"', '\\"')
            .replaceAll('\\', '\\\\')
            .replaceAll('\b', '\\b')
            .replaceAll('\f', '\\f')
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r')
            .replaceAll('\t', '\\t') +
        '"';
  }
}

Expression raw(String text) => new _Raw(text);

class _Raw extends Expression {
  final String text;

  _Raw(this.text);

  @override
  String compileExpression(CodeBuffer buffer) {
    return text;
  }
}

Expression array(Iterable<Expression> items) => new _Array(items);

class _Array extends Expression {
  final Iterable<Expression> items;

  _Array(this.items);

  @override
  String compileExpression(CodeBuffer buffer) {
    return '[ ' +
        items.map((i) => i.compileExpression(buffer)).join(', ') +
        ' ]';
  }
}

Expression object(Map<String, Expression> values) => new _Object(values);

Expression function(String name,
        {@required Iterable<String> params,
        @required int numLocals,
        @required Expression entry}) =>
    object({
      'name': literal(name),
      'params': array(params.map(literal)),
      'num_locals': literal(numLocals),
      'entry': entry,
    });

Expression entry(
        {@required String name, @required Iterable<Expression> instrs}) =>
    object({
      'name': literal(name),
      'instrs': array(instrs),
    });

Expression op(String name,
    {Expression val, Expression retTo, Expression throwTo, Expression then, Expression $else, int numArgs, int idx}) {
  var m = {
    'name': literal(name),
  };

  if (val != null) m['val'] = val;
  if (retTo != null) m['ret_to'] = retTo;
  if (throwTo != null) m['throw_to'] = throwTo;
  if (then != null) m['then'] = then;
  if ($else != null) m['else'] = $else;
  if (numArgs != null) m['num_args'] = literal(numArgs);
  if (idx != null) m['idx'] = literal(idx);

  return object(m);
}

class _Object extends Expression {
  final Map<String, Expression> values;

  _Object(this.values);

  @override
  String compileExpression(CodeBuffer buffer) {
    int i = 0;
    return values.keys.fold<StringBuffer>(new StringBuffer('{ '), (b, key) {
          if (i++ > 0) b.write(', ');
          return b..write('$key: ' + values[key].compileExpression(buffer));
        }).toString() +
        ' }';
  }
}

Reference reference(String name, {Expression value}) =>
    new Reference._(name).._value = value;

class Reference extends Expression {
  final String name;
  Expression _value;

  Reference._(this.name);

  Expression get value => _value;

  @override
  String compileExpression(CodeBuffer buffer) {
    return '@$name';
  }

  Statement assign(Expression value) {
    return new _Assign(name, _value = value);
  }
}

Statement assign(String name, Expression value) => new _Assign(name, value);

class _Assign extends Statement {
  final String name;
  final Expression value;

  _Assign(this.name, this.value);

  @override
  void compile(CodeBuffer buffer) {
    var v = value.compileExpression(buffer);
    buffer.writeln('$name = $v;');
  }
}
