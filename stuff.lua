

function halt_now() rtctime.dsleep_aligned(to_usec(10), to_usec(2)) end

function halt()
  print("Sleep at ", rtctime.get())

  if not tmr.alarm(0, 1000, tmr.ALARM_SINGLE, halt_now) then
    halt_now()
  end
end

function dsync_then_halt()
  sec, usec = rtctime.get()
  rtcmem.write32(RTCMEM_SLOT_DSLEEPSYNC, sec)
  halt()
end

function ntp_sync_then_halt()
  ntp_sync(halt)
end

function ntp_dsync_then_halt()
  ntp_sync(dsync_then_halt)
end


function main()
  need_sync = false
  callback = halt

  if node.bootreason() == 1 then
    print("Cold boot: need sync")    
    need_sync = true
    callback = ntp_sync_then_halt
  else
    last_sync = rtcmem.read32(RTCMEM_SLOT_LASTSYNC)
    dsleep_sync = rtcmem.read32(RTCMEM_SLOT_DSLEEPSYNC)

    print("Warm boot: last sync ", last_sync, "dsleep_sync", dsleep_sync)

    if dsleep_sync == 0 then
      print("Warm boot but no dsleep_sync, need sync")
      need_sync = true
      callback = ntp_dsync_then_halt
    else
      if last_sync == 0 then
        print("Warm boot but no last_sync?? need sync")
        need_sync = true
        callback = ntp_sync_then_halt
      else 
        now_sec, now_usec = rtctime.get()
        delta = now_sec - last_sync

        if delta >= 3600 then
          print("Warm boot and last sync " .. delta .. " sec ago, need sync")
          need_sync = true
          callback = ntp_sync_then_halt
        end
      end
    end
  end

  if need_sync then
    wait_for_wifi(callback)
  else
    callback()
  end
end