using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.ActivityMonitor as ActMon;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;

class textifyView extends Ui.WatchFace {
    hidden const unitString = [null, "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];
    hidden const teenString = ["ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"];
    hidden const tenString = ["oh", "ten", "twenty", "thirty", "forty", "fifty", "sixty"];
	hidden var _DEBUG = false, _DEBUG_VAR = 0, fourtwenty = false;
	hidden var penWidth = 4;
    hidden var timeFont, timeFontHeight, timeVerticalScale, timeVerticalCentre, dateFont, dateFontHeight;
    
    // settings
    hidden var is24Hour;
    hidden var isMilitaryTime, TextifyIndividually, hourColour, minuteColour, dateColour, backgroundColour, UseUpperCase, FontChoice;
    
    // physical settings
    hidden var screenWidth, halfScreenWidth, screenHeight, halfScreenHeight;
    function initialize() {
        WatchFace.initialize();
        if (_DEBUG) { System.println("#initialise#"); }
    	//updateSettings();
    }

    // Load your resources here
    function onLayout(dc) {
    	if (_DEBUG) { System.println("#onLayout#"); }
    	updateSettings();
    	
    	screenWidth = dc.getWidth();
    	halfScreenWidth = screenWidth/2;
    	screenHeight = dc.getHeight();
    	halfScreenHeight = screenHeight/2;
    }

    function updateSettings()
    {
    	if (_DEBUG) { System.println("[updateSettings]"); }
        var deviceSettings = Sys.getDeviceSettings();
        is24Hour = deviceSettings.is24Hour;
        isMilitaryTime = Application.getApp().getProperty("UseMilitaryFormat");
        TextifyIndividually = Application.getApp().getProperty("TextifyIndividually");
        hourColour = Application.getApp().getProperty("HourColour");
        minuteColour = Application.getApp().getProperty("MinuteColour");
        dateColour = Application.getApp().getProperty("DateColour");
        backgroundColour = Application.getApp().getProperty("BackgroundColour");
        UseUpperCase = Application.getApp().getProperty("UseUpperCase");
    }
    
	function onSettingsChanged() { // triggered by settings change in GCM
		if (_DEBUG) { System.println("onSettingsChanged"); }
    	updateSettings();
    	WatchUi.requestUpdate();   // update the view to reflect changes
	}

    // Update the view
    function onUpdate(dc) {
    	if (_DEBUG) { System.println("#onUpdate#"); }
    	updateFontChoice(dc);
    	//updateSettings();
        // watch statistics
        var batteryLevel = Sys.getSystemStats().battery;
        if (_DEBUG) { batteryLevel = 15; is24Hour = true; } // DEBUG
        var batteryLevelString = (batteryLevel <= 15)?"recharge":batteryLevel.format("%d").toString() + "%"; 
        batteryLevelString = (UseUpperCase)?batteryLevelString.toUpper():batteryLevelString;
        
        // Get the current time
        var clockTime = Sys.getClockTime();
        if (_DEBUG) // DEBUG
        {
        	if (_DEBUG_VAR == 0)
        	{
        		clockTime.hour = 17; clockTime.min = 17;
        	}
        	else if (_DEBUG_VAR == 1)
        	{
        		clockTime.hour = 24; clockTime.min = 37;
        	}
        	else
        	{
        		clockTime.hour = 16; clockTime.min = 20 + _DEBUG_VAR - 2;
    		}
        }
        
        // Four Twenty ...
        if ( (clockTime.hour == 16) && (clockTime.min == 20) )
        {
            backgroundColour = Gfx.COLOR_DK_GREEN;
            hourColour = Gfx.COLOR_GREEN;
            minuteColour = Gfx.COLOR_WHITE;
            dateColour = Gfx.COLOR_WHITE;
            fourtwenty = true;
            clockTime.hour = 4;
        }
        
        if ((!is24Hour) && (clockTime.hour > 12))
        {
            clockTime.hour -= 12;
        }
                     
        var clockTimeStringArray = minsHours2Text(clockTime.hour, clockTime.min, isMilitaryTime, TextifyIndividually);   
        
        if ((UseUpperCase) || (FontChoice < 2)) // FontChoice < 2 are AllCaps fonts
        {
            clockTimeStringArray[0] = (clockTimeStringArray[0] == null)?null:clockTimeStringArray[0].toUpper();
            clockTimeStringArray[1] = (clockTimeStringArray[1] == null)?null:clockTimeStringArray[1].toUpper();
            clockTimeStringArray[2] = (clockTimeStringArray[2] == null)?null:clockTimeStringArray[2].toUpper();
            clockTimeStringArray[3] = (clockTimeStringArray[3] == null)?null:clockTimeStringArray[3].toUpper();
        }
        
        // Get the current date
        var clockDate = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
        //clockDate.day_of_week = "Sun"; clockDate.day = 2; clockDate.month = "Sep"; // DEBUG

        var dateString = toDateString(clockDate.day_of_week, clockDate.day, clockDate.month, UseUpperCase);
        
        // setup the watch face
        dc.setColor(backgroundColour, backgroundColour);
        dc.clear();
        
        // draw the date
        var dateFontHeight = dc.getFontHeight(dateFont);

        dc.setColor(dateColour, Gfx.COLOR_TRANSPARENT);
        dc.drawText(halfScreenWidth, dateFontHeight, dateFont, dateString, Gfx.TEXT_JUSTIFY_CENTER);
        
        // draw the battery percent
        dc.drawText(halfScreenWidth, dc.getHeight() - 1.7*dateFontHeight, dateFont, batteryLevelString, Gfx.TEXT_JUSTIFY_CENTER);
        
        // get the current step count
        var ActInfo = ActMon.getInfo();
        var stepCount = ActInfo.steps;
        var stepGoal = ActInfo.stepGoal;
        var stepPercent = (stepCount == 0.0)?0.0:(stepCount.toFloat() / stepGoal);
        if (_DEBUG) { stepPercent = 2.25; } // DEBUG
        
        // draw the step count
        drawStepCount(dc, stepPercent, penWidth, hourColour, minuteColour);
         
        // draw the time
        drawTimeString(dc, clockTimeStringArray, timeFont, hourColour, minuteColour);
        
        if (fourtwenty)
        {
        	updateSettings();
            fourtwenty = false;
        }
        
        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
        if (_DEBUG) { _DEBUG_VAR++; } // DEBUG
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    if (_DEBUG) { System.println("#onHide#"); }
    }

    function onShow() {
    if (_DEBUG) { System.println("#onShow#"); }
    }
    
    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    if (_DEBUG) { System.println("#onExitSleep#"); }
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    if (_DEBUG) { System.println("#onEnterSleep#"); }
    }
    
    function drawOverStepPos(dc, stepPercent, penWidth, minuteColour)
    {
         dc.setColor(minuteColour, Gfx.COLOR_TRANSPARENT);
         dc.setPenWidth(penWidth);
         
         var overStepCount = stepPercent.toNumber();
         var arcPercent = stepPercent - overStepCount.toFloat();
         
         var arcSwathDeg = 3;
         var arcGapDeg = 2;
         
         for (var index = 0; index < overStepCount; index++)
         {
            var degreeEnd = 360 * arcPercent - (arcGapDeg + arcSwathDeg)*index;
            var degreeStart = degreeEnd - arcSwathDeg;
         
            drawArc(dc, degreeStart, degreeEnd, penWidth, minuteColour);    
         }
    }
    
    function drawStepCount(dc, stepPercent, penWidth, hourColour, minuteColour)
    {
        if (stepPercent > 0.0)
         {
             dc.setColor(hourColour, Gfx.COLOR_TRANSPARENT);
             dc.setPenWidth(penWidth);
             var degreeStart = 0;
             
             var degreeEnd = degreeStart;
             if (stepPercent > 1.0)
             {
                degreeEnd += (360 - degreeStart);
             }
             else
             {
                degreeEnd += (360 - degreeStart)*stepPercent;
             }
            
             drawArc(dc, degreeStart, degreeEnd, penWidth, hourColour);
                         
             if (stepPercent > 1.0)
             {
                drawOverStepPos(dc, stepPercent, penWidth, minuteColour);
             }
        }
    }
    
    function drawTimeString(dc, clockTimeStringArray, timeFont, hourColour, minuteColour) {
        var vOffset = 0;
        
        // set the hour colour
        dc.setColor(hourColour, Gfx.COLOR_TRANSPARENT);
                
        if (clockTimeStringArray[2] == null)
        {
            dc.drawText(halfScreenWidth, timeVerticalCentre, timeFont, clockTimeStringArray[1], Gfx.TEXT_JUSTIFY_CENTER);
        }
        else if ((clockTimeStringArray[0] == null) && (clockTimeStringArray[3] != null)) // 1 hour line, 2 minute lines 
        {
            dc.drawText(halfScreenWidth, timeVerticalCentre - timeFontHeight, timeFont, clockTimeStringArray[1], Gfx.TEXT_JUSTIFY_CENTER);
            dc.setColor(minuteColour, Gfx.COLOR_TRANSPARENT);
            dc.drawText(halfScreenWidth, timeVerticalCentre, timeFont, clockTimeStringArray[2], Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(halfScreenWidth, timeVerticalCentre + timeFontHeight, timeFont, clockTimeStringArray[3], Gfx.TEXT_JUSTIFY_CENTER);
        }
        else if ((clockTimeStringArray[0] != null) && (clockTimeStringArray[3] == null)) // 2 hour lines, 1 minute line 
        {
            dc.drawText(halfScreenWidth, timeVerticalCentre - timeFontHeight, timeFont, clockTimeStringArray[0], Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(halfScreenWidth, timeVerticalCentre, timeFont, clockTimeStringArray[1], Gfx.TEXT_JUSTIFY_CENTER);
            dc.setColor(minuteColour, Gfx.COLOR_TRANSPARENT);
            dc.drawText(halfScreenWidth, timeVerticalCentre + timeFontHeight, timeFont, clockTimeStringArray[2], Gfx.TEXT_JUSTIFY_CENTER);
        }
        else if ((clockTimeStringArray[0] == null) && (clockTimeStringArray[2] == null)) // 1 hour line, 0 minute lines
        {
            dc.drawText(halfScreenWidth, timeVerticalCentre, timeFont, clockTimeStringArray[1], Gfx.TEXT_JUSTIFY_CENTER);
        }
        else
        {
            dc.drawText(halfScreenWidth, timeVerticalCentre - 1.5*timeFontHeight, timeFont, (clockTimeStringArray[0] == null)?"":clockTimeStringArray[0], Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, clockTimeStringArray[1], Gfx.TEXT_JUSTIFY_CENTER);
            dc.setColor(minuteColour, Gfx.COLOR_TRANSPARENT);
            dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, clockTimeStringArray[2], Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(halfScreenWidth, timeVerticalCentre + 1.5*timeFontHeight, timeFont, (clockTimeStringArray[3] == null)?"":clockTimeStringArray[3], Gfx.TEXT_JUSTIFY_CENTER);
        }
    }
    
    function drawArc(dc, degreeStart, degreeEnd, penWidth, arcColour)
    {
        dc.setColor(arcColour, Gfx.COLOR_TRANSPARENT);
        if (degreeEnd > 90)
        {
            if ((degreeStart > 90) == false)
            {
                dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - penWidth, Gfx.ARC_CLOCKWISE, 90 - degreeStart, 0);
                dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - penWidth, Gfx.ARC_CLOCKWISE, 0, 360 - (degreeEnd - 90));
            }
            else
            {
                dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - penWidth, Gfx.ARC_CLOCKWISE, 360 - (degreeStart - 90), 360 - (degreeEnd - 90));
            }
        }
        else
        {
            dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - penWidth, Gfx.ARC_CLOCKWISE, 90 - degreeStart, 90 - degreeEnd);             
        }
    }
    
    function updateFontChoice(dc)
    {
        // XTINY Roboto Condensed Regular 26
        // TINY Roboto Condensed Bold 26
        // SMALL Roboto Condensed Bold 29
        // MEDIUM Roboto Condensed Bold 34
        var FontChoice_ = Application.getApp().getProperty("FontChoice");
        
    	if (FontChoice != FontChoice_)
    	{
			FontChoice = FontChoice_;
					    	
	        switch(FontChoice) {
	            case 0:
	                timeFont = Ui.loadResource(Rez.Fonts.Digitalt);
	                dateFont = Ui.loadResource(Rez.Fonts.DigitaltSmall);
	                timeVerticalScale = 0.9;
	                break;
	            case 1:
	                timeFont = Ui.loadResource(Rez.Fonts.Munistic);
	                dateFont = Ui.loadResource(Rez.Fonts.MunisticSmall);
	                timeVerticalScale = 0.9;
	                break;
	            case 2:
	                timeFont = Ui.loadResource(Rez.Fonts.Gputeks);
	                dateFont = Ui.loadResource(Rez.Fonts.GputeksSmall);
	                timeVerticalScale = 0.75;
	                break;
	            case 4:
	                timeFont = Ui.loadResource(Rez.Fonts.okolaks);
	                dateFont = Ui.loadResource(Rez.Fonts.okolaksSmall);
	                timeVerticalScale = 0.75;
	                break;
	            default: // case 3
	                timeFont = Ui.loadResource(Rez.Fonts.Resagokr);
	                dateFont = Ui.loadResource(Rez.Fonts.ResagokrSmall);
	                timeVerticalScale = 1.0;
	        }
        }
        
        timeFontHeight = timeVerticalScale*dc.getFontHeight(timeFont);
        timeVerticalCentre = halfScreenHeight - 0.5*timeFontHeight;
        dateFontHeight = dc.getFontHeight(timeFont);
    }
    
    function toDateString(dotw, day, month, UseUpperCase) {
        var dateString = Lang.format("$1$ $2$ $3$", [dotw, day, month]);

        return (UseUpperCase)?dateString.toUpper():dateString;
    }
    
    function minsHours2Text(hours, mins, isMilitaryTime, TextifyIndividually) {
        var textOut = [null,null,null,null];
        
        if (TextifyIndividually)
        {
        	textOut[0] = digit2Text(hours/10);
        	textOut[1] = digit2Text(hours%10);
        	textOut[2] = digit2Text(mins/10);
        	textOut[3] = digit2Text(mins%10);
        }
        else if ((mins == 0) && ((hours % 12) == 0))
        {
            if (hours == 12)
            {
                textOut[1] = "midday";
            }
            else
            {
                textOut[1] = "midnight";
            }
        }
        else
        {
            var hourText = number2Text(hours, true, isMilitaryTime);
            var minText = number2Text(mins, false, isMilitaryTime);
            
            textOut[0] = hourText[0];
            textOut[1] = hourText[1];
            textOut[2] = minText[0];
            textOut[3] = minText[1];
        }
        
        return textOut;
    }

    function number2Text(numberIn, isHour, isMilitaryTime) {
        var textOut = [null,null];
        var tens = numberIn / 10;
        var units = numberIn % 10;
        
        var isHourIdx = (isHour)?1:0;
        
        if (numberIn == 0)
        {
            if (isHour)
            {
                if (isMilitaryTime)
                {
                    textOut[1] = "zero";
                }
                else
                {
                    textOut[0] = "twenty";
                    textOut[1] = "four";
                }
            }
            else
            {
                if (isMilitaryTime)
                {
                    textOut[0] = "hundred";
                }
                else
                {
                    textOut[0] = "o'clock";
                }
            }
        }
        else if (numberIn < 10)
        {
            if (isHour)
            {
                textOut[isHourIdx] = (isMilitaryTime)?"zero ":"";
                textOut[isHourIdx] += unitString[units];
            }
            else
            {
                textOut[isHourIdx] = "oh " + unitString[units];
            }
        }
        else if (numberIn < 20)
        {
            textOut[isHourIdx] = teenString[units];
        }
        else if (units == 0)
        {
            textOut[isHourIdx] = tenString[tens];
        }
        else
        {
            textOut[0] = tenString[tens];
            textOut[1] = unitString[units];   
        }

        return textOut;
    }
    
    function digit2Text(numberIn) {
        var textOut = null;
        
        if (numberIn == 0)
        {
        	textOut = "zero";
        }
        else if (numberIn < 10)
        {
            textOut = unitString[numberIn];
        }

        return textOut;
    }
}