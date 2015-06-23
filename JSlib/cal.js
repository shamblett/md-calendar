function
calendar(tname, date, dayZone, view)
{
        this.tname = tname;
        this.date = date;
        this.view = view;
        this.dayZone = dayZone;
        this.curHM = -1 ;
        this.apts = new Array();
        return(this);
}



function
calAptData(hm, what)
{
        this.hm = hm;
        this.what = what;
        return(this);
}



function
calStore(hm, what)
{
        a = cal.apts;
        a[a.length] = new calAptData(hm, what);
}



function
calFindApt(hm)
{

        a = cal.apts;
        for(i=0;i<a.length;i++)
                if(a[i].hm == hm )
                        return(a[i]);
        return(0);
}


function
calStam()
{
        d = new Date();

        return(
                d.getMinutes() * 60 * 1000 +
                d.getSeconds() * 1000 +
                d.getMilliseconds()
                );
}



function
calCmd(day, args)
{
        loc = "/bin/main.dart?" +
                        "stam=" + calStam() +
                        "&date=" + day +
                        args
                ;

        location = loc ;
}



function
calYear(y)
{
        day = y*10000 + 101 ;
        calCmd(day, "&View=year");
}



function
calWeek(day)
{
        calCmd(day, "&View=week");
}



function
calMonth(day)
{
        calCmd(day, "&View=month");
}



function
calTime(day, dayZone)
{
        if ( dayZone == 1 )
                calCmd(day, "");
        else
                calCmd(day, "&dayZone="+dayZone);
}



function
calDay(day)
{
        calCmd(day, "");
}



function
calSetApt(hm)
{
        a = calFindApt(hm);
        preWhat = (a == 0) ? '' : a.what ;

        postWhat = prompt("Apppoitment at " + hm, preWhat);


        if ( postWhat == null || postWhat == cal.undef )
                return;
        if ( postWhat == preWhat )
                return;

        calCmd(
                cal.date,
                "&calApt=Done&hm=" + hm + "&what=" + escape(postWhat) +
                "&dayZone=" + cal.dayZone
                );
}



var calCtrlName = new Array(
        'earlier',
        'later',
        'today',
        'day',
        'week',
        'month',
        'year',
        'previous',
        'next'
);




function
calDate2int(t)
{

        y = t.getFullYear();
        m = t.getMonth() + 1;
        d = t.getDate();

        return(y * 10000 + m * 100 + d);
}



function
calTBcontrol(which)
{
        if ( cal.view == '' )
                varg = '' ;
        else
                varg = "&View=" + cal.view ;

        switch(which) {
                case 0 :
                                calCmd(cal.date, "&dayZone=0");
                        break;
                case 1 :
                                calCmd(cal.date, "&dayZone=2");
                        break;
                case 2 :
                                t = new Date();
                                today = calDate2int(t);
                                calCmd(today, "");
                        break;
                case 3 :
                                calCmd(cal.date, "");
                        break;
                case 4 :
                                calCmd(cal.date, "&View=week");
                        break;
                case 5 :
                                calCmd(cal.date, "&View=month");
                        break;
                case 6 :
                                calCmd(cal.date, "&View=year");
                        break;
                case 7 :
                                calCmd(cal.date, varg + "&calPrev=");
                        break;
                case 8 :
                                calCmd(cal.date, varg + "&calNext=");
                        break;
                default :
                                alert("Unknow Control");
                        break;
        }
}
