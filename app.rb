require 'twilio-ruby'
require 'sinatra'
require 'yaml'

class CurrentCall
  # Store current call id in tmp file. Allows for app_reloading with `rerun`
  # or `shotgun` in development
  class << self
    def sid
      File.open(path, "r").read.chomp if File.exists?(path)
    end

    def sid=(call_sid)
      File.open(path, 'a+') {|f| f.write(call_sid) }
    end

    private

    def path
      "tmp/current_call"
    end
  end

end

class AgentCall < CurrentCall
  def self.path
    "tmp/agent_call"
  end
end

class App < Sinatra::Base

  configure do
    enable :logging
    set :twilio_config, YAML.load_file("twilio.yml")
    set :account_sid, (ENV["ACCOUNT_SID"] || twilio_config["account_sid"])
    set :auth_token, (ENV["AUTH_TOKEN"] || twilio_config["auth_token"])
    set :phone_number, (ENV["PHONE_NUMBER"] || twilio_config["phone_number"])
    set :queue_name, "queue_name"
    set :hold_queue_name, "hold_queue_name"
    set :conference_name, "fighting_mongooses_conf"
  end

  before do
    logger.info "params: #{params.inspect}"
    logger.info "CurrentCall.sid = #{CurrentCall.sid}"
  end

  after do
    logger.info "response.body: #{response.body}"
  end

  get '/agent_client' do
    capability = Twilio::Util::Capability.new settings.account_sid, settings.auth_token

    capability.allow_client_incoming 'agent_client'
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
    p params[:splat]
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

  post '/hangup_all' do
    calls = twilio_client.account.calls.list({:status => "in-progress"})

    calls.each do |call|
        call.hangup()
    end
  end

  ## CONFERENCE

  post '/put_caller_in_conference' do
    call = twilio_client.account.calls.get(CurrentCall.sid)
    call.update(:url => url("go_to_conference"), :method => "POST")
  end

  post '/put_agent_in_conference' do
    call = twilio_client.account.calls.get(AgentCall.sid)
    call.update(:url => url("go_to_conference"), :method => "POST")
  end

  post '/dial_agent' do
    agent_call = twilio_client.account.calls.create(
      :from => settings.phone_number,
      :to => "client:agent_client",
      :url => url('go_to_conference') # direct call to conference immediately
    )

    AgentCall.sid = agent_call.sid
  end

  post '/go_to_conference' do
    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Conference settings.conference_name, :waitUrl => 'http://twimlets.com/holdmusic?Bucket=com.twilio.music.electronica'
      end
    end
    response.text
  end

  ### CALL HOLD

  post '/put_agent_on_hold' do
    agent_call = twilio_client.account.calls.get(AgentCall.sid)
    agent_call.update(:url => url("hold/agent"), :method => "POST")
  end

  post '/put_caller_on_hold' do
    agent_call = twilio_client.account.calls.get(CurrentCall.sid)
    agent_call.update(:url => url("hold/caller"), :method => "POST")
  end

  post '/hold/:role' do
    response = Twilio::TwiML::Response.new do |r|
      if params[:role] == 'agent'
        r.Say "You are an agent on hold!"
        r.Play "https://api.twilio.com/cowbell.mp3", :loop => 100
      else
        r.Say "Placing you on hold. Please wait."
        r.Play "http://s1download-universal-soundbank.com/mp3/sounds/3040.mp3", :loop => 100 # Hiccup
      end
    end
    response.text
  end

  helpers do
    def twilio_client
      @twilio_client ||= ::Twilio::REST::Client.new settings.account_sid, settings.auth_token
    end
  end
end
