/*
 * Package : md-calendar
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2015
 * Copyright :  S.Hamblett 2015
 */

library md_calendar;

class mdCalendar {
  
  // Apache
  var _ap = null;
  
  
  mdCalendar(var ap) {
    
    this._ap = ap;
    
    
  }
  
  void announce () {
  
    _ap.writeOutput("Hello from md calendar");
    
  }
  
  
}