# frozen_string_literal: true

require "spec_helper"

describe Session::Check::Configuration do
  subject(:config) { described_class.new }

  describe "#session_active_proc" do
    it "is set by default" do
      expect(config.session_active_proc).to be_a(Proc)
    end

    context "default proc" do
      let(:controller) { double("controller") }

      it "returns exists: true and remaining session time when current_user is present" do
        elapsed = 60
        last_request_at = Time.now.utc.to_i - elapsed
        warden_session = { 'last_request_at' => last_request_at }
        allow(controller).to receive(:current_user).and_return(double("user"))
        allow(controller).to receive(:session).and_return({ 'warden.user.user.session' => warden_session })
        result = config.session_active_proc.call(controller)
        expected_expires_in = Devise.timeout_in.to_i - elapsed
        expect(result[:exists]).to eq(true)
        expect(result[:expires_in]).to be_within(2).of(expected_expires_in)
      end

      it "falls back to full timeout when warden session data is unavailable" do
        allow(controller).to receive(:current_user).and_return(double("user"))
        allow(controller).to receive(:session).and_return({})
        result = config.session_active_proc.call(controller)
        expect(result[:exists]).to eq(true)
        expect(result[:expires_in]).to be_within(2).of(Devise.timeout_in.to_i)
      end

      it "returns exists: false and 0 when current_user is nil" do
        allow(controller).to receive(:current_user).and_return(nil)
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
