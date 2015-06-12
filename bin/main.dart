/*
 * Package : md-calendar
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2015
 * Copyright :  S.Hamblett 2015
 */


import 'dart:convert';

import 'package:md_calendar/md_calendar.dart' as md_calendar;


main(List<String> arguments) {
  
  // Get our Apache class
  Apache myApp = new Apache();
  
  // Set a global header
  myApp.setHeader(Apache.CONTENT_TYPE, "text/html");
  
  // Get our calendar application
  md_calendar.mdCalendar cal = new md_calendar.mdCalendar(myApp);
  cal.announce();
  
  // Flush and exit
  myApp.flushBuffers();
}

