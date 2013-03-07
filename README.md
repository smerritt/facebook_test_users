# A gem to ease the pain of managing Facebook test users

Testing Facebook apps is hard; part of that difficulty comes from
managing your test users. Currently, Facebook's "Developer" app
doesn't offer any way to do it, so you wind up with a bunch of `curl`
commands and pain (see Facebook's [API
documentation](https://developers.facebook.com/docs/test_users/) for
details).

This gem tries to take away the pain of managing your test users. It's
easy to get started.

`$ gem install facebook_test_users`

`$ fbtu apps register --name myapp --app-id 123456 --app-secret abcdef`

`$ fbtu users list --app myapp`

`$ fbtu users create --app myapp --name Fred`

`$ fbtu users change --app myapp --user 1000000093284356 --name "Sir Fred"`

`$ fbtu apps add-user --from-app myapp --user 1000000093284356 --to-app myotherapp`

`$ fbtu apps rm-user --app myapp --user 1000000093284356`

`$ fbtu users rm --app myapp --user 1000000093284356`

You can also use it in your own Ruby applications; `require
"facebook_test_users"` and off you go.

## Integration with Rails apps

It's easy to integrate with Rails apps.  For example, if your app has
a `"config/omniauth/#{Rails.env}.yml"` file containing:

    facebook:
      name:       http://localhost:3000
      API_key:    123456789012
      app_secret: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6

and `config/initializers/omniauth.rb` containing:

    omniauth_yml_path = Rails.root.join("config", "omniauth", Rails.env + ".yml")
    SETTINGS = YAML.load(IO.read(omniauth_yml_path))

    Rails.application.config.middleware.use OmniAuth::Builder do
      SETTINGS.each do |service, secrets|
        provider service.to_sym, secrets['API_key'], secrets['app_secret']
      end
    end

then you could build simple rake tasks like this:

    require 'facebook_test_users/cli'
    require File.expand_path "#{Rails.root}/config/initializers/omniauth.rb"

    fb = SETTINGS['facebook']
    APP_ID = fb['API_key']
    SECRET = fb['app_secret']

    namespace :fbtu do
      namespace :app do
        desc 'Register facebook app credentials with fbtu'
        task :register do
          FacebookTestUsers::App.create!(:name => fb['name'], :id => APP_ID, :secret => SECRET)
          puts "Registered app '#{fb['name']}'"
        end
      end

      namespace :users do
        desc 'List test users via fbtu'
        task :list do
          cli = FacebookTestUsers::CLI::Main.start [:users, :list, '--app', fb['name'] ]
        end
      end
    end

Then after running `rake fbtu:app:register`, you can invoke `fbtu`
commands as per normal, using `--app http://localhost:3000` to refer
to the registered app.
