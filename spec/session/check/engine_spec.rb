# frozen_string_literal: true

require "spec_helper"

describe Session::Check::Engine do
  it "has a version number" do
    expect(Session::Check::VERSION).not_to be nil
  end

  it "has a to_prepare block that adds the helper to ActionController::Base" do
    instance = ActionController::Base.new
    result = instance.session_check
    expect(result).to include("session_time")
  end

  it "renders the script tag without a nonce by default" do
    instance = ActionController::Base.new
    result = instance.session_check
    expect(result).to include("<script>")
  end

  it "renders the script tag with a nonce when provided" do
    instance = ActionController::Base.new
    result = instance.session_check(nonce: "abc123")
    expect(result).to include('nonce="abc123"')
  end

  it "has a to_prepare block that adds the helper to a subclass of ActionController::Base" do
    instance = SomeController.new
    result = instance.session_check
    expect(result).to include("session_time")
  end
end
