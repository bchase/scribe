-- extension description
function descriptor()
  return { 
    title = "Scribe",
    version = "0.1",
    author = "Brad Chase",
    url = 'http://webappfromscratch.com/author/',
    shortdesc = "Adds subtitle text to screenshot metadata",
    description = "Adds subtitle text to screenshot metadata",
    capabilities = {}
  }
end

subtitles = {}

-- start extention
function activate()
  --vlc.msg.info("[Scribe] Activating\n")
  -- [ ] register hotkey
  
  screenshot()
  --input_callback('add')
end

function screenshot()
  -- [ ] pause
  -- [.] get subtitle text
  -- [X] take screenshot -- vlc.var.command(vlc.object, 'snapshot')
  -- [ ] play
 
  -- [ ] load screenshot
  -- [ ] write metadata
  -- [ ] POST to server image
  
  line = "Dialogue: 0,0:00:00.82,0:00:02.42,JP,,0000,0000,0000,,  何言ってんだか"
  parse_ass_subtitles('/home/bosco/Downloads/sao/sao04.ass')
  print(#subtitles)
  print(subtitles[#subtitles-1][3])
end

function input_callback(action)  -- action=add/del/toggle
  vlc.msg.info("[Scribe] assigning callback\n")
  -- action = 'add'
	local input = vlc.object.input()
  if input then
    vlc.var.add_callback(input, "intf-event", input_events_handler, "Hello world!")
    vlc.msg.info("[Scribe] callback assigned\n")
  end
end

function input_events_handler(var, old, new, data)
  vlc.msg.info("[Scribe] here\n")
	if new==4 then  -- 4 ~ INPUT_EVENT_POSITION 
		local input = vlc.object.input()
		if input then
      local time = vlc.var.get(input, "time")
      vlc.msg.info("[Scribe] "..time.."\n")
		end
	end
end

function parse_subtitles()
  file_path, extension = get_subtitle_file_path()
  if     extension == '.ass' then
    subtitles = parse_ass_subtitles(file_path)
  elseif extension == '.srt' then
    subtitles = parse_srt_subtitles(file_path)
  end
end

function parse_ass_subtitles(file_path)
  -- e.g. -- Dialogue: 0,0:00:00.82,0:00:02.42,JP,,0000,0000,0000,,  何言ってんだか
  
  for line in io.lines(file_path) do
    if string.find(line, "^Dialogue") then
    timestamp_pattern = "%d+:%d+:%d+\.%d+,%d+:%d+:%d+\.%d+"

    timestamps = string.sub(line, string.find(line, timestamp_pattern))

    start  = string.sub(timestamps, 1, 10)
    finish = string.sub(timestamps, 12, 21)

    start_num  = ass_timestamp_to_number(start)
    finish_num = ass_timestamp_to_number(finish)

    print(line)
    text = string.sub(line, string.find(line, ",,.+$"))

    subtitle = {start_num, finish_num, text}

    table.insert(subtitles, #subtitles+1, subtitle)
    end
  end
end

function ass_timestamp_to_number(timestamp)
  hour = string.sub(timestamp, 1, 1)
  min  = string.sub(timestamp, 3, 4)
  sec  = string.sub(timestamp, 6, 7)
  mil  = string.sub(timestamp, 9, 10)

  return timestamp_to_number(hour, min, sec, mil)
end

function parse_srt_subtitles(file_path)
  -- e.g. ...
  -- 4
  -- 00:00:23,830 --> 00:00:26,330
  -- 握らせてもらったよ。
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
  print(num)
  return num
end

function sub_delay_num()
  return vlc.var.get(vlc.object.input(), 'spu-delay')
end

function get_video_uri()
  local video_uri = vlc.input.item():uri()
  video_uri = vlc.strings.decode_uri(video_uri)
  return video_uri
end

function get_subtitle_file()
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
end

-- sub_delay = vlc.var.get(vlc.object.input(), 'spu-delay')
-- subtitle = pcall(vlc.var.libvlc_command, libvlc_video_get_spu)

activate()
