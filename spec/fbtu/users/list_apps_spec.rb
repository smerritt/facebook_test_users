require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu users list-apps" do
  context "with two apps installed and a user created" do
    before(:each) do
      @alpha = register_app('alpha')
      @beta  = register_app('beta')
      @alice = create_user_for(@alpha)
    end

    it "lists the apps" do
      list_url = "https://graph.facebook.com/#{@alice.id}/ownerapps?access_token=#{@alpha.access_token}"
      response = {
        "data" => [
          {"name" => @alpha.name, "id" => @alpha.id },
          {"name" => @beta.name,  "id" => @beta.id  },
        ],
        "paging" => {
          "next" => "https => \\/\\/graph.facebook.com\\/#{@alice.id}\\/ownerapps?access_token=#{@alpha.access_token}&limit=5000&offset=5000&__after_id=137431703386"
        }
      }
      FakeWeb.register_uri(:get, list_url, :body => response.to_json)

      fbtu %w[users list-apps --app alpha --user] + [@alice.id]
      @out.should include(@alpha.name)
      @out.should include(@beta.name)
    end
  end

  context "with only one app installed and no user" do
    before(:each) do
      alpha = register_app('alpha')
    end

    it "tells you if there was no such user to list apps for" do
      lambda do
        fbtu %w[users list-apps --app alpha --user 12345], :quiet => true
      end.should raise_error
      @err.should include("Unknown user '12345'")
    end
  end

  context "with a user and one apps" do
    before(:each) do
      alpha = register_app('alpha')
      @alice = create_user_for(alpha)
    end

    it "tells you if there was no such app owning the user" do
      lambda do
        fbtu %w[users list-apps --app beta --user] + [@alice.id], :quiet => true
      end.should raise_error
      @err.should include("Unknown app beta")
    end
  end
end
