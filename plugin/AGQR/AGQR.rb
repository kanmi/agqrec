# coding: utf-8
module AGQR
  require 'fileutils'
  require 'date'
  require "net/http"
  require "kconv"
  require "oga"
  require "chronic"

  module ::Oga
    module XML
      class Node
        def children_without_text
          self.tap { |_| break _.children.to_a - _.text_nodes.to_a }.select{ |_| _.class == Oga::XML::Element }
        end
      end
    end
  end

  class << self
    def schedules
      @schedules ||= update_schedules
    end

    def fetch_timetable(uri = 'http://www.agqr.jp/timetable/streaming.html', limit = 10)
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      response = Net::HTTP.get_response(URI.parse(uri))
      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        fetch_timetable(response['location'], limit - 1)
      else
        response.value
      end
    end

    def update_schedules(force: true)
      if force || Dir.exists?(Config.tmp_path)
        if File.exists? 'agqr_schedules.json'
          return @schedule = JSON.parse(File.join(Config.tmp_path, 'agqr_schedules.json'))
        end
      else
        FileUtils.mkdir_p Config.tmp_path
      end

      doc = Oga.parse_html(fetch_timetable().body.force_encoding("UTF-8"))
      rowspans = doc.css(".title-p").map { |_| _.parent.attribute("rowspan").tap { |attr| break attr ? attr.value.to_i : 1 } }
      wd_index = []
      wd = [0] * 7

      l = rowspans.clone
      while !l.empty?
        wd.each.with_index do |_, i|
          if _ == 0 && !l.empty?
            wd_index << i
            wd[i] += l.shift
          end
        end
        wd.map! { |_| _ - 1 } while !wd.include?(0)
      end

      weekdays = %w(Mon Tue Wed Thu Fri Sat Sun)
      @schedules = doc.css(".title-p").map.with_index { |schedule, i|
        schedule = schedule.parent.children_without_text
        time_node  = schedule.find { |_| _.attribute('class').value.split.include?('time') }
        rp_node    = schedule.find { |_| _.attribute('class').value.split.include?('rp') }
        title_node = schedule.find { |_| _.attribute('class').value.split.include?('title-p') }.tap { |_|
          break _.children_without_text.first unless _.children_without_text.first.nil?
          break _.children.first
        }

        time = Chronic.parse(time_node.text.strip).strftime("%H:%M")
        weekday = (time_node.text.strip =~ /^\d:\d\d$/) ? weekdays[(wd_index[i]+1)%7] : weekdays[wd_index[i]]
        {
          at: "#{weekday} #{time}",
          title: title_node.text.strip.toutf8,
          url: title_node.class != Oga::XML::Text ? title_node.attribute("href").value.strip : "",
          personality: rp_node.text.strip.toutf8,
          email: rp_node.children_without_text.first.tap { |_| break _.nil? ? "" : _.attribute("href").value.strip.sub(/^mailto:/, "") },
          length: rowspans[i] * 30
        }
      }

      File.write(File.join(Config.tmp_path, 'agqr_schedules.json'), JSON.pretty_generate(@schedules))
      @schedules
    end
  end

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
               time:   Chronic.parse(schedule[:at]).strftime(Config.time_format),
               length: schedule[:length].to_i * 60 + schedule[:margin].to_i * 2
             })
      
    end
  end

  extend Methods
end
