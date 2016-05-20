function run_state4()
  -- This is actually the main resting state, as it were. We land here when
  -- we've gotten the RTC initialized, including NTP and at least one dsleep
  -- with recalibration, so we have a time reference _but we may well not be
  -- actually connected to WiFi yet_.

  local sec, usec = rtctime.get()
  local lastsync = rtcmem.read32(RTCMEM_SLOT_LASTSYNC)
  local delta = sec - lastsync

  print("== 4: warm boot at " .. sec .. ", last sync " .. delta .. " ago")

  if delta > 3600 then
    print("== 4: resyncing")
    state:to_state(1)
  else
    print("== 4: waiting for WiFi for marker")
    async_to_state("WiFi", wait_for_wifi, 5, 4)
  end
end

function run_state5()
  local sec, usec = rtctime.get()

  print("== 5: sending marker at " .. sec)

  conn = net.createConnection(net.UDP, 0)

  conn:on("sent", function(conn)
    print ("allegedly sent")

    conn:close()

    tmr.alarm(1, 50, 0, function ()
      print ("going to sleep")
      state:queue(0)
      state:queue(4)

      if not state.running then
        state:run()
      end
    end)
  end)

  conn:connect(9998, "172.31.0.212")
  conn:send("ESP8266 " .. node.chipid() .. " MARK " .. sec)
end

state = State.init({
  enter1 = function ()
    print("== 1: wait for WiFi, then NTP")
    async_to_state("WiFi", wait_for_wifi, 2, 100)
  end,

  enter100 = function ()
    print("== critical failure, hoping for better later")
    state:queue(0)
    state:queue(1)
  end,

  enter2 = function ()
    print("== 2: wait for NTP")
    async_to_state("NTP", ntp_sync, 3, 100)
  end,

  enter3 = function ()
    if state.after_dsleep then
      print("== 3: NTP good, marking dsleep OK")
      local sec, usec = rtctime.get()
      rtcmem.write32(RTCMEM_SLOT_DSLEEPSYNC, sec)
    else
      print("== 3: NTP good")
    end

    state:queue(0)
    state:queue(4)
  end,

  enter4 = function ()
    if rtcmem.read32(RTCMEM_SLOT_DSLEEPSYNC) == 0 then
      print("== 4: repeat sync after dsleep")
      state.after_dsleep = true
      state:to_state(1)
    else
      run_state4()
    end
  end,

  loop4 = function ()
    run_state4()
  end,

  enter5 = function ()
    run_state5()
  end
})

table.insert(INITHOOKS.cold, function ()
  print("...reset state")
  state:reset()
end)

table.insert(INITHOOKS.warm, function ()
  print("...reload state")
  state:reload()
end)

table.insert(INITHOOKS.both, function()
  print("...initializing pump")
  gpio.mode(5, gpio.OUTPUT)
  gpio.write(5, gpio.LOW)
end)

table.insert(INITHOOKS.both, function()
  if state:queue_is_empty() then
    print("...empty state machine queue, inject state 1")
    state:queue(1)
  end

  print("...starting state machine")
  state:run()
end)
