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

-- start extention
function activate()
  -- register hotkey
    -- to  call screenshot()
end

-- take screenshot/write metadata
function screenshot()
  -- get subtitle text
  -- take screenshot
  -- load screenshot
  -- write metadata
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
      return file 
    end

    sub_full_path = "/"..sub_file_name..extension
    file = io.open(sub_full_path,'r')

    if file then 
      return file 
    end
  end
end

-- subtitle = vlc.var.libvlc_command("libvlc_video_get_spu", vlc.object.libvlc())
