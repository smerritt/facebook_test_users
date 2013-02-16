require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu users rm" do
  before(:each) do
    @alpha = add_app('alpha')
    @alice = add_user_to(@alpha)
  end

  it "deletes the user" do
    delete_url = "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}"
    FakeWeb.register_uri(:delete, delete_url, :body => "true")

    fbtu %w[users rm --app alpha --user] + [@alice.id]

    FakeWeb.should have_requested(:delete,
      "https://graph.facebook.com/#{@alice.id}?access_token=#{@alice.access_token}")
  end

  it "tells you if there was no such user" do
    lambda do
      fbtu %w[users rm --app alpha --user bogus], :quiet => true
    end.should raise_error
    @err.should include("Unknown user")
  end
end
