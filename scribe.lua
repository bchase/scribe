-- extension description
function descriptor()
  return { 
    title = "Scribe",
    version = "0.1",
    author = "Brad Chase",
    url = 'http://webappfromscratch.com/author/',
    shortdesc = "Sends a screenshot and its subtitle text to a web service",
    description = "Sends a screenshot and its subtitle text to a web service",
    capabilities = {}
  }
end

-- start extention
function activate()
  --vlc.msg.info("[Scribe] Activating\n")
  -- [ ] register hotkey

  -- [ ] pause
  
  -- [X] get subtitle text
    -- [X] parse .ass
    -- [.] parse .srt
  -- [X] generate ss name
  -- [X] take screenshot 
  
  -- [ ] play
  
  -- [\] find new screenshot file
    -- [\] detect OS
    -- [\] set proper ss dir path
    -- [X] get latest screenshot path
  -- [\] POST sub text and image to service
  
  subtitles = parse_subtitles()
  print("Parsed "..#subtitles.." subtitles.")

	time_num      = time_num()
  sub_delay_num = sub_delay_num()
  sub_time_num  = time_num + sub_delay_num

  sub_text = get_subtitle_for_time_num(sub_time_num, subtitles)
  print("Subtitle text: "..sub_text)

  print('1')
  file_name = get_screenshot_file_name()
  print(file_name)
  screenshot()
  print('2')
  image_file = get_screenshot_file(file_name)
  print('3')

  post_to_service(sub_text, image_file)
  print('4')
end

function screenshot()
  local vout = vlc.object.vout()
  if not vout then return end
  vlc.var.set(vout,"video-snapshot",nil)
end

function get_screenshots_dir_path()
  ver = io.popen('ver'):read("*a")
  if string.find(ver, "Windows") then
    -- WINDOWS TODO
    return "My Documents\\My Pictures \\"
  else
    uname = io.popen('uname'):read("*a")
    user  = io.popen('whoami'):read("*a")
    user  = string.gsub(user, "\r$", "")
    user  = string.gsub(user, "\n$", "")
    if string.find(uname, 'Linux') then
      -- LINUX
      return "/home/"..user.."/Pictures/"
    elseif string.find(uname, 'Mac') then
      -- MAC TODO + user
      return "Pictures/"
    end
  end
end

function get_screenshot_file_name()
  -- "vlcsnap-YYYY-MM-DD-HHhMMmSSs.png"
  -- TODO !!! handle case of split second
  file_name = os.date("vlcsnap-%Y-%m-%d-%Hh%Mm%Ss")
  return file_name
end

function get_screenshot_file(file_name)
  ss_dir    = get_screenshots_dir_path()
  file      = nil
  file_path = nil

  i = 999
  while i >= 0 and not file do
    test_fname = file_name..i..".png"
    file_path  = ss_dir..test_fname
    file       = io.open(file_path)

    if file then 
      print("Screenshot file:"..file_path)
      return file 
    end

    i          = i - 1
  end
end

function get_subtitle_for_time_num(time_num, subtitles)
  for times, text in pairs(subtitles) do
    start_num  = times[1]
    finish_num = times[2]

    if (time_num >= start_num) and (time_num <= finish_num) then
      return text
    end
  end
end

function parse_subtitles()
  file_path_and_extension = get_subtitle_file_path()

  if not file_path_and_extension then return end

  file_path = file_path_and_extension[1]
  extension = file_path_and_extension[2]

  subtitles = {}

  if     extension == '.ass' then
    subtitles = parse_ass_subtitles(file_path)
  elseif extension == '.srt' then
    subtitles = parse_srt_subtitles(file_path)
  end

  return subtitles
end

function parse_ass_subtitles(file_path)
  -- e.g. -- Dialogue: 0,0:00:00.82,0:00:02.42,JP,,0000,0000,0000,,  何言ってんだか
  subtitles = {}
  
  for line in io.lines(file_path) do
    if string.find(line, "^Dialogue") then
      timestamp_pattern = "%d+:%d+:%d+\.%d+,%d+:%d+:%d+\.%d+"

      timestamps = string.sub(line, string.find(line, timestamp_pattern))

      start  = string.sub(timestamps, 1, 10)
      finish = string.sub(timestamps, 12, 21)

      start_num  = ass_timestamp_to_number(start)
      finish_num = ass_timestamp_to_number(finish)

      times = {start_num, finish_num}

      text = string.sub(line, string.find(line, ",,.+$"))

      --subtitle = {start_num, finish_num, text}
      --table.insert(subtitles, #subtitles+1, subtitle)

      subtitles[times] = text
    end
  end

  return subtitles
end

function ass_timestamp_to_number(timestamp)
  hour = string.sub(timestamp, 1, 1)
  min  = string.sub(timestamp, 3, 4)
  sec  = string.sub(timestamp, 6, 7)
  mil  = string.sub(timestamp, 9, 10)

  return timestamp_to_number(hour, min, sec, mil)
end

function parse_srt_subtitles(file_path)
  print('parse srt subs')
  -- e.g. ...
  -- 4
  -- 00:00:23,830 --> 00:00:26,330
  -- 握らせてもらったよ。
  
  subtitles = {}

  times = nil
  
  for line in io.lines(file_path) do
    print(line)
    line = string.gsub(line, "\r$", "")
    line = string.gsub(line, "\n$", "")
    print(string.len(line))

    if string.find(line, "^%d+:%d+:%d+,%d+") then
      print('timestamp:')
      print(line)

      -- TODO
      timestamp_pattern = "%d+:%d+:%d+\.%d+ --> %d+:%d+:%d+\.%d+"

      timestamps = string.sub(line, string.find(line, timestamp_pattern))

      -- TODO
      start  = string.sub(timestamps, 1, 10)
      finish = string.sub(timestamps, 12, 21)

      start_num  = ass_timestamp_to_number(start)
      finish_num = ass_timestamp_to_number(finish)

      times = {start_num, finish_num}
    elseif string.find(line, "^%d+$") or string.find(line, "^$") then
      print('skip:')
      print(line)
      -- NO-OP
    else
      print('text:')
      print(line)
      -- if line is not empty and not just a number...
      subtitles[times] = line
    end
  end

  return subtitles
end

function srt_timestamp_to_number(timestamp)
  hour = string.sub(timestamp, 1, 2)
  min  = string.sub(timestamp, 4, 5)
  sec  = string.sub(timestamp, 7, 8)
  mil  = string.sub(timestamp, 10, 12)

  return timestamp_to_number(hour, min, sec, mil)
end

function timestamp_to_number(hour, min, sec, mil)
  num = 0
  num = num + (tonumber(hour) * 3600)
  num = num + (tonumber(min)  * 60)
  num = num + (tonumber(sec))
  num = num + (tonumber("."..mil))
  return num
end

function sub_delay_num()
  return vlc.var.get(vlc.object.input(), 'spu-delay')
end

function time_num()
	return vlc.var.get(vlc.object.input(), "time")
end

function get_video_uri()
  local video_uri = vlc.input.item():uri()
  video_uri = vlc.strings.decode_uri(video_uri)
  return video_uri
end

function get_subtitle_file_path()
  local video_uri = get_video_uri()
  local extensions = {'.ass','.srt'}
  local sub_file_name = string.gsub(video_uri, "^.-///(.*)%..-$","%1")

  for index, extension in pairs(extensions) do
    sub_full_path = sub_file_name..extension
    file = io.open(sub_full_path,'r')

    if file then 
      return {sub_full_path, extension}
    end

    sub_full_path = "/"..sub_file_name..extension
    file = io.open(sub_full_path,'r')

    if file then 
      return {sub_full_path, extension}
    end
  end

  print('found no subtitle file...')
end

function post_to_service(sub_text, image_file)
  print('Sending file and text... ')
  http  = require('socket.http')
  ltn12 = require('ltn12')

  file_size = image_file:seek("end")
  print(file_size)

  image_file:seek("set", 0) -- rewind file

  print('before request')
  http.request {
    url     = 'http://localhost:3000/',
    method  = 'POST',
    headers = {
      ['Content-Type']   = 'multipart/form-data',
      ['Content-Length'] = file_size
    },
    source  = ltn12.source.file(file),
    sink    = ltn12.sink.table(response_body)
  }
  print('File sent!')
end

--function input_callback(action)  -- action=add/del/toggle
--  vlc.msg.info("[Scribe] assigning callback\n")
--  -- action = 'add'
--	local input = vlc.object.input()
--  if input then
--    vlc.var.add_callback(input, "intf-event", input_events_handler, "Hello world!")
--    vlc.msg.info("[Scribe] callback assigned\n")
--  end
--end
--
--function input_events_handler(var, old, new, data)
--  vlc.msg.info("[Scribe] here\n")
--	if new==4 then  -- 4 ~ INPUT_EVENT_POSITION 
--		local input = vlc.object.input()
--		if input then
--      local time = vlc.var.get(input, "time")
--      vlc.msg.info("[Scribe] "..time.."\n")
--		end
--	end
--end

-- sub_delay = vlc.var.get(vlc.object.input(), 'spu-delay')
-- subtitle = pcall(vlc.var.libvlc_command, libvlc_video_get_spu)
-- vlc.var.command(vlc.object, 'snapshot')

-- "I will not install luasocket but liblua5.1-socket2 instead"
  -- After this operation, 244 kB of additional disk space will be used.

--activate()
