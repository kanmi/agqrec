module AGQR
  require 'fileutils'

  module Methods
    def init
      ::Config.add_field(name, {})
      ::Config.AGQR[:stream_url] ||= 'rtmp://fms-base1.mitene.ad.jp/agqr/aandg22'
      ::Config.AGQR[:rtmp_cmd]       ||= "rtmpdump -q -r #{Config.AGQR[:stream_url]} --live -o '#{Config.save_path}' -B %s 2>&1 >/dev/null"
      ::Config.AGQR[:rtmp_cmd_sound] ||= "rtmpdump -q -r #{Config.AGQR[:stream_url]} --live -B %s 2>/dev/null | ffmpeg -i pipe:0 -acodec copy -f #{Config.save_path}"
      ::Config.AGQR
    end

    def record(schedule)
	  unless Dir.exists?(File.dirname(Config.save_path))
	    FileUtils.mkdir_p(File.dirname(Config.save_path))
	  end

	  system(AGQR % [ Config.save_path % {},
					  schedule[:length] * 60 + MARGIN*2 ])
      
    end
  end

  extend Methods
end
