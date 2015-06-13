/*
 * Package : md-calendar
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2015
 * Copyright :  S.Hamblett 2015
 */

library md_calendar;

import 'dart:math';
import 'dart:io';
import 'dart:async';

import 'package:mustache/mustache.dart';
import 'package:sqljocky/sqljocky.dart';

class mdCalendar {

  // Apache
  var _ap = null;

  // Setup
  final int _$NUMHours = 9;
  final List<int> _$startHour = [0, 8, 15];

  final _random = new Random();
  int _next(int min, int max) => min + _random.nextInt(max - min);

  var _pool;
  bool _tableisCreated = false;
  final String _$calTable = "lwc";

  bool _dataLoaded = false;
  final String _bdp = "/include/bogusData";
  List<String> _$lines;

  // Construction
  mdCalendar(var ap) {
    this._ap = ap;
    _pool = new ConnectionPool(
        host: 'localhost',
        port: 3306,
        user: 'lwc',
        password: 'lwc',
        db: 'lwc',
        max: 5);
  }

  // Functions

  Future _calCreateTable() {
    Completer completer = new Completer();

    String $crtFields =
        "date int, hm int, what varchar(255), id int auto_increment NOT NULL, KEY (date, hm), PRIMARY KEY(id)";

    if (_tableisCreated) {
      completer.complete();
      return completer.future;
    }

    String $crt = "create table ${_$calTable} ( ${$crtFields} )";
    _pool.query($crt).then((result) {
      _calCreateSampleData();
      return completer;
    });

    _tableisCreated = true;
    return completer.future;
  }

  void _calCreateBogusEntry(int year, int month, int day, int $h) {
    if (!_dataLoaded) {
      Directory where = Directory.current;
      String path = where.path;
      var bogus = new File(path + _bdp);
      _$lines = bogus.readAsLinesSync();
      int $cnt = _$lines.length;
      _dataLoaded = true;
    }

    /*$cal = array(
        'date' => $date,
        'hm' => $h * 100,
        'what' => str_replace("'", "\\'", $lines[rand(0, $cnt-2)]),
  );
  msDbSql(msDbInsertSql($calTable, $cal));*/

  }

  void _calCreateSampleData() {
    DateTime $today = new DateTime.now();
    for (int $im = $today.month; $im <= 12; $im++) for (int $id = 4;
        $id < 27;
        $id += _next(5, 16)) for (int $h = 4; $h < 22; $h += _next(1, 22)) {
      if ($im == $today.month && $id < $today.day) continue;
      _calCreateBogusEntry($today.year, $im, $id, $h);
    }
  }

  void announce() {
    _ap.writeOutput("Hello from md calendar\n");
    _calCreateTable();
    _ap.writeOutput(_$lines.toString());
    _ap.writeOutput("\n");
  }
}
