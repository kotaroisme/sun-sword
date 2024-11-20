module SunSword
  class FrontendGenerator < Rails::Generators::Base
    source_root File.expand_path('templates_frontend', __dir__)

    class_option :setup, type: :boolean, default: false, desc: 'Setup domain structure'

    def validate_setup_option
      unless options.setup
        raise Thor::Error, 'The --setup option must be specified to create the domain structure.'
      end
    end

    desc 'This generator installs Vite with Rails 7 configuration'

    def setup
      remove_assets_folder
      copy_assets_from_template

      # copy_database_config
      # copy_env_development

      add_vite_to_gemfile
      install_vite
      configure_vite

      modify_application_js
      generate_default_frontend
      generate_controllers_site
      generate_components
      modify_layout_for_vite
    end

    private

    def remove_assets_folder
      assets_path = "#{path_app}/assets"
      if Dir.exist?(assets_path)
        remove_dir(assets_path)
        say "Folder '#{assets_path}' has been removed.", :green
      else
        say "Folder '#{assets_path}' does not exist.", :yellow
      end
    end

    def copy_assets_from_template
      template 'assets/config/manifest.js', File.join('assets/config/manifest.js')
      say "File '#{path_app}/assets' has been copied from template.", :green
    end

    def copy_database_config
      template 'config/database.yml', File.join('config/database.yml')
    end

    def copy_env_development
      template 'env.development', File.join('.env.development')
      template 'env.development', File.join('env.example')
    end

    def add_vite_to_gemfile
      gem_dependencies = <<~RUBY

        # --- SunSword Package frontend
        gem "turbo-rails"
        gem "stimulus-rails"
        gem "vite_rails"
      RUBY
      append_to_file('Gemfile', gem_dependencies)
      say 'Vite Rails gem added and bundle installed', :green
    end

    def install_vite
      template 'package.json', 'package.json'
      run 'bundle exec vite install'
      run 'yarn add -D sass vite-plugin-full-reload vite-plugin-ruby vite-plugin-stimulus-hmr'
      run 'yarn add -D tailwindcss @tailwindcss/forms @tailwindcss/typography @tailwindcss/aspect-ratio @tailwindcss/forms @tailwindcss/line-clamp autoprefixer'
      run 'yarn add -D eslint prettier eslint-plugin-prettier eslint-config-prettier eslint-plugin-tailwindcss path'
      run 'yarn add @hotwired/stimulus @hotwired/turbo-rails stimulus-vite-helpers vite animejs stimulus-use'
      say 'Vite installed successfully', :green
    end

    def configure_vite
      say 'Configuring Vite...'

      # Add a basic Vite configuration file to your Rails app
      template 'tailwind.config.js', 'tailwind.config.js'
      template 'postcss.config.js', 'postcss.config.js'
      template 'vite.config.ts.tt', 'vite.config.ts'
      template 'Procfile.dev', 'Procfile.dev'
      template 'bin/watch', 'bin/watch'
      run 'chmod +x bin/watch'
      template 'config/vite.json', 'config/vite.json'

      say 'Vite configuration completed', :green
    end

    def modify_application_js
      if File.exist?('app/javascript/application.js')

        say 'Updated application.js for Vite', :green
      end
    end

    def generate_default_frontend
      directory('frontend', 'app/frontend')
      say 'Generate default controller', :green
    end

    def generate_components
      directory('views/components', 'app/views/components')
      say 'Generate default controller', :green
    end

    def generate_controllers_site
      run 'rails g controller site stimulus'
      template 'controllers/site_controller.rb', File.join('app/controllers/site_controller.rb')
      template 'controllers/application_controller.rb.tt', File.join('app/controllers/application_controller.rb')
      site_route = <<-RUBY

  root "site#stimulus"
  get "site/jadi_a"
  get "site/jadi_b"

  namespace :dashboard do
    get "site" => "site#index", as: :dashboard_site_index
  end

      RUBY
      inject_into_file 'config/routes.rb', site_route, after: "Rails.application.routes.draw do\n"

      say 'Generate default controller', :green
    end

    def path_app
      'app'
    end

    def modify_layout_for_vite
      template 'views/site/stimulus.html.erb.tt', 'app/views/site/stimulus.html.erb'
      template 'views/site/_comment.html.erb.tt', 'app/views/site/_comment.html.erb'
      template 'views/layouts/application.html.erb.tt', 'app/views/layouts/application.html.erb'

      directory('views/layouts/dashboard', 'app/views/layouts/dashboard')
      directory('helpers', 'app/helpers')
      template('controllers/dashboard/site_controller.rb', 'app/controllers/dashboard/site_controller.rb')
      say 'Updated application layout for Vite integration', :green
    end
  end
end
