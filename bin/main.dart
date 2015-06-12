/*
 * Package : md-calendar
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2015
 * Copyright :  S.Hamblett 2015
 */


import 'dart:convert';

import 'package:md_calendar/md_calendar.dart' as md_calendar;

main(List<String> arguments) {
  
  Apache.setHeader(Apache.CONTENT_TYPE, "text/html");
  Apache.writeOutput('Hello world: ${md_calendar.calculate()}!');
  Apache.flushBuffers();
}
