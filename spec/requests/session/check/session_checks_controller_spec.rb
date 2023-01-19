# frozen_string_literal: true

require "spec_helper"

describe Session::Check::SessionChecksController, type: :request do
  around(:each) do |example|
    Timecop.freeze { example.run }
  end

  describe "#time_to_session_expiry" do
    it "returns the time to session expiry" do
      expect(User.timeout_in).to eq(30.minutes)

      seconds_since_last_request = (Time.now.utc - 500.seconds).to_i.seconds
      expect(described_class)
        .to receive(:time_of_last_warden_request).and_return(seconds_since_last_request)
      get "/session_check/time_to_session_expiry"
      expected_expires_in = 30.minutes - Time.now.utc.to_i.seconds + seconds_since_last_request
      result = JSON.parse(response.body)
      expected_payload = { "session_exists" => true, "session_expires_in" => expected_expires_in }
      expect(result).to eq(expected_payload)
    end
  end

  describe "#seconds_since_last_warden_request" do
    it "returns the seconds since the last warden request" do
      session = { "warden.user.user.session" => { "last_request_at" => 500.seconds.ago } }
      result = described_class.time_of_last_warden_request(session)
      expect(result).to eq(500.seconds.ago)
    end

    it "returns now if there is no warden information" do
      session = {}
      result = described_class.time_of_last_warden_request(session)
      expect(result).to eq(Time.zone.now)
    end
  end
end
