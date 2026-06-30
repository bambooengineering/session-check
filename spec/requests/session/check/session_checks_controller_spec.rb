# frozen_string_literal: true

require "spec_helper"

describe Session::Check::SessionChecksController, type: :request do
  around(:each) do |example|
    Timecop.freeze { example.run }
  end

  describe "#time_to_session_expiry" do
    context "with the default session_active_proc" do
      it "returns session_exists: true and Devise.timeout_in when a user is present" do
        get "/session_check/time_to_session_expiry"
        result = JSON.parse(response.body)
        expect(result).to eq({ "session_exists" => true, "session_expires_in" => Devise.timeout_in.to_i })
      end
    end

    context "with a custom session_active_proc" do
      around do |example|
        original = Session::Check.configuration.session_active_proc
        Session::Check.configuration.session_active_proc = ->(_controller) { { exists: false, expires_in: 42 } }
        begin
          example.run
        ensure
          Session::Check.configuration.session_active_proc = original
        end
      end

      it "delegates to the custom proc and returns its result" do
        get "/session_check/time_to_session_expiry"
        result = JSON.parse(response.body)
        expect(result).to eq({ "session_exists" => false, "session_expires_in" => 42 })
      end
    end

    context "when the proc returns an ActiveSupport::Duration for expires_in" do
      around do |example|
        original = Session::Check.configuration.session_active_proc
        Session::Check.configuration.session_active_proc = ->(_controller) { { exists: true, expires_in: 30.minutes } }
        begin
          example.run
        ensure
          Session::Check.configuration.session_active_proc = original
        end
      end

      it "coerces expires_in to an integer" do
        get "/session_check/time_to_session_expiry"
        result = JSON.parse(response.body)
        expect(result["session_expires_in"]).to eq(1800)
        expect(result["session_expires_in"]).to be_a(Integer)
      end
    end

    context "when the proc returns a truthy non-boolean for exists" do
      around do |example|
        original = Session::Check.configuration.session_active_proc
        Session::Check.configuration.session_active_proc = ->(_controller) { { exists: "yes", expires_in: 60 } }
        begin
          example.run
        ensure
          Session::Check.configuration.session_active_proc = original
        end
      end

      it "coerces exists to a boolean" do
        get "/session_check/time_to_session_expiry"
        result = JSON.parse(response.body)
        expect(result["session_exists"]).to be(true)
      end
    end
  end
end
