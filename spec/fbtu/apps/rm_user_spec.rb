require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu apps rm-user" do
  context "with both apps installed and a user created" do
    before(:each) do
      @alpha = register_app('alpha')
      @beta  = register_app('beta')
      @alice = create_user_for(@alpha)
    end

    it "removes the user from another app" do
      delete_url = "https://graph.facebook.com/#{@alpha.id}/accounts/test-users?uid=#{@alice.id}&access_token=#{@alpha.access_token}"
      FakeWeb.register_uri(:delete, delete_url, :body => "true")
      fbtu %w[apps rm-user --app alpha --user] + [@alice.id]
      @out.should include("User #{@alice.id} removed from app 'alpha'")
    end

    it "does not removes the user from an app it's not associated with" do
      delete_url = "https://graph.facebook.com/#{@beta.id}/accounts/test-users?uid=#{@alice.id}&access_token=#{@beta.access_token}"
      error = "This is not a valid test user for this app"
      fakeweb_register_bad_request(:delete, delete_url, 2901, error)
      lambda do
        fbtu %w[apps rm-user --app beta --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include(error)
    end
  end

  context "with only one app installed and a user created" do
    before(:each) do
      alpha = register_app('alpha')
      @alice = create_user_for(alpha)
    end

    it "tells you if there was no such app to remove the user from" do
      lambda do
        fbtu %w[apps rm-user --app beta --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include("Unknown app beta")
    end
  end
end
