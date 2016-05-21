uart.setup(0, 115200, 8, 0, 1, 1)

print("---- init.lua running")

print('MAC Address: ', wifi.sta.getmac())
print('Chip ID:     ', node.chipid())
print('Heap Size:   ', node.heap())
print('Boot Reason: ', node.bootreason())
print('RTC:         ', rtctime.get(), '\n')

gpio.mode(6, gpio.INPUT, gpio.PULLUP)

RTCMEM_SLOT_LASTSYNC = 21
RTCMEM_SLOT_DSLEEPSYNC = 22
RTCMEM_SLOT_STATE = 23

INITHOOKS = {
  cold = {
    function ()
      print("...reset RTC sync info")
      rtcmem.write32(RTCMEM_SLOT_LASTSYNC, 0)
      rtcmem.write32(RTCMEM_SLOT_DSLEEPSYNC, 0)
    end,
    function ()
      -- Prepare the rtcfifo if not already done
      if rtcfifo.ready() == 0 then
        print("...prepare FIFO")
        rtcfifo.prepare({ interval_us = to_usec(10) })
      else
        print("...FIFO is ready")       
      end
    end
  },
  warm = {},
  both = {}
}

function to_usec(x) return x * 1000000 end
function to_msec(x) return x * 1000    end

-- function halt_now() rtctime.dsleep_aligned(to_usec(10), to_usec(2)) end
-- function halt_now() rtctime.dsleep(to_usec(30)) end
function halt_now()
  tmr.alarm(3, to_msec(10), tmr.ALARM_SINGLE, function () state:run() end)
end

function halt()
  print("Sleep at ", rtctime.get())

  if not tmr.alarm(2, 1000, tmr.ALARM_SINGLE, halt_now) then
    halt_now()
  end
end

if gpio.read(6) == 1 then
  State = loadfile("State.lc")()
  dofile("utils.lc")

  -- NOTE WELL: wifi.lc isn't checked in to avoid committing WiFi keys. enduserconfig
  -- might be an option here, too.
  --
  -- wifi.lc can be basically anything that gets WiFi running. Take your pick.
  dofile("wifi.lc")

  dofile("main.lc")
else
  print("HALT pin low")
end

bootkey = "warm"

if node.bootreason() == 1 then
  bootkey = "cold"
end

print("BOOT: " .. bootkey)

for idx, hook in ipairs(INITHOOKS[bootkey]) do
  hook()
end

for idx, hook in ipairs(INITHOOKS.both) do
  hook()
end