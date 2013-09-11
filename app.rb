require 'twilio-ruby'
require 'sinatra'

module CurrentCall

  class << self
    def sid
      IO.read("tmp/current_call").chomp rescue ""
    end

    def sid=(call_sid)
      IO.write("tmp/current_call", call_sid)
    end
  end

end

class App < Sinatra::Base

  configure do
    enable :logging
    set :account_sid, ENV["ACCOUNT_SID"]
    set :auth_token, ENV["AUTH_TOKEN"]
    set :queue_name, "queue_name"
  end

  before do
    logger.info "params: #{params.inspect}"
    logger.info "CurrentCall.sid = #{CurrentCall.sid}"
  end

  after do
    logger.info "response.body: #{response.body}"
  end

  get '/:client_name' do
    capability = Twilio::Util::Capability.new settings.account_sid, settings.auth_token

    capability.allow_client_incoming params[:client_name]
    token = capability.generate
    erb :index, :locals => {:token => token}
  end

  post '/voice' do
    CurrentCall.sid = params["CallSid"]

    response = Twilio::TwiML::Response.new do |r|
      r.Enqueue(settings.queue_name, "waitUrl" => url("/queue_wait"))
    end
    response.text
  end

  post '/queue_wait' do
    response = Twilio::TwiML::Response.new do |r|
      r.Gather :action => url("/say_hello") do |d|
        d.Play "http://com.twilio.music.classical.s3.amazonaws.com/BusyStrings.mp3"
      end
    end
    response.text
  end

  get '/run/*' do
    client = ::Twilio::REST::Client.new settings.account_sid, settings.auth_token
    call = client.account.calls.get(CurrentCall.sid)
    url = url("#{params[:splat].first}")
    call.update(:url => url, :method => "POST")
  end

  post '/say_hello' do
    response = Twilio::TwiML::Response.new do |r|
      r.Say "Hello world"
      r.Enqueue(settings.queue_name, "waitUrl" => url("/queue_wait"))
    end
    response.text
  end

  post '/dial_client/:client' do
    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Client params[:client]
      end
    end
    response.text
  end

  post '/dial_number/:number' do
    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Number params[:number]
      end
    end
    response.text
  end

  post '/enqueue' do
    response = Twilio::TwiML::Response.new do |r|
      r.Enqueue(settings.queue_name, "waitUrl" => url("/queue_wait"))
    end
    response.text
  end

end
