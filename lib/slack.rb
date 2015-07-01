class SlackAPI
  require 'faraday'
  require 'json'
  attr_accessor :token

  def initialize(token)
	@token = token

	unless @client
	  @client = Faraday::Connection.new(:url =>'https://slack.com') do |builder|
		builder.adapter  :net_http
		# builder.response :logger
	  end
	end
  end

  def channels
	self.channels_list if @channels.nil?
	@channels
  end

  def channels_list
	res = JSON.parse(@client.get("/api/channels.list", { :token => @token }).body)
	return nil unless res["ok"]
	@channels = res["channels"]
  end

  def chat_post_message(args = {})
	args[:token] = @token if args[:token].nil?
	JSON.parse(@client.get("/api/chat.postMessage", args).body)
  end
end

