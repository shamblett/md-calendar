/*
 * Package : md-calendar
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2015
 * Copyright :  S.Hamblett 2015
 */

library md_calendar;

import 'dart:math';
import 'dart:io';

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

  final String _$calTable = "Hello";

  bool _dataLoaded = false;
  final String _bdp = "/include/bogusData";
  List<String> _$lines;

  // Construction
  mdCalendar(var ap) {
    this._ap = ap;
  }

  // Functions

  void calCreateBogusEntry(int year, int month, int day, int $h) {
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

  void calCreateSampleData() {
    DateTime $today = new DateTime.now();
    for (int $im = $today.month; $im <= 12; $im++) for (int $id = 4;
        $id < 27;
        $id += _next(5, 16)) for (int $h = 4; $h < 22; $h += _next(1, 22)) {
      if ($im == $today.month && $id < $today.day) continue;
      calCreateBogusEntry($today.year, $im, $id, $h);
    }
  }

  void announce() {
    _ap.writeOutput("Hello from md calendar\n");
    calCreateSampleData();
    _ap.writeOutput(_$lines.toString());
    _ap.writeOutput("\n");
  }
}
