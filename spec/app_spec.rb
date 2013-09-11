require 'spec_helper'
require "pry"

set :environment, :test

describe App do
  include Rack::Test::Methods

  def app
    App
  end

  it "does stuff" do
    post '/voice', {"CallSid" => "12345"}
    last_response.should be_ok
  end
end
