# frozen_string_literal: true

require "spec_helper"
require "warden/test/helpers"

describe Session::Check::SessionChecksController, type: :request do
  include Warden::Test::Helpers

  after(:each) { Warden.test_reset! }

  around(:each) do |example|
    Timecop.freeze { example.run }
  end

  let(:user) do
    User.find_or_create_by!(email: "user@example.com") { |u| u.password = "password123" }
  end

  describe "#time_to_session_expiry" do
    context "with the default session_active_proc" do
      it "returns session_exists: true and Devise.timeout_in when a user is signed in" do
        login_as user, scope: :user
        get "/session_check/time_to_session_expiry"
        result = JSON.parse(response.body)
        expect(result).to eq({ "session_exists" => true, "session_expires_in" => Devise.timeout_in.to_i })
      end

      it "returns session_exists: false when no user is signed in" do
        get "/session_check/time_to_session_expiry"
        result = JSON.parse(response.body)
        expect(result).to eq({ "session_exists" => false, "session_expires_in" => 0 })
      end

      it "returns 200 with session_exists: false, rather than a 401, once the Devise session " \
        "has timed out" do
        login_as user, scope: :user
        get "/session_check/time_to_session_expiry" # first request lands the login_as session

        Timecop.travel(Devise.timeout_in.from_now + 60) do
          get "/session_check/time_to_session_expiry"
          expect(response.status).to eq(200)
          result = JSON.parse(response.body)
          expect(result).to eq({ "session_exists" => false, "session_expires_in" => 0 })
        end
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
