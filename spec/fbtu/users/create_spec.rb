require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu users create" do
  context "with the app installed" do
    before(:each) do
      alpha = register_app('alpha')

      @new_user_id = 60189
      new_user_response = {
        "id" => @new_user_id,
        "access_token" => 5795927166794,
        "login_url" => "https://facebook.example.com/login/#@new_user_id",
      }

      FakeWeb.register_uri(:post,
                            "https://graph.facebook.com/#{alpha.id}/accounts/test-users",
                            :body => new_user_response.to_json)
    end

    it "creates a user" do
      fbtu %w[users create --app alpha]
      @out.should include(@new_user_id.to_s)
    end

    it "creates a user with the app not installed" do
      # The API doesn't return the installed status
      fbtu %w[users create --app alpha --installed false]
      @out.should include(@new_user_id.to_s)
    end

    it "creates a named user" do
      fbtu %w[users create --app alpha --name Joe]
      # The API doesn't return the name
      @out.should include(@new_user_id.to_s)
    end

    it "creates a user with a locale" do
      fbtu %w[users create --app alpha --locale en_GB]
      # The API doesn't return the locale
      @out.should include(@new_user_id.to_s)
    end
  end

  it "tells you if there was no such app" do
    lambda do
      fbtu %w[users create --app beta], :quiet => true
    end.should raise_error
    @err.should include("Unknown app beta")
  end
end
