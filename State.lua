-- State class
State = {}
State.__index = State

function State.init(machine)
  local obj = {}
  setmetatable(obj, State)
  obj.machine = machine
  obj.state = nil
  obj.running = false

  tmr.register(0, 1, tmr.ALARM_SEMI, function ()
    obj:run_loop()
  end)

  return obj
end

function State:queue_is_empty()
  return rtcfifo.count() == 0
end

function State:reset()
  self.state = 0
  self:rtc_write()
  print("State: reset to state 0")
end

function State:reload()
  self:rtc_read()
  print("State: reloaded into state " .. self.state)
end

function State:run()
  tmr.start(0)
end

function State:queue(next_state)
  rtcfifo.put(rtctime.get(), next_state, 0, "nxst")
end

function State:to_state(next_state)
  self:queue(next_state)

  if not self.running then
    self:run()
  end
end

function State:run_loop()
  -- runs only when triggered by timer 0, which is generally started with :run

  print(rtctime.get() .. ": run loop starting")

  self.running = true

  while rtcfifo.count() > 0 do
    local timestamp, value, scale, name = rtcfifo.pop()

    print(timestamp, value, scale, name)

    if name == "nxst" then
      cur_state = self.state
      next_state = value

      if next_state == 0 then
        print("STATE 0: sleep, baby, sleep")
        halt()
        return
      end

      if next_state == cur_state then
        print("loop " .. cur_state)

        loop_name = "loop" .. cur_state
        loop_func = self.machine[loop_name]

        if loop_func then
          loop_func(cur_state)
        end
      else
        print("leave " .. cur_state .. " for " .. next_state)

        exit_name = "exit" .. cur_state
        exit_func = self.machine[exit_name]

        enter_name = "enter" .. next_state
        enter_func = self.machine[enter_name]

        if exit_func then
          exit_func(next_state)
        end

        self.state = next_state
        self:rtc_write()

        if enter_func then
          enter_func(cur_state)
        end
      end
    end
  end

  self.running = false

  print(rtctime.get() .. ": run loop ended")
end

function State:rtc_write()
  rtcmem.write32(RTCMEM_SLOT_STATE, self.state)
end  

function State:rtc_read()
  self.state = rtcmem.read32(RTCMEM_SLOT_STATE)
end  

-- end State

return State
