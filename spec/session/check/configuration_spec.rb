# frozen_string_literal: true

require "spec_helper"

describe Session::Check::Configuration do
  subject(:config) { described_class.new }

  describe "#session_active_proc" do
    it "is set by default" do
      expect(config.session_active_proc).to be_a(Proc)
    end

    context "default proc" do
      let(:warden) { double("warden") }
      let(:controller) do
        double("controller").tap do |c|
          allow(c).to receive_message_chain(:request, :env).and_return({ 'warden' => warden })
        end
      end

      it "returns exists: true and remaining session time when a warden user is present" do
        elapsed = 60
        last_request_at = Time.now.utc.to_i - elapsed
        warden_session = { 'last_request_at' => last_request_at }
        allow(warden).to receive(:user).with(scope: :user, run_callbacks: false).and_return(double("user"))
        allow(controller).to receive(:session).and_return({ 'warden.user.user.session' => warden_session })
        result = config.session_active_proc.call(controller)
        expected_expires_in = Devise.timeout_in.to_i - elapsed
        expect(result[:exists]).to eq(true)
        expect(result[:expires_in]).to be_within(2).of(expected_expires_in)
      end

      it "falls back to full timeout when warden session data is unavailable" do
        allow(warden).to receive(:user).with(scope: :user, run_callbacks: false).and_return(double("user"))
        allow(controller).to receive(:session).and_return({})
        result = config.session_active_proc.call(controller)
        expect(result[:exists]).to eq(true)
        expect(result[:expires_in]).to be_within(2).of(Devise.timeout_in.to_i)
      end

      it "returns exists: false and 0 when there is no warden user" do
        allow(warden).to receive(:user).with(scope: :user, run_callbacks: false).and_return(nil)
        result = config.session_active_proc.call(controller)
        expect(result).to eq({ exists: false, expires_in: 0 })
      end

      it "returns exists: false and 0 when the session has actually timed out, without " \
        "triggering Devise's sign-out/401 behaviour" do
        last_request_at = Time.now.utc.to_i - (Devise.timeout_in.to_i + 60)
        warden_session = { 'last_request_at' => last_request_at }
        # Fetching with run_callbacks: false means Warden won't sign the user out or throw here,
        # unlike a real `current_user` call once the session has timed out; the returned user
        # object itself is still present, and it's the expires_in calculation below that
        # determines the session is no longer active.
        allow(warden).to receive(:user).with(scope: :user, run_callbacks: false).and_return(double("user"))
        allow(controller).to receive(:session).and_return({ 'warden.user.user.session' => warden_session })
        result = config.session_active_proc.call(controller)
        expect(result).to eq({ exists: false, expires_in: 0 })
      end

      it "returns exists: false and 0 when there is no warden proxy on the request" do
        allow(controller).to receive_message_chain(:request, :env).and_return({})
        result = config.session_active_proc.call(controller)
        expect(result).to eq({ exists: false, expires_in: 0 })
      end
    end

    it "can be overridden with a custom proc" do
      custom_proc = ->(_controller) { { exists: true, expires_in: 9999 } }
      config.session_active_proc = custom_proc
      expect(config.session_active_proc).to eq(custom_proc)
    end
  end
end
