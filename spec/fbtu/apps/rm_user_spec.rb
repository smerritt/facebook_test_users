require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu apps rm-user" do
  context "with both apps installed and a user created" do
    before(:each) do
      alpha = register_app('alpha')
      beta  = register_app('beta')
      @alice = create_user_for(alpha)
    end

    it "removes the user from another app" do
      fbtu %w[apps rm-user --from-app alpha --owner-app beta --user] + [@alice.id]
      @out.should include("User #{@alice.id} removed from app 'alpha'")
    end
  end

  context "with only one app installed and a user created" do
    before(:each) do
      alpha = register_app('alpha')
      @alice = create_user_for(alpha)
    end

    it "tells you if there was no such app to remove the user from" do
      lambda do
        fbtu %w[apps rm-user --from-app beta --owner-app alpha --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include("Unknown app beta")
    end

    it "tells you if there was no such app to owning the user" do
      lambda do
        fbtu %w[apps rm-user --from-app alpha --owner-app beta --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include("Unknown app beta")
    end
  end
end
