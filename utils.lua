function wait_for_wifi(callback)
  local tries = 10

  tmr.alarm(1, 1000, 1, function ()
    if wifi.sta.getip() == nil then
      tries = tries - 1

      if tries <= 0 then
        print("wait_for_wifi: giving up")
        tmr.stop(1)
        callback(false)
      else 
        print("wait_for_wifi: waiting...")
      end
    else
      ip, nm, gw = wifi.sta.getip()
      print("IP Info:")
      print("  IP Address: ", ip)
      print("  Netmask:    ", nm)
      print("  Gateway:    ", gw, '\n')

      tmr.stop(1)
      callback(true)
    end
  end)
end

function async_to_state(what, fn, success_state, fail_state)
  fn(function (status)
    if status then
      print("=== " .. what .. " OK => " .. success_state)
      state:to_state(success_state)
    else
      print("=== " .. what .. " failed => " .. fail_state)
      state:to_state(fail_state)
    end
  end)
end

function ntp_sync(callback)
  sntp.sync("time.apple.com",
    function (sec, usec, server) 
      print("NTP sync good! ", sec, usec, server)
      rtcmem.write32(RTCMEM_SLOT_LASTSYNC, sec)

      callback(true)
    end,
    function (err)
      print("NTP sync failed: ", err)

      callback(false)
    end
  )
end
