module AGQR
  require 'fileutils'
  require 'date'
  
  module Methods
    def init
      ::Config.add_field(name, {})
      ::Config.AGQR[:stream_url] ||= 'rtmp://fms-base1.mitene.ad.jp/agqr/aandg22'
      ::Config.AGQR[:rtmp_cmd]       ||= "rtmpdump -q -r #{Config.AGQR[:stream_url]} --live -B %{length} -o '#{Config.save_path}'"
      ::Config.AGQR[:rtmp_cmd_sound] ||= "rtmpdump -q -r #{Config.AGQR[:stream_url]} --live -B %{length} | ffmpeg -loglevel quiet -i pipe:0 -acodec copy #{Config.save_path}"
      ::Config.AGQR
    end

    def run(schedule)
      save_dir = File.dirname(Config.save_path) % { title: schedule[:title] }
	  FileUtils.mkdir_p(save_dir) unless Dir.exists?(save_dir)

	  system((schedule[:sound_only] ? ::Config.AGQR[:rtmp_cmd_sound] : ::Config.AGQR[:rtmp_cmd]) % {
               title:  schedule[:title],
               ext:    schedule[:sound_only] ? 'aac' : 'flv',
               time:   DateTime.parse(schedule[:at]).strftime(Config.time_format),
               length: schedule[:length].to_i * 60 + schedule[:margin].to_i * 2
             })
      
    end
  end

  extend Methods
end
