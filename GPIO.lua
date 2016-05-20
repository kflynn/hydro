-- GPIO class
GPIO = {}
GPIO.__index = GPIO

function GPIO.init(pin, on_is_low)
  local obj = {}
  setmetatable(obj, GPIO)
  obj.pin = pin
  obj.on_value = on_is_low and gpio.LOW or gpio.HIGH
  obj.off_value = on_is_low and gpio.HIGH or gpio.LOW

  gpio.mode(pin, gpio.OUTPUT)

  obj:off()
  return obj
end

function GPIO:on()
  self.state = 1
  gpio.write(self.pin, self.on_value)
end

function GPIO:off()
  self.state = 0
  gpio.write(self.pin, self.off_value)
end

function GPIO:toggle()
  -- print("Toggle, state ", self.state)
  if self.state == 1 then
    self:off()
  else
    self:on()
  end
end

function GPIO:start_toggling(which_timer, msec)
  self.timer = which_timer
  tmr.alarm(which_timer, msec, 1, function ()
    self:toggle()
  end)
end

function GPIO:stop_toggling(final_state)
  tmr.stop(self.timer)
  self.timer = nil

  if final_state then
    self:on()
  else
    self:off()
  end
end

-- end GPIO class

return GPIO
