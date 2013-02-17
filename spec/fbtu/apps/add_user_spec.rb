require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu apps add-user" do
  context "with both apps installed and a user created" do
    before(:each) do
      @alpha = register_app('alpha')
      beta  = register_app('beta')
      @alice = create_user_for(@alpha)
    end

    it "adds the user to another app" do
      fbtu %w[apps add-user --from-app alpha --to-app beta --user] + [@alice.id]
      @out.should include("User #{@alice.id} added to app 'beta'")
    end

    it "adds the user to another app without read_stream permissions" do
      fbtu %w[apps add-user --from-app alpha --to-app beta
              --permissions none --user] + [@alice.id]
      @out.should include("User #{@alice.id} added to app 'beta'")
    end

    it "adds the user to another app without installing the app" do
      fbtu %w[apps add-user --from-app alpha --to-app beta
              --installed false --user] + [@alice.id]
      @out.should include("User #{@alice.id} added to app 'beta'")
    end

    it "doesn't add the user from an app it's not associated to" do
      error = "Facebook refused for some other reason."
      fakeweb_register_bad_request(:post,
        "https://graph.facebook.com/#{@alpha.id}/accounts/test-users",
        9999, error)
      lambda do
        fbtu %w[apps add-user --from-app beta --to-app alpha --user] + [@alice.id], \
          :quiet => true
      end.should raise_error
      @err.should include(error)
    end
  end

  context "with only one app installed and a user created" do
    before(:each) do
      alpha = register_app('alpha')
      @alice = create_user_for(alpha)
    end

    it "tells you if there was no such app to add the user to" do
      lambda do
        fbtu %w[apps add-user --from-app alpha --to-app beta --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include("Unknown app beta")
    end

    it "tells you if there was no such app to add the user from" do
      lambda do
        fbtu %w[apps add-user --from-app beta --to-app alpha --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include("Unknown app beta")
    end
  end
end
