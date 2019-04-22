using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Math;

// globals to manage state between classes
var homer_done = false;
var animation = null;

// global to manage fonts
var f_time = null;
var f_timebg = null;

// here's the animation delegate used to manage any animation events
var delegate = null;

class AnimationView extends WatchUi.WatchFace {

    // variables for time layout
    var dw;
    var dh;
    const font_height = 66;
    const vert_offset = 6;

    function initialize() {
        WatchUi.WatchFace.initialize();
    }

    // let's load the animation, and initialise the
    // delegate to manage any play events
    function loadAnimation() {
        animation = addAnimation(Rez.Drawables.homer, {:layer=>WatchUi.ANIMATION_DRAW_LAYER_FOREGROUND, :locX=>0, :locY=>0});
        delegate = new AnimationDelegate(method(:play));
    }

    // play the animation, and attach the pre-initialised delegate
    function play() {
        animation.play({:delegate=>delegate});
    }

    // wrapper to play the animation,
    // but let's first check if the animation exists, if not load it.
    function doAnimation() {
      if( animation == null ) {
          killFonts();
          loadAnimation();
      }
      play();
    }

    // load, and play the animation when the show event triggers
    function onShow() {
      doAnimation();
    }

    // we release any animaton resources onHide
    function onHide() {
        killAnimations();
        killFonts();
    }

    function onLayout(dc) {
        dw = dc.getWidth();
        dh = dc.getHeight();
    }

    // invoked when our animation is complete, or when sleep is triggered
    function onUpdate(dc) {

        // animation is done, let's display the time
        if (homer_done) {

          // we nuke the animation to free up enough memory
          // to load and render the background and time
          killAnimations();
          loadFonts();

          // here's where we load in the background,
          // which is the final frame of the animation
          var b_shrub = WatchUi.loadResource(Rez.Drawables.shrub);
          dc.drawBitmap(0,0,b_shrub);

          // render the time
          var s_time = fetchTime();
          var time_width = dc.getTextWidthInPixels(s_time, f_timebg);

          // figure out time extents
          var total_digits = s_time.length();
          var total_height = ((total_digits-1)*vert_offset)+font_height;

          // time x,y position
          var x_pos_time = (dw-time_width)/2;
          var y_pos_time = (dh-total_height)/2;
          var y_pos_start = y_pos_time+((total_digits-1)*vert_offset);

          // let's render the time, one digit at a time
          for (var next_digit = 0; next_digit<total_digits; next_digit++) {

            var current_numeral = s_time.substring(next_digit,next_digit+1);

            // render the background and foreground digits
            dc.setColor(0xffffff, Gfx.COLOR_TRANSPARENT);
            dc.drawText(x_pos_time, y_pos_start-(next_digit*vert_offset), f_timebg, current_numeral, Gfx.TEXT_JUSTIFY_LEFT);
            dc.setColor(0x000000, Gfx.COLOR_TRANSPARENT);
            dc.drawText(x_pos_time, y_pos_start-(next_digit*vert_offset), f_time, current_numeral, Gfx.TEXT_JUSTIFY_LEFT);

            x_pos_time = x_pos_time + dc.getTextWidthInPixels(current_numeral, f_timebg);

          }


        }


    }


    // fetch the time and return as a string
    function fetchTime() {

      // grab time objects
      var clockTime = System.getClockTime();
      var date = Time.Gregorian.info(Time.now(),0);

      // define time, day, month variables
      var hour = clockTime.hour;
      var minute = clockTime.min;

      var deviceSettings = System.getDeviceSettings();

      // 12-hour support
      if (hour > 12 || hour == 0) {
          if (!deviceSettings.is24Hour)
              {
              if (hour == 0)
                  {
                  hour = 12;
                  }
              else
                  {
                  hour = hour - 12;
                  }
              }
      }

      // add padding to units if required
      if( minute < 10 ) {
          minute = "0" + minute;
      }

      if( hour < 10 && deviceSettings.is24Hour) {
          hour = "0" + hour;
      }

      return hour.toString()+minute.toString();

    }

    // Let's kill all the animations.
    // clearAnimations() will clear all animations belong
    // to the view, and release the memory resources
    function killAnimations() {
      clearAnimations();
      animation = null;
    }

    // load the fonts for the time
    function loadFonts() {
      if (f_time == null && f_timebg == null) {
        f_time = WatchUi.loadResource(Rez.Fonts.chomp);
        f_timebg = WatchUi.loadResource(Rez.Fonts.chomp_solid);
      }
    }

    function killFonts() {
      f_time = null;
      f_timebg = null;
    }

    // The user has just looked at their watch.
    // Time to trigger the start of the animation.
    function onExitSleep() {
      homer_done = false;
      doAnimation();
    }

    // Terminate any active timers and prepare for slow updates.
    // Let's trigger an onUpdate() to show the time
    function onEnterSleep() {
      homer_done = true;
      WatchUi.requestUpdate();
    }


}

// use the AnimationDelegate to handle any animation events
class AnimationDelegate extends WatchUi.AnimationDelegate {

    var callback = null;

    function initialize(c) {
        callback = c;
        WatchUi.AnimationDelegate.initialize();
    }

    function onAnimationEvent(event, options) {

        switch(event) {

            // when the animation is done, trigger an
            // onUpdate() to show the time
            case ANIMATION_EVENT_COMPLETE:
              homer_done = true;
              WatchUi.requestUpdate();
              break;

              default:
              callback.invoke();

        }

    }

}
