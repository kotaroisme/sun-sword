require 'rails/generators'

module SunSword
  class FrontendGenerator < Rails::Generators::Base
    source_root File.expand_path('templates_frontend', __dir__)

    class_option :setup, type: :boolean, default: false, desc: 'Setup domain structure'
    class_option :engine, type: :string, default: nil, desc: 'Specify engine name (e.g., admin, api)'

    def validate_setup_option
      unless options.setup
        raise Thor::Error, 'The --setup option must be specified to create the domain structure.'
      end
    end

    def validate_engine
      return unless options[:engine]

      unless engine_exists?
        raise Thor::Error, "Engine '#{options[:engine]}' not found. Available engines: #{available_engines.join(', ')}"
      end

      say "Generating frontend for engine: #{options[:engine]}", :cyan
    end

    desc 'This generator installs Vite with Rails 8 configuration'

    def setup
      copy_assets_from_template

      add_to_gemfile
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

    def add_to_gemfile
      gem_dependencies = <<~RUBY
        # --- SunSword Package frontend
        group :development do
          gem "listen"
        end
        group :test do
          gem "rails-controller-testing"
        end
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

    def generate_controllers_site
      run 'rails g controller site stimulus'
      template 'controllers/site_controller.rb', File.join(path_app, 'controllers/site_controller.rb')
      template 'controllers/application_controller.rb.tt', File.join(path_app, 'controllers/application_controller.rb')
      site_route = <<-RUBY

  default_url_options :host => "\#{ENV['BASE_URL']}"
  root "site#stimulus"
  get "site/jadi_a"
  get "site/jadi_b"

      RUBY
      inject_into_file 'config/routes.rb', site_route, after: "Rails.application.routes.draw do\n"

      say 'Generate default controller', :green
    end

    def path_app
      engine_path ? File.join(engine_path, 'app') : 'app'
    end

    def engine_path
      return nil unless options[:engine]
      @engine_path ||= detect_engine_path
    end

    def detect_engine_path
      engine_name = options[:engine]
      possible_paths = [
        "engines/#{engine_name}",
        "components/#{engine_name}",
        "gems/#{engine_name}",
        engine_name
      ]

      possible_paths.each do |path|
        return path if Dir.exist?(path) && File.exist?(File.join(path, "#{engine_name}.gemspec"))
      end

      nil
    end

    def engine_exists?
      !engine_path.nil?
    end

    def available_engines
      engines = []
      ['engines', 'components', 'gems', '.'].each do |dir|
        next unless Dir.exist?(dir)

        Dir.glob(File.join(dir, '*')).each do |path|
          next unless Dir.exist?(path)

          engine_name = File.basename(path)
          gemspec = File.join(path, "#{engine_name}.gemspec")
          engines << engine_name if File.exist?(gemspec)
        end
      end
      engines.uniq
    end

    def app_name
      @app_name ||= if options[:engine]
        options[:engine].to_s
      else
        begin
          Rails.application.class.module_parent_name.underscore
        rescue
          'app'
        end
      end
    end

    def source_code_dir
      @source_code_dir ||= if options[:engine]
        "#{path_app}/frontend"
      else
        'app/frontend'
      end
    end

    def modify_layout_for_vite
      template 'views/site/stimulus.html.erb.tt', File.join(path_app, 'views/site/stimulus.html.erb')
      template 'views/site/_comment.html.erb.tt', File.join(path_app, 'views/site/_comment.html.erb')
      template 'views/layouts/application.html.erb.tt', File.join(path_app, 'views/layouts/application.html.erb')

      template 'views/layouts/dashboard/application.html.erb.tt', File.join(path_app, 'views/layouts/owner/application.html.erb')
      template 'views/layouts/dashboard/_sidebar.html.erb.tt', File.join(path_app, 'views/components/layouts/_sidebar.html.erb')
      directory('helpers', File.join(path_app, 'helpers'))
      say 'Updated application layout for Vite integration', :green
    end
  end
end
