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
  final int _NUMHours = 9;
  final List<int> _startHour = [0, 8, 15];

  final _random = new Random();
  int _next(int min, int max) => min + _random.nextInt(max - min);

  var _pool;
  final String _calTable = "lwc";
  bool _dataLoaded = false;

  final String _bdp = "/include/bogusData";
  List<String> _lines;
  int _cnt;

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
    _pool.query("select * from ${_calTable}").then((result) {
      return completer.complete(true);
    }).catchError((e) {
      return completer.complete(false);
    });
    return completer.future;
  }

  _calCreateBogusEntry(int year, int month, int day, int h) async {
    Completer completer = new Completer();

    if (!_dataLoaded) {
      String path;
      path = _ap.Server['DOCUMENT_ROOT'];
      if (liveSite) {
        path += "/projects/md_calendar/";
      }

      var bogus = new File(path + _bdp);
      _lines = bogus.readAsLinesSync();
      _cnt = _lines.length;
      _dataLoaded = true;
    }

    DateTime date = new DateTime.utc(year, month, day);
    var query = await _pool
        .prepare("insert into ${_calTable} (date,hm,what) values (?, ?, ?)");
    String what = _lines[_next(0, _cnt - 2)];
    List parameters = [[date.millisecondsSinceEpoch, h * 100, "${what}"]];
    await query.executeMulti(parameters);

    return completer.complete;
  }

  _calCreateSampleData() async {
    Completer completer = new Completer();
    DateTime today = new DateTime.now();
    for (int im = today.month; im <= 12; im++) for (int id = 4;
        id < 27;
        id += _next(5, 16)) for (int h = 4; h < 22; h += _next(1, 22)) {
      if (im == today.month && id < today.day) continue;
      await _calCreateBogusEntry(today.year, im, id, h);
    }
    return completer.complete;
  }

  _calCreateTable() async {
    String crtFields =
        "date int, hm int, what varchar(255), id int auto_increment NOT NULL, KEY (date, hm), PRIMARY KEY(id)";

    if (!await _tableIsCreated()) {
      var querier =
          new QueryRunner(_pool, [" create table ${_calTable} (${crtFields})"]);
      await querier.executeQueries();
      await _calCreateSampleData();
      return true;
    } else {
      return true;
    }
  }

  void calApt() {

    /*$date = $_REQUEST['date'];
    $hm = $_REQUEST['hm'];
    $what = $_REQUEST['what'];

    msDbSql("delete from $calTable where date = $date and hm = $hm");

    if ( $what != '' )
      calInsert($date, $hm, $what);

    calMain($date);

    return(1);*/
  }

  void calMain(String date) {
    /* global $calTable, $lwcVersion ;

    if ( isset($_REQUEST['View']) )
      $view = $_REQUEST['View'];
    else
      $view = '' ;

    if ( $view == '' && isset($_REQUEST['dayZone']) )
      $dayZone = $_REQUEST['dayZone'];
    else
      $dayZone = 1;

    if ( isset($_REQUEST['calNext']) ) {
      if ( $view == 'week' )
        $date = msdbDayWadd($date);
      else if ( $view == 'month' )
        $date = msdbDayMadd($date);
      else if ( $view == 'year' )
        $date = msdbDayYadd($date);
      else
        $date = msdbDayDadd($date);
    } else if ( isset($_REQUEST['calPrev']) ) {
      if ( $view == 'week' )
        $date = msdbDayWsub($date);
      else if ( $view == 'month' )
        $date = msdbDayMsub($date);
      else if ( $view == 'year' )
        $date = msdbDayYsub($date);
      else
        $date = msdbDayDsub($date);
    }

    msdbInclude("include/cal.h", array(
        'calTitle' => "$calTable: $date",
        'lwcVersion' => $lwcVersion,
    ));

    jsInfo($date, $dayZone, $view);

    calHeader($date, $view == 0);

  ?>
  <TABLE class=calTopTable BORDER=1>
  <TR>
  <TD VALIGN=TOP ROWSPAN=3>
  <?php calLeftSide($date, $dayZone, $view); ?>
  </TD>
  <TD>
  <?php calMlist($date); ?>
  </TD>
  </TR>
  <TR>
  <TD>
  <?php calPrintMtable($date, $date); ?>
  </TD>
  </TR>
  <TR>
  <TD>
  <?php calPrintMtable(msdbDayMadd($date), $date); ?>
  </TD>
  </TR>
  </TABLE>

  <?php
  msdbInclude("include/cal.t");

  return(1);*/
  }

  void calOpen() {
    String date;
    if (_ap.Request['date'] != null) {
      date = _ap.Request['date'];
    } else {
      DateTime today = new DateTime.now();
      date =
          today.year.toString() + today.month.toString() + today.day.toString();
    }

    if (_ap.Request['GoTo'] != null) {
      String gt = _ap.Request['GoTo'];

      return (calMain(gt));
    }

    if (_ap.Request['calApt'] != null) return (calApt());

    return (calMain(date));
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
