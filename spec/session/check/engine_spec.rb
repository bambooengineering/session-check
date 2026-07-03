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

  it "does not HTML-escape quotes in the JSON-encoded logged_out_url" do
    result = instance.session_check(logged_out_url: '/users/sign_in?next=%2F"home"')
    expect(result).to include('logged_out_url: "/users/sign_in?next=%2F\"home\"",')
    expect(result).not_to include("&quot;")
    expect(result).not_to include("\\u0022")
  end

  it "escapes HTML-significant characters in logged_out_url so it can't break out of the <script> tag" do
    result = instance.session_check(logged_out_url: '</script><script>alert(1)</script>')
    expect(result).not_to include("</script><script>alert(1)</script>")
    expect(result).to include('logged_out_url: "\u003c/script\u003e\u003cscript\u003ealert(1)\u003c/script\u003e",')
  end
end
