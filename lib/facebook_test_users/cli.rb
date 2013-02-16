require 'thor'
require 'facebook_test_users'

module FacebookTestUsers
  module CLI
    def CLI.find_app!(name)
      app = App.find_by_name(name)
      unless app
        $stderr.puts "Unknown app #{name}."
        $stderr.puts "Run 'fbtu apps' to see known apps."
        raise ArgumentError, "No such app"
      end
      app
    end

    class Apps < Thor

      check_unknown_options!
      def self.exit_on_failure?() true end

      # default_task currently breaks subcommand help, so it's
      # probably better to leave it out for now:
      # https://github.com/wycats/thor/issues/306
      #default_task :list

      desc "register", "Tell fbtu about a new application (must already exist on Facebook)"
      method_option "app_id", :type => :string, :required => true, :banner => "OpenGraph ID of the app"
      method_option "app_secret", :type => :string, :required => true, :banner => "App's secret key"
      method_option "name", :type => :string, :required => true, :banner => "Name of the app (so you don't have to remember its ID)"
      def register
        FacebookTestUsers::App.create!(:name => options[:name], :id => options[:app_id], :secret => options[:app_secret])
        list
      end

      desc "list", "List the applications fbtu knows about"
      def list
        App.all.each do |app|
          puts "#{app.name} (id: #{app.id})"
        end
      end

      desc "add-user", "Add an existing user from another app"
      method_option "to_app", :type => :string, :required => true,
      :banner => "Name of the application to which user will be added"
      method_option "user", :aliases => %w[-u], :type => :string, :required => true,
      :banner => "User ID to add"
      method_option "from_app", :type => :string, :required => true,
      :banner => "Name of the application for which user was originally created"
      method_option "installed", :aliases => %w[-i], :type => :string, :default => true,
      :banner => "Whether your app should be installed for the user"
      method_option "permissions", :aliases => %w[-p], :type => :string, :default => "read_stream",
      :banner => "Permissions the app should be given"
      def add_user
        to_app   = FacebookTestUsers::CLI::find_app!(options[:to_app])
        from_app = FacebookTestUsers::CLI::find_app!(options[:from_app])
        add_user_options = options.select do |k, v|
          %w[installed permissions].include? k.to_s
        end
        add_user_options[:uid] = options[:user]
        add_user_options[:owner_access_token] = from_app.access_token
        result = to_app.add_user(add_user_options)
        puts "User #{result.id} added to app '#{options[:to_app]}'"
      end

    end # Apps

    class Users < Thor
      check_unknown_options!
      def self.exit_on_failure?() true end

      desc "list", "List available test users for an application"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"

      def list
        app = FacebookTestUsers::CLI::find_app!(options[:app])
        if app.users.any?
          shell.print_table([
              ['User ID', 'Access Token', 'Login URL'],
              *(app.users.map do |user|
                  [user.id, user.access_token, user.login_url]
                end)
            ])
        else
          puts "App #{app.name} has no users."
        end
      end

      desc "create", "Create a new test user"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true,
                    :banner => "Name of the app"
      method_option "name", :aliases => %w[-n], :type => :string, :required => false,
                    :banner => "Name of the new user"
      method_option "installed", :aliases => %w[-i], :type => :string, :required => false,
                    :banner => "whether your app should be installed for the test user"
      method_option "locale", :aliases => %w[-l], :type => :string, :required => false,
                    :banner => "the locale for the test user"

      def create
        app = FacebookTestUsers::CLI::find_app!(options[:app])
        attrs = options.select { |k, v| %w(name installed locale).include? k.to_s }
        user = app.create_user(attrs)
        puts "User ID:      #{user.id}"
        puts "Access Token: #{user.access_token}"
        puts "Login URL:    #{user.login_url}"
        puts "Email:        #{user.email}"
        puts "Password:     #{user.password}"
      end

      desc "friend", "Make two of an app's users friends"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"
      method_option "user1", :aliases => %w[-1 -u1], :type => :string, :required => true, :banner => "First user ID"
      method_option "user2", :aliases => %w[-2 -u2], :type => :string, :required => true, :banner => "Second user ID"

      def friend
        app = FacebookTestUsers::CLI::find_app!(options[:app])
        users = app.users
        u1 = users.find {|u| u.id.to_s == options[:user1] } or raise ArgumentError, "No user found w/id #{options[:user1].inspect}"
        u2 = users.find {|u| u.id.to_s == options[:user2] } or raise ArgumentError, "No user found w/id #{options[:user2].inspect}"

        # the first request is just a request; the second request
        # accepts the first request
        u1.send_friend_request_to(u2)
        u2.send_friend_request_to(u1)
      end

      desc "change", "Change a test user's name and/or password"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true,
                    :banner => "Name of the app"
      method_option "user", :aliases => %w[-u], :type => :string, :required => true,
                    :banner => "ID of the user to change"
      method_option "name", :aliases => %w[-n], :type => :string, :required => false,
                    :banner => "New name for the user"
      method_option "password", :aliases => %w[-n], :type => :string, :required => false,
                    :banner => "New password for the user"

      def change
        app = FacebookTestUsers::CLI::find_app!(options[:app])
        user = app.users.find do |user|
          user.id.to_s == options[:user].to_s
        end

        if user
          response = user.change(options)
          if response == "true"
            puts "Successfully changed user"
          else
            puts "Failed to change user"
          end
        else
          $stderr.write("Unknown user '#{options[:user]}'\n")
          raise ArgumentError, "No such user"
        end
      end

      desc "rm", "Remove a test user from an application"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"
      method_option "user", :banner => "ID of the user to remove", :aliases => %w[-u], :type => :string, :required => true

      def rm
        app = FacebookTestUsers::CLI::find_app!(options[:app])
        user = app.users.find do |user|
          user.id.to_s == options[:user].to_s
        end

        if user
          begin
            user.destroy
            puts "User ID #{user.id} removed"
          rescue RestClient::BadRequest => bad_request
            json = MultiJson.decode(bad_request.response)
            begin
              $stderr.write(json['error']['message'] + "\n")
            rescue
              $stderr.write(json.inspect + "\n")
            end
          end
        else
          $stderr.write("Unknown user '#{options[:user]}'\n")
          raise ArgumentError, "No such user"
        end
      end

      desc "nuke", "Remove all test users from an application. Use with care."
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"

      def nuke
        app = FacebookTestUsers::CLI::find_app!(options[:app])
        app.users.each(&:destroy)
      end

    end # Users

    class Main < Thor
      check_unknown_options!
      def self.exit_on_failure?() true end

      desc "apps", "Commands for managing FB applications"
      subcommand :apps, Apps

      desc "users", "Commands for managing FB applications test users"
      subcommand :users, Users
    end
  end
end
