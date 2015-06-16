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
import 'package:sqljocky/utils.dart';

bool liveSite = false;

class mdCalendar {

  // Apache
  var _ap = null;

  // Setup
  final int _$NUMHours = 9;
  final List<int> _$startHour = [0, 8, 15];

  final _random = new Random();
  int _next(int min, int max) => min + _random.nextInt(max - min);

  var _pool;
  final String _$calTable = "lwc";
  bool _dataLoaded = false;

  final String _bdp = "/include/bogusData";
  List<String> _$lines;
  int _$cnt;

  // Construction
  mdCalendar(var ap) {
    this._ap = ap;
    _pool = new ConnectionPool(
        host: 'localhost',
        port: 3306,
        user: 'lwc2',
        password: 'lwc2',
        db: 'lwc2',
        max: 5);
  }

  // Functions

  Future<bool> _tableIsCreated() {
    Completer completer = new Completer();
    _pool.query("select * from ${_$calTable}").then((result) {
      return completer.complete(true);
    }).catchError((e) {
      return completer.complete(false);
    });
    return completer.future;
  }

  _calCreateBogusEntry(int year, int month, int day, int $h) async {
    Completer completer = new Completer();

    if (!_dataLoaded) {
      String path;
      path = _ap.Server['DOCUMENT_ROOT'];
      if (liveSite) {
        path += "/projects/md_calendar/";
      }

      var bogus = new File(path + _bdp);
      _$lines = bogus.readAsLinesSync();
      _$cnt = _$lines.length;
      _dataLoaded = true;
    }

    DateTime date = new DateTime.utc(year, month, day);
    var query = await _pool
        .prepare("insert into ${_$calTable} (date,hm,what) values (?, ?, ?)");
    String what = _$lines[_next(0, _$cnt - 2)];
    List parameters = [[date.millisecondsSinceEpoch, $h * 100, "${what}"]];
    await query.executeMulti(parameters);

    return completer.complete;
  }

  _calCreateSampleData() async {
    Completer completer = new Completer();
    DateTime $today = new DateTime.now();
    for (int $im = $today.month; $im <= 12; $im++) for (int $id = 4;
        $id < 27;
        $id += _next(5, 16)) for (int $h = 4; $h < 22; $h += _next(1, 22)) {
      if ($im == $today.month && $id < $today.day) continue;
      await _calCreateBogusEntry($today.year, $im, $id, $h);
    }
    return completer.complete;
  }

  _calCreateTable() async {
    String crtFields =
        "date int, hm int, what varchar(255), id int auto_increment NOT NULL, KEY (date, hm), PRIMARY KEY(id)";

    if (!await _tableIsCreated()) {
      var querier = new QueryRunner(
          _pool, [" create table ${_$calTable} (${crtFields})"]);
      await querier.executeQueries();
      await _calCreateSampleData();
      return true;
    } else {
      return true;
    }
  }

  announce() async {
    _ap.writeOutput("<h1>Hello from md calendar</h1>");
    var result = false;
    result = await _calCreateTable();
    _ap.writeOutput("<h2>Flushing</h2>");
    // Flush and exit
    _ap.flushBuffers(true);
  }
}
