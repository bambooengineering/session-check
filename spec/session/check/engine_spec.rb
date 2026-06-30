# frozen_string_literal: true

require "spec_helper"

describe Session::Check::Engine do
  let(:instance) do
    ActionController::Base.new.tap { |c| allow(c).to receive(:current_user).and_return(nil) }
  end

  it "has a version number" do
    expect(Session::Check::VERSION).not_to be nil
  end

  it "has a to_prepare block that adds the helper to ActionController::Base" do
    result = instance.session_check
    expect(result).to include("session_time")
  end

  it "renders the script tag without a nonce by default" do
    result = instance.session_check
    expect(result).to include("<script>")
  end

  it "renders the script tag with a nonce when provided" do
    result = instance.session_check(nonce: "abc123")
    expect(result).to include('nonce="abc123"')
  end

  it "uses a 1000ms multiplier for setTimeout so check_every (in seconds) converts correctly to milliseconds" do
    result = instance.session_check
    expect(result).to include("check_every_s * 1000")
  end

  it "has a to_prepare block that adds the helper to a subclass of ActionController::Base" do
    instance = SomeController.new.tap { |c| allow(c).to receive(:current_user).and_return(nil) }
    result = instance.session_check
    expect(result).to include("session_time")
  end
end
