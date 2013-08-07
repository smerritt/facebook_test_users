require 'thor'
require 'facebook_test_users'
require 'heredoc_unindent'
require 'launchy'
require 'fileutils'

module FacebookTestUsers
  module CLI
    module Utils
      def find_app!(name)
        app = App.find_by_name(name)
        unless app
          raise Thor::Error, "Unknown app #{name}. Run 'fbtu apps' to see known apps."
        end
        app
      end

      def bad_request_message(bad_request)
        response = bad_request.response
        json = MultiJson.decode(response)
        json['error']['message'] rescue json.inspect
      end

      def handle_bad_request(raise_error=true)
        begin
          yield
        rescue RestClient::BadRequest => bad_request
          @message = bad_request_message(bad_request)
          raise Thor::Error, "#{bad_request.class}: #@message" if raise_error
          nil
        end
      end
    end

    class Base < Thor
      include Utils
    end

    class Apps < Base
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
      method_option   "to_app",    :aliases => %w[-t], :type => :string, :required => true,
                    :banner => "Name of the application to which user will be added"
      method_option "from_app",    :aliases => %w[-f], :type => :string, :required => true,
                    :banner => "Name of the application for which user was originally created"
      method_option "user",        :aliases => %w[-u], :type => :string, :required => true,
                    :banner => "User ID to add"
      method_option "installed",   :aliases => %w[-i], :type => :string, :default => true,
                    :banner => "Whether your app should be installed for the user"
      method_option "permissions", :aliases => %w[-p], :type => :string, :default => "read_stream",
                    :banner => "Permissions the app should be given"
      def add_user
        to_app   = find_app!(options[:to_app])
        from_app = find_app!(options[:from_app])
        add_user_options = options.select do |k, v|
          %w[installed permissions].include? k.to_s
        end
        add_user_options[:uid] = options[:user]
        add_user_options[:owner_access_token] = from_app.access_token
        handle_bad_request do
          result = to_app.add_user(add_user_options)
          puts "User #{result.id} added to app '#{options[:to_app]}'"
        end
      end

      desc "rm-user", "Remove an existing user from an app"
      method_option "app", :type => :string, :required => true,
        :banner => "Name of the application from which user will be removed"
      method_option "user", :aliases => %w[-u], :type => :string, :required => true,
        :banner => "User ID to add"
      def rm_user
        app  = find_app!(options[:app])
        result = handle_bad_request do
          app.rm_user(options[:user])
        end
        if result
          puts "User #{options[:user]} removed from app '#{options[:app]}'"
        else
          puts "User #{options[:user]} not removed from app '#{options[:app]}'"
        end
      end

    end # Apps

    class Users < Base
      check_unknown_options!
      def self.exit_on_failure?() true end

      desc "list", "List available test users for an application"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"

      def list
        app = find_app!(options[:app])
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
        app = find_app!(options[:app])
        attrs = options.select { |k, v| %w(name installed locale).include? k.to_s }
        user = handle_bad_request do
          app.create_user(attrs)
        end

        if user
          result = "User ID:      #{user.id}\n"
          result += "Access Token: #{user.access_token}\n"
          result += "Login URL:    #{user.login_url}\n"
          result += "Email:        #{user.email}\n"
          result += "Password:     #{user.password}"

          location = File.join(Rails.root.join("tmp", "facebook_test_users"), "#{Time.now.to_i}_#{options[:name].downcase.gsub(' ','_')}.txt")

          FileUtils.mkdir_p(location)
          File.open(location, 'w') do |f|
            f.write content
          end

          Launchy.open("file:///#{URI.parse(URI.escape(location))}")
        end
      end

      desc "friend", "Make two of an app's users friends"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"
      method_option "user1", :aliases => %w[-1 -u1], :type => :string, :required => true, :banner => "First user ID"
      method_option "user2", :aliases => %w[-2 -u2], :type => :string, :required => true, :banner => "Second user ID"

      def friend
        app = find_app!(options[:app])
        users = app.users
        u1 = users.find {|u| u.id.to_s == options[:user1] } or \
          raise Thor::Error, "No user found w/id #{options[:user1].inspect}"
        u2 = users.find {|u| u.id.to_s == options[:user2] } or \
          raise Thor::Error, "No user found w/id #{options[:user2].inspect}"

        # The first request is just a request; the second request
        # accepts the first request.
        handle_bad_request do
          u1.send_friend_request_to(u2)
          u2.send_friend_request_to(u1)
        end
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
        app = find_app!(options[:app])
        user = app.users.find do |user|
          user.id.to_s == options[:user].to_s
        end

        if user
          response = handle_bad_request do
            user.change(options)
          end
          if response == "true"
            puts "Successfully changed user"
          else
            puts "Failed to change user"
          end
        else
          raise Thor::Error, "Unknown user '#{options[:user]}'"
        end
      end

      desc "list-apps", "List apps associated with the user"
      method_option "user", :aliases => %w[-u], :type => :string, :required => true,
                    :banner => "ID of the user for which to list associated apps"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true,
                    :banner => "Name of the app owning the user"
      def list_apps
        app = find_app!(options[:app])
        user = app.users.find do |user|
          user.id.to_s == options[:user].to_s
        end

        if user
          response = handle_bad_request do
            user.owner_apps(app)
          end
          if response
            json = MultiJson.decode(response)
            apps = json['data'] rescue nil
            if apps
              shell.print_table([
                                  ['App name', 'App ID'],
                                  *(apps.map { |app| [app['name'], app['id']] })
                                ])
            else
              $stderr.write("No apps returned; response was: #{response}\n")
            end
          end
        else
          raise Thor::Error, "Unknown user '#{options[:user]}'"
        end
      end

      desc "rm", "Remove a test user from an application"
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"
      method_option "user", :banner => "ID of the user to remove", :aliases => %w[-u], :type => :string, :required => true

      def rm
        app = find_app!(options[:app])
        user = app.users.find do |user|
          user.id.to_s == options[:user].to_s
        end

        if user
          result = handle_bad_request(raise_error=false) do
            user.destroy
          end
          if result
            puts "User ID #{user.id} removed"
          else
            if @message.match /(\(#2903\) Cannot delete this test account because it is associated with other applications.)/
              error = <<-EOMSG.unindent.gsub(/^\|/, '')
              #$1
              Run:
              |
                fbtu users list-apps --app #{options[:app]} --user #{user.id}
              |
              then for each of the other apps, run:
              |
                fbtu apps rm-user --app APP-NAME --user #{user.id}
              |
              Then re-run this command.
              EOMSG
            else
              error = @message
            end
            raise Thor::Error, error
          end
        else
          raise Thor::Error, "Unknown user '#{options[:user]}'"
        end
      end

      desc "nuke", "Remove all test users from an application. Use with care."
      method_option "app", :aliases => %w[-a], :type => :string, :required => true, :banner => "Name of the app"

      def nuke
        app = find_app!(options[:app])
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
