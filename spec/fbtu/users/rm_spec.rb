require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu users rm" do
  before(:each) do
    @alpha = register_app('alpha')
    @alice = create_user_for(@alpha)
  end

  it "deletes the user" do
    delete_url = "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}"
    FakeWeb.register_uri(:delete, delete_url, :body => "true")

    fbtu %w[users rm --app alpha --user] + [@alice.id]

    FakeWeb.should have_requested(:delete,
      "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}")
    @out.should include("User ID #{@alice.id} removed")
  end

  it "doesn't delete the user if it's associated with another app" do
    delete_url = "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}"
    error = "(#2903) Cannot delete this test account because it is associated with other applications."
    response = {
      "error" => {
        "message" => error,
        "type" => "OAuthException",
        "code" => 2903
      }
    }

    FakeWeb.register_uri(:delete, delete_url, :status => [ '400', 'Bad Request' ],
                         :body => response.to_json)

    lambda do
      fbtu %w[users rm --app alpha --user] + [@alice.id], :quiet => true
    end.should raise_error

    FakeWeb.should have_requested(:delete,
      "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}")
    @err.should include(error)
    @err.should include("fbtu users list-apps")
    @err.should include("fbtu apps rm-user")
    @err.should include("Then re-run this command.")
  end

  it "doesn't delete the user if there's another issue" do
    delete_url = "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}"
    error = "(#9999) Facebook refused for some other reason."
    response = {
      "error" => {
        "message" => error,
        "type" => "OAuthException",
        "code" => 9999
      }
    }

    FakeWeb.register_uri(:delete, delete_url, :status => [ '400', 'Bad Request' ],
                         :body => response.to_json)

    lambda do
      fbtu %w[users rm --app alpha --user] + [@alice.id], :quiet => true
    end.should raise_error

    FakeWeb.should have_requested(:delete,
      "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}")
    @err.should include(error)
  end

  it "tells you if there was no such user" do
    lambda do
      fbtu %w[users rm --app alpha --user bogus], :quiet => true
    end.should raise_error
    @err.should include("Unknown user")
  end
end
