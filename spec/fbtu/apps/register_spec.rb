require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe "fbtu apps register" do
  it "lets you create an app" do
    fbtu %w[apps register --app-id 123456 --app-secret 7890 --name hydrogen]

    fbtu %w[apps list]
    @out.should include("hydrogen")
    @out.should_not include("squirrel")
  end

  it "won't let you create an app with a bogus ID" do
    lambda do
      fbtu %w[apps register --app-id xyzzy --app-secret 7890 --name hydrogen], :quiet => true
    end.should raise_error
  end

  it "won't let you create an app with a bogus secret" do
    lambda do
      fbtu %w[apps register --app-id 123456 --app-secret xyzzy --name hydrogen], :quiet => true
    end.should raise_error
  end

  it "won't let you create an app without a name" do
    lambda do
      fbtu %w[apps register --app-id 123456 --app-secret 123456], :quiet => true
    end.should raise_error
  end

  it "won't let you create an app with a duplicate name" do
    fbtu %w[apps register --app-id 123456 --app-secret 7890 --name hydrogen]
    lambda do
      fbtu %w[apps register --app-id 123456 --app-secret 7890 --name hydrogen], :quiet => true
    end.should raise_error
  end
end
