require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu users change" do
  before(:each) do
    alpha = register_app('alpha')

    @alice = add_user_to(alpha)
    @bob   = add_user_to(alpha)

    FakeWeb.register_uri(:post,
      "https://graph.facebook.com/#{@alice.id}",
      :body => 'true')

    FakeWeb.register_uri(:post,
      "https://graph.facebook.com/#{@bob.id}",
      :body => 'false')
  end

  it "changes an existing user's name" do
    fbtu %w[users change --app alpha --user] + [@alice.id] + %w[--name Alice]
    @out.should include("Successfully changed user")
  end

  it "changes an existing user's password" do
    fbtu %w[users change --app alpha --user] + [@alice.id] + %w[--password topsecret]
    @out.should include("Successfully changed user")
  end

  it "changes an existing user's user and password" do
    fbtu %w[users change --app alpha --user] + [@alice.id] +
      %w[--name Alice --password topsecret]
    @out.should include("Successfully changed user")
  end

  it "fails to change an existing user's name" do
    fbtu %w[users change --app alpha --user] + [@bob.id] + %w[--name Bob]
    @out.should include("Failed to change user")
  end

  it "tells you if there was no such user" do
    lambda do
      fbtu %w[users change --app alpha --user bogus], :quiet => true
    end.should raise_error
    @err.should include("Unknown user")
  end
end
