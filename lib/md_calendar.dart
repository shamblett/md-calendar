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
import 'package:path/path.dart' as path;

bool liveSite = true;

class mdCalendar {

  // Apache
  var _ap = null;

  // Setup
  final int _NUMHours = 9;
  final List<int> _startHour = [0, 8, 15];
  final String _lwcVersion = '1.0';
  String _documentRoot;
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
      path = _documentRoot;

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
    String newCal =
        "var cal = new calendar('${_calTable}', ${date}, ${dayZone.toString()}, '${view}') ;";

    _ap.writeOutput(
        "<LINK REL=STYLESHEET TYPE=\"text/css\" HREF=\"JSlib/calStyles.css\">\n");
    _ap.writeOutput(
        "<SCRIPT LANGUAGE=\"JavaScript1.2\" SRC=\"JSlib/cal.js\"></SCRIPT>\n");
    _ap.writeOutput("<SCRIPT LANGUAGE=\"javascript\"> ${newCal} </SCRIPT>\n");
  }

  calHeader(String date, bool isday) {
    if (!isday) return;

    DateTime dartDate = new DateTime(int.parse(date.substring(0, 4)),
        int.parse(date.substring(4, 6)), int.parse(date.substring(6, 8)));

    int wday = dartDate.weekday;
    String wdname;
    switch (dartDate.weekday) {
      case DateTime.MONDAY:
        wdname = 'Monday';
        break;
      case DateTime.TUESDAY:
        wdname = 'Tuesday';
        break;
      case DateTime.WEDNESDAY:
        wdname = 'Wednesday';
        break;
      case DateTime.THURSDAY:
        wdname = 'Thursday';
        break;
      case DateTime.FRIDAY:
        wdname = 'Friday';
        break;
      case DateTime.SATURDAY:
        wdname = 'Saturday';
        break;
      case DateTime.SUNDAY:
        wdname = 'Sunday';
        break;
    }
    String mname;
    switch (dartDate.month) {
      case DateTime.JANUARY:
        mname = 'January';
        break;
      case DateTime.FEBRUARY:
        mname = 'February';
        break;
      case DateTime.MARCH:
        mname = 'March';
        break;
      case DateTime.APRIL:
        mname = 'April';
        break;
      case DateTime.MAY:
        mname = 'May';
        break;
      case DateTime.JUNE:
        mname = 'June';
        break;
      case DateTime.JULY:
        mname = 'July';
        break;
      case DateTime.AUGUST:
        wdname = 'August';
        break;
      case DateTime.SEPTEMBER:
        wdname = 'September';
        break;
      case DateTime.OCTOBER:
        mname = 'October';
        break;
      case DateTime.NOVEMBER:
        mname = 'November';
        break;
      case DateTime.DECEMBER:
        mname = 'December';
        break;
    }
    _ap.writeOutput(
        "${wdname} ${mname} ${dartDate.day.toString()}, ${dartDate.year.toString()}\n");
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

  String calImgRef(String imgname, String alt) {
    String altStr;
    if (alt != null) altStr = "ALT=\"${alt}\"";
    else altStr = "";

    String ret = "<IMG BORDER=0 ${altStr} SRC=\"${imgname}\">";
    return ret;
  }

  String calTBcontrol(String which) {
    var calControls = {
      'CAL_CTRL_EARLIER': [
        'images/earlier.gif',
        "Starting at Midnight (wee hours)",
        0
      ],
      'CAL_CTRL_LATER': [
        'images/later.gif',
        "Ending at Midnight (after hours)",
        1
      ],
      'CAL_CTRL_TODAY': ['images/today.gif', "Today", 2],
      'CAL_CTRL_DAY': ['images/day.gif', "Day View", 3],
      'CAL_CTRL_WEEK': ['images/week.gif', "Week View", 4],
      'CAL_CTRL_MONTH': ['images/month.gif', "Month View", 5],
      'CAL_CTRL_YEAR': ['images/year.gif', "Year View", 6],
      'CAL_CTRL_PREVIOUS': ['images/left.gif', "Previous", 7],
      'CAL_CTRL_NEXT': ['images/right.gif', "Next", 8]
    };

    String img = calControls[which][0];
    String alt = calControls[which][1];
    String imgRef = calImgRef(img, alt);
    int w = calControls[which][2];

    String ret = "<A HREF=\"javascript:calTBcontrol(${w})\">${imgRef}</A>";
    return ret;
  }

  String TBgoto(String date) {
    String y = date.substring(0, 4);
    String m = date.substring(4, 6);
    String d = date.substring(6, 8);

    String type = "TYPE=text NAME=GoTo SIZE=16 MAXLENGTH=20";
    return ("&nbsp;Go&nbsp;to:<INPUT $type value=\"$m/$d/$y\">");
  }

  String calToolBar(String date, int dayZone, String view) {
    // the improper nesting of table and form gives better visual layout
    String output;

    output = "<FORM><INPUT TYPE=hidden NAME=date value=${date}>\n";
    output +=
        '<TABLE class="calToolBar" CELLPADDING=0 CELLSPACING=0 BORDER=0>\n';
    output += "<TR>\n";
    if (view == '') output += "<TD>${calTBcontrol('CAL_CTRL_EARLIER')}</TD>\n";
    output += "<TD>${ calTBcontrol('CAL_CTRL_DAY')}</TD>\n";
    if (view == '') output += "<TD>${calTBcontrol('CAL_CTRL_LATER')}</TD>\n";
    output += "<TD>${calTBcontrol('CAL_CTRL_TODAY')}</TD>\n";
    output += "<TD>${calTBcontrol('CAL_CTRL_WEEK')}</TD>\n";
    output += "<TD>${calTBcontrol('CAL_CTRL_MONTH')}</TD>\n";
    output += "<TD>${calTBcontrol('CAL_CTRL_YEAR')}</TD>\n";
    output += "<TD>${calTBcontrol('CAL_CTRL_PREVIOUS')}</TD>\n";
    output += "<TD>${calTBcontrol('CAL_CTRL_NEXT')}</TD>\n";
    output += "<TD>${TBgoto(date)}</TD>\n";
    output += "</TR>\n";
    output += "</FORM>\n";
    output += "</TABLE>\n";

    return output;
  }

  String calLeftSide(String date, int dayZone, String view) {
    String output;
    output = '<TABLE class="calLeftSide" BORDER=0>\n';
    output += "\t<TR>\n\t\t<TD>\n";
    output += calToolBar(date, dayZone, view);
    output += "\t\t</TD>\n\t</TR>\n\t<TR>\n\t\t<TD>\n";
    /*if ( $view == '' )
      $s = "calDayView($date, $dayZone);";
    else {
      $vf = $viewFuncs[$view];
      $s = "$vf($date);";
    }

    /*	MSDB_ERROR($s);	*/
    eval($s);*/

    output += "\t\t</TD>\n\t</TR>\n</TABLE>\n";
    return output;
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
    String url = "http://" +
        _ap.Server['SERVER_NAME'] +
        path.dirname(_ap.Server['REQUEST_URI']);
    String header =
        '<HTML><HEAD><TITLE>Light Weight Calendar - {{calTitle}} - {{lwcVersion}}</TITLE>' +
            '<base href="${url}" target="_blank"></HEAD><BODY>';
    var template = new Template(header, name: 'template-header.html');
    String title = _calTable + ' : ' + date;
    var output =
        template.renderString({'calTitle': title, 'lwcVersion': _lwcVersion});
    _ap.writeOutput(output);
    jsInfo(date, dayZone, view);

    calHeader(date, view == 'day');
    String leftSide = calLeftSide(date, dayZone, view);
    String mList = ""; // calMlist($date);
    String mTable1 = ""; // calPrintMtable($date, $date);
    String mTable2 = ""; // calPrintMtable(msdbDayMadd($date), $date);
    String table = '''<TABLE class="calTopTable" BORDER=1>
  <TR>
  <TD VALIGN=TOP ROWSPAN=3>
 {{leftSide}}
  </TD>
  <TD>
 {{mList}}
  </TD>
  </TR>
  <TR>
  <TD>
  {{mTable1}}
  </TD>
  </TR>
  <TR>
  <TD>
  {{mTable2}}
  </TD>
  </TR>
  </TABLE></BODY></HTML>''';

    template = new Template(table, name: 'template-body.html');
    output = template.renderString({
      'leftSide': leftSide,
      'mList': mList,
      'mTable1': mTable1,
      'mTable2': mTable2
    });
    _ap.writeOutput(output);
  }

  void calOpen() {
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

      calMain(gt);
    }

    if (_ap.Request.containsKey('calApt')) return (calApt());

    calMain(date);
  }

  announce() async {
    _documentRoot = _ap.Server['DOCUMENT_ROOT'];
    if (liveSite) {
      _documentRoot += "/projects/md_calendar/";
    }
    await _calCreateTable();
    calOpen();

    // Flush and exit
    _ap.flushBuffers(true);
  }
}
