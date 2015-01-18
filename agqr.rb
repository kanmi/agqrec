# coding: utf-8
require 'clockwork'
require 'json'
require 'time'
require 'pathname'
require 'active_support/core_ext/numeric/time'
require './lib/slack'

#AGQR_STREAM_URL = 'rtmp://fms-base1.mitene.ad.jp/agqr/aandg11'
AGQR_STREAM_URL = 'rtmp://fms-base1.mitene.ad.jp/agqr/aandg22'
DATA_DIR = File.expand_path("#{File.dirname(__FILE__)}/data")
MARGIN = 15

AGQR = "rtmpdump -q -r #{AGQR_STREAM_URL} --live -o '%s' -B %s 2>&1 >/dev/null"

module Clockwork
  schedule = JSON.load(File.read('./schedule.json'))
  slack = SlackAPI.new("xoxp-2358774485-2358774487-2894066442-f841bf")

  handler do |job, time|
	job = schedule.select { |e| e["title"] == job }[-1]
	puts "Running #{job["title"]}, at #{time}"

	Thread.start do
	  sleep(60-(MARGIN%60))
	  Thread.start do
	  slack.chat_post_message( username: "agqr_bot",
							   icon_url: "http://agqr.jp/img/ag_icon.gif",
							   channel:  "#agqr", 
							   text:     "#{job['title']} の録画が始まったよ")
	  end

	  system(AGQR % [ "#{DATA_DIR}/#{job['title']}/[#{time.strftime '%Y-%m-%d'}] #{job['title']}.flv",
					  job["length"] * 60 + MARGIN*2 ])

	  slack.chat_post_message( username: "agqr_bot",
							   icon_url: "http://agqr.jp/img/ag_icon.gif",
							   channel:  "#agqr",
							   text:     "#{job['title']} の録画が終わったよ")
	end
  end

  schedule.each do |s|
	# mkdir and chmod it to 0777
	unless Dir.exists?("#{DATA_DIR}/#{s['title']}")
	  Dir.mkdir("#{DATA_DIR}/#{s['title']}")
	  File.chmod(0777, "#{DATA_DIR}/#{s['title']}")
	end

	every(1.week, s['title'], :at => (DateTime.parse(s['at']) - MARGIN.seconds).strftime("%A %R"))
  end
end
