guard 'livereload' do
  watch("app.rb")
  watch("config.ru")
  watch(%r{(lib|plugin|views|public)/.+\.(rb|erb|js|css)$})
end

guard :shotgun, server: "thin", host: "127.0.0.1", port: "9292" do; end
