require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu users friend" do
  before(:each) do
    alpha = register_app('alpha')

    @alice = create_user_for(alpha)
    @bob = create_user_for(alpha)

    FakeWeb.register_uri(:post,
      "https://graph.facebook.com/#{@alice.id}/friends/#{@bob.id}",
      :body => "true")
    FakeWeb.register_uri(:post,
      "https://graph.facebook.com/#{@bob.id}/friends/#{@alice.id}",
      :body => "true")
  end

  it "adds a user with the app installed" do
    fbtu ['users', 'friend',
      '--app', 'alpha',
      '--user1', @alice.id,
      '--user2', @bob.id]

    FakeWeb.should have_requested(:post,
      "https://graph.facebook.com/#{@alice.id}/friends/#{@bob.id}")
    FakeWeb.should have_requested(:post,
      "https://graph.facebook.com/#{@bob.id}/friends/#{@alice.id}")
  end
end
