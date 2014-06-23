require 'yaml'
require 'time'
require 'pathname'
require 'active_support/core_ext/numeric/time'

AGQR_STREAM_URL = 'rtmp://fms-base1.mitene.ad.jp/agqr/aandg2'
DATA_DIR = File.expand_path("#{File.dirname(__FILE__)}/data")
MARGIN = 15

job_type :AGQR, "sleep :wait; rtmpdump -r #{AGQR_STREAM_URL} --live -o :task -B :length"

YAML.load_file('./schedule.yaml').each do |s|
  next unless s['record']
  every s['wday'].to_sym, :at => (Time.parse(s['time'])-MARGIN.seconds).strftime('%R') do
    AGQR "#{DATA_DIR}/#{s['title']}-`date '+\%Y\%m\%d'.flv`", :length => s['length'] * 60 + MARGIN, :wait => 60 - (MARGIN%60)
  end
end
