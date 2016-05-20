-- Example wifi.lua. Very complex, huh?

table.insert(INITHOOKS.both, function()
  print('Starting WiFi...')

  wifi.setmode(wifi.STATION)
  wifi.sta.config("my-ssid", "my-key")
end)
