require 'yaml'
require 'bundler'
Bundler.require
require 'angelo/tilt/erb'

class Devsummit < Angelo::Base
  include Angelo::Tilt::ERB

  before do
    @gt = Geotrigger::Application.new YAML.load_file 'geotrigger.yml'
  end

  get '/' do
    @trigger_list = @gt.post 'trigger/list', boundingBox: :geojson
    @host = 'esri.nakamura.io'
    erb :index
  end

  post '/trigger_callback' do
    msg = { triggerId: params['trigger']['triggerId'] }.to_json
    websockets.each do |ws|
      ws.write msg
    end
  end

  socket '/callbacks' do |ws|
    websockets << ws
    begin
      while msg = ws.read do
        ws.write 'pong' if msg == 'ping'
      end
    rescue Reel::SocketError => rse
      ws.close
    end
  end

end

Devsummit.run
