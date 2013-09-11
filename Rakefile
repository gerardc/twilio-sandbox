require "bundler/setup"
require "twilio-ruby"

task :config_twilio do
  account_sid = ENV["ACCOUNT_SID"]
  auth_token = ENV["AUTH_TOKEN"]
  phone_sid = ENV["PHONE_SID"]
  url = ENV["URL"] + "/voice"

  @client = Twilio::REST::Client.new account_sid, auth_token
  @number = @client.account.incoming_phone_numbers.get(phone_sid)

  puts "Updating #{phone_sid} to point to: #{url}"
  @number.update(:voice_url => url)
end
