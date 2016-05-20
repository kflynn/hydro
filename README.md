ESP8266 hydroponics controller
==============================

This is code to let an ESP8266 controller manage a small hydroponics garden.

You'd like to think that this would be mindnumbingly simple, and in one respect you'd be correct: NodeMCU makes a _lot_ of this stuff really easy. 

On the other hand, the moment computers have to handle the passage of time, life gets pretty miserable, and this is no exception. Most of the complexity here is:

1. Sync the clock using NTP, but only when we need to.

2. Manage the fact that the pump cycles happen on scales of hours, while the RTC needs attention on scales of seconds.

3. Don't leave the controller running when there's nothing to do. (This is kind of unnecessary for this project, since the pump runs on mains current anyway, but it's the right habit to be in for IoT stuff.)

Note that the ESP8266 doesn't actually have a Real Hardware RTC. This implies that we need to sync to NTP more often than we'd otherwise need to, and further implies that we have to take special care to make sure we sync at least once after the first dsleep cycle.
