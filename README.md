ESP8266 hydroponics controller
==============================

This is code to let an ESP8266 controller manage a small hydroponics garden.

You'd like to think that this would be mindnumbingly simple, and in one respect you'd be correct: NodeMCU makes a _lot_ of this stuff really easy. 

On the other hand, the moment computers have to handle the passage of time, life gets pretty miserable, and this is no exception. Most of the complexity here is:

1. Sync the clock using NTP, but only when we need to.

2. Manage the fact that the pump cycles happen on scales of hours, while the RTC needs attention on scales of seconds.

3. Don't leave the controller running when there's nothing to do. (This is kind of unnecessary for this project, since the pump runs on mains current anyway, but it's the right habit to be in for IoT stuff.)

Note that the ESP8266 doesn't actually have a Real Hardware RTC. This implies that we need to sync to NTP more often than we'd otherwise need to, and further implies that we have to take special care to make sure we sync at least once after the first dsleep cycle...

...except that these days we're just using `tmr.alarm()` instead of `rtctime.dsleep()` anyway, because using `dsleep()` resets the GPIO pin that we want to use as the relay output! So we'd need to use `tmr.alarm()` while the pump is running anyway... so forget it, we'll just use it all the time.

WiFi Stuff
----------

`init.lua` relies on `wifi.lc` to get WiFi running, but you might note that `wifi.lua` isn't checked in. That's intentional, because otherwise I'd be saving WiFi keys in GitHub.

You can look at `wifi-example.lua` for an example `wifi.lua`.

Running the system
------------------

- Provide a `wifi.lua`. 
- Edit pin numbers to taste in `main.lua`, towards the bottom.
- Plug in!

If the pin labelled GPIO12 on the board (NodeMCU pin 6 -- why did they DO that??) is pulled to ground, the system will _not_ actually start. This is a disaster-recovery utility.

Software design
---------------

On boot, `init.lua` gets control and creates the `INITHOOKS` table. Everything in the system that needs to run bootstrap code registers it in that table:

- `init.lua` uses it to initialize the RTC and the state FIFO
- `main.lua` uses it to:
   - get the state machine set up (again)
   - initialize the pump
   - finally start the state machine actually running

The state machine controls the world, and is asynchronous: see `State.lua` for more, but basically we use the ESP8266 RTC fifo to manage state transitions. We handle WiFi, NTP, and time in general with the state machine.

