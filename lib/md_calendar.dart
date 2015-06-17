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
  final String _lwcVersion = '1.0';

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

  calInsert(String date, int hm, String what) {

    /*$w = str_replace("'", "\'", $what);
    $row = array('date' => $date, 'hm' => $hm, 'what' => $what);
    if ( ! msDbPreInsert($calTable, $row) )
      return;
    $cmd = msDbInsertSql($calTable, $row) ;
    msDbSql($cmd);*/
  }

  jsInfo(String date, int dayZone, String view) {
    /*

    $newCal = "var cal = new calendar('$calTable', $date, $dayZone, '$view') ;" ;

    echo "<LINK REL=STYLESHEET TYPE=\"text/css\" HREF=\"JSlib/calStyles.css\">\n" ;
    echo "<SCRIPT LANGUAGE=\"JavaScript1.2\" SRC=\"JSlib/cal.js\"></SCRIPT>\n";
    echo "<SCRIPT LANGUAGE=\"javascript\"> $newCal </SCRIPT>\n";*/
  }

  calHeader(String date, bool isday) {
    if (!isday) return;

    /*list($y, $m, $d) = msdbDayBreak($date);

    $wday = msdbDayWday($date);
    $wdname = msdbWdayLname($wday);
    $mname = msdbMonthLname($m);

    echo "$wdname $mname $d, $y\n";*/
  }

  calApt() async {
    String date = _ap.Request['date'];
    int hm = _ap.Request['hm'];
    String what = _ap.Request['what'];

    await _pool
        .query("delete from ${_calTable} where date = ${date} and hm = ${hm}");

    if (what != '') calInsert(date, hm, what);

    calMain(date);
  }

  void calMain(String date) {
    String view;
    if (_ap.Request.containsKey('View')) {
      view = _ap.Request['View'];
    } else {
      view = '';
    }
    int dayZone;
    if (view == '' && _ap.Request.containsKey('dayZone')) {
      dayZone = _ap.Request;
    } else {
      dayZone = 1;
    }

    DateTime dartDate = new DateTime(int.parse(date.substring(0, 4)),
        int.parse(date.substring(4, 6)), int.parse(date.substring(6, 8)));

    if (_ap.Request.containsKey('calNext')) {
      if (view == 'week') dartDate.add(new Duration(days: 7));
      else if (view == 'month') dartDate.add(new Duration(days: 31));
      else if (view == 'year') dartDate.add(new Duration(days: 365));
      else dartDate.add(new Duration(days: 1));
    } else if (_ap.Request.containsKey('calPrev')) {
      if (view == 'week') dartDate.subtract(new Duration(days: 7));
      else if (view == 'month') dartDate.subtract(new Duration(days: 31));
      else if (view == 'year') dartDate.subtract(new Duration(days: 365));
      else dartDate.subtract(new Duration(days: 1));
    }
    String month;
    String day;
    if (dartDate.month <= 9) {
      month = "0" + dartDate.month.toString();
    } else {
      month = dartDate.month.toString();
    }
    if (dartDate.day <= 9) {
      day = "0" + dartDate.day.toString();
    } else {
      day = dartDate.day.toString();
    }
    date = dartDate.year.toString() + month + day;
    String header =
        '<HTML><HEAD><TITLE>Light Weight Calendar - {{calTitle}} - {{lwcVersion}}</TITLE></HEAD><BODY>';
    var template = new Template(header, name: 'template-header.html');
    String title = _calTable + ' : ' + date;
    var output =
        template.renderString({'calTitle': title, 'lwcVersion': _lwcVersion});

    /*msdbInclude("include/cal.h", array(
        'calTitle' => "$calTable: $date",
        'lwcVersion' => $lwcVersion,
    ));*/

    jsInfo(date, dayZone, view);

    calHeader(date, view == 0);
/*
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
    _ap.writeOutput("calOpen() - entered");
    String date;
    if (_ap.Request.containsKey('date')) {
      date = _ap.Request['date'];
    } else {
      DateTime today = new DateTime.now();
      String month;
      String day;
      if (today.month <= 9) {
        month = "0" + today.month.toString();
      } else {
        month = today.month.toString();
      }
      if (today.day <= 9) {
        day = "0" + today.day.toString();
      } else {
        day = today.day.toString();
      }
      date = today.year.toString() + month + day;
    }

    if (_ap.Request.containsKey('GoTo')) {
      String gt = _ap.Request['GoTo'];

      return (calMain(gt));
    }

    if (_ap.Request.containsKey('calApt')) return (calApt());

    return (calMain(date));
  }

  announce() async {
    _ap.writeOutput("<h1>Hello from md calendar</h1>");
    await _calCreateTable();
    calOpen();
    _ap.writeOutput("<h2>Flushing</h2>");
    // Flush and exit
    _ap.flushBuffers(true);
  }
}
