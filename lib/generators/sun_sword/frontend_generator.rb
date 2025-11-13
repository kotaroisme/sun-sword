require 'rails/generators'

module SunSword
  class FrontendGenerator < Rails::Generators::Base
    source_root File.expand_path('templates_frontend', __dir__)

    class_option :setup, type: :boolean, default: false, desc: 'Setup domain structure'
    class_option :engine, type: :string, default: nil, desc: 'Engine option is not supported for frontend generator'

    def validate_setup_option
      unless options.setup
        raise Thor::Error, 'The --setup option must be specified to create the domain structure.'
      end
    end

    def validate_no_engine
      if options[:engine]
        raise Thor::Error, 'Frontend generator does not support --engine option. Frontend setup must be done in the main app only. Use "rails generate sun_sword:frontend --setup" without engine option.'
      end
    end

    desc 'This generator installs Vite with Rails 8 configuration'

    def setup
      validate_no_engine
      copy_assets_from_template

      add_to_gemfile
      install_vite
      configure_vite

      modify_application_js
      generate_default_frontend
      generate_controllers_tests
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

    def add_to_gemfile
      gem_dependencies = <<~RUBY
        # --- SunSword Package frontend
        group :development do
          gem "listen"
        end
        group :test do
          gem "rails-controller-testing"
        end
        gem 'turbo-rails'
        gem 'vite_rails'
      RUBY
      append_to_file('Gemfile', gem_dependencies)
      say 'Rails gem added and bundle installed', :green
    end

    def install_vite
      template 'package.json.tt', 'package.json'
      run 'bun install'
      run 'bun add -D vite vite-plugin-full-reload vite-plugin-ruby vite-plugin-stimulus-hmr'
      run 'bun add path stimulus-vite-helpers @hotwired/stimulus @hotwired/turbo-rails @tailwindcss/aspect-ratio @tailwindcss/forms @tailwindcss/line-clamp @tailwindcss/typography @tailwindcss/vite tailwindcss vite-plugin-rails autoprefixer'
      run 'bun add -D eslint prettier eslint-plugin-prettier eslint-config-prettier eslint-plugin-tailwindcss'
      say 'Vite installed successfully with Bun', :green
    end

    def configure_vite
      say 'Configuring Vite...'

      # Add a basic Vite configuration file to your Rails app
      template 'vite.config.ts.tt', 'vite.config.ts'
      template 'Procfile.dev.tt', 'Procfile.dev'
      template 'bin/watch.tt', 'bin/watch'
      run 'chmod +x bin/watch'
      template 'config/vite.json.tt', 'config/vite.json'
      template 'env.development.tt', '.env.development'

      say 'Vite configuration completed', :green
    end

    def modify_application_js
      if File.exist?('app/javascript/application.js')

        say 'Updated application.js for Vite', :green
      end
    end

    def generate_default_frontend
      directory('frontend', File.join(path_app, 'frontend'))
      say 'Generated default frontend files', :green
    end

    def generate_components
      directory('views/components', File.join(path_app, 'views/components'))
      say 'Generate default controller', :green
    end

    def generate_controllers_tests
      run 'rails g controller tests stimulus turbo_drive turbo_frame frame_content update_content'
      template 'controllers/tests_controller.rb', File.join(path_app, 'controllers/tests_controller.rb')
      template 'controllers/tests_controller_spec.rb', File.join(path_app, 'controllers/tests_controller_spec.rb')
      template 'controllers/application_controller.rb.tt', File.join(path_app, 'controllers/application_controller.rb')
      tests_route = <<-RUBY

  default_url_options :host => "\#{ENV['BASE_URL']}"
  root "tests#stimulus"
  # Frontend feature tests
  get "tests/stimulus"
  get "tests/turbo_drive"
  get "tests/turbo_frame"
  get "tests/frame_content"
  post "tests/update_content"

      RUBY
      inject_into_file 'config/routes.rb', tests_route, after: "Rails.application.routes.draw do\n"

      # Generate views for tests
      template 'views/tests/stimulus.html.erb.tt', File.join(path_app, 'views/tests/stimulus.html.erb')
      template 'views/tests/_comment.html.erb.tt', File.join(path_app, 'views/tests/_comment.html.erb')
      # Copy non-template files from views/tests directory
      copy_file 'views/tests/turbo_drive.html.erb', File.join(path_app, 'views/tests/turbo_drive.html.erb')
      copy_file 'views/tests/turbo_frame.html.erb', File.join(path_app, 'views/tests/turbo_frame.html.erb')
      copy_file 'views/tests/_frame_content.html.erb', File.join(path_app, 'views/tests/_frame_content.html.erb')
      copy_file 'views/tests/_updated_content.html.erb', File.join(path_app, 'views/tests/_updated_content.html.erb')
      copy_file 'views/tests/_log_entry.html.erb', File.join(path_app, 'views/tests/_log_entry.html.erb')

      say 'Generate tests controller for frontend feature testing', :green
    end

    def path_app
      'app'
    end

    def app_name
      @app_name ||= begin
        Rails.application.class.module_parent_name.underscore
                    rescue
                      'app'
      end
    end

    def source_code_dir
      @source_code_dir ||= 'app/frontend'
    end

    def modify_layout_for_vite
      template 'views/layouts/application.html.erb.tt', File.join(path_app, 'views/layouts/application.html.erb')

      template 'views/layouts/dashboard/application.html.erb.tt', File.join(path_app, 'views/layouts/owner/application.html.erb')
      template 'views/layouts/dashboard/_sidebar.html.erb.tt', File.join(path_app, 'views/components/layouts/_sidebar.html.erb')
      directory('helpers', File.join(path_app, 'helpers'))
      say 'Updated application layout for Vite integration', :green
    end
  end
end
