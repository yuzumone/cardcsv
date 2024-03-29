import 'dart:io';
import 'package:args/args.dart';

void main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addSeparator('cardcsv: parse creditcard csv file.\n');
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show this message.');
  parser.addOption('file', abbr: 'f', help: 'Input file path.');
  parser.addOption('output',
      abbr: 'o', defaultsTo: 'output.csv', help: 'Out file name.');
  try {
    var results = parser.parse(arguments);
    if (!results['help'] || results['file'] != null) {
      var str = await _convert(results['file']);
      var data = _format(str);
      await _write(results['output'], data);
    } else {
      print(parser.usage);
      exit(64);
    }
  } catch (e) {
    print(parser.usage);
    exit(64);
  }
}

Future<String> _convert(String path) async {
  var proc = await Process.run('nkf', ['-wd', path]);
  return proc.stdout as String;
}

List<List<String>> _format(String raw) {
  var reg = RegExp(r'\d+');
  var list = raw
      .split('\n')
      .map((e) => e.split(','))
      .where((e) => reg.hasMatch(e[0]))
      .toList();

  if (list[0].length == 7) {
    if (reg.hasMatch(list[0][2])) {
      list.forEach((e) {
        e.removeRange(3, 7);
      });
    } else if (reg.hasMatch(list[0][0])) {
      list = list.reversed
          .where((e) => !['PayPayポイント運用に支払い', 'ボーナス運用に支払い'].contains(e[1]))
          .map((e) => [
                e[4]
                    .replaceAll('年', '/')
                    .replaceAll('月', '/')
                    .replaceAll('日', '')
                    .replaceAll(RegExp(r'\s\d+時\d+分'), ''),
                e[1].replaceAll('に支払い', ''),
                e[6].replaceAll('-', '')
              ])
          .cast<List<String>>()
          .toList();
    } else {
      list.forEach((e) {
        e.removeRange(2, 5);
        e.removeLast();
      });
    }
  } else if (list[0].length == 9) {
    list = list
        .map((e) => [
              '20${e[0].substring(0, 2)}/${e[0].substring(2, 4)}/${e[0].substring(4, 6)}',
              e[2],
              e[6]
            ])
        .cast<List<String>>()
        .toList();
  }
  return list;
}

Future<void> _write(String output, List<List<String>> data) async {
  var file = File(output);
  for (var item in data) {
    await file.writeAsString('${item[0]}, ${item[1]}, ${item[2]}\n',
        mode: FileMode.append);
  }
}
