module SunSword
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path('templates_scaffold', __dir__)

    argument :arg_structure, type: :string, default: '', banner: ''

    def running
      validation!
      setup_variables
      create_root_folder
      create_controller_file
      create_view_file
      create_link_file
    end

    private

    def validation!
      unless File.exist?('config/initializers/rider_kick.rb')
        say 'Error must create init configuration for rider_kick!'
        raise Thor::Error, 'run: bin/rails generate rider_kick:init'
      end
    end

    def setup_variables
      config     = YAML.load_file("db/structures/#{arg_structure}_structure.yaml")
      @structure = Hashie::Mash.new(config)

      # Mengambil detail konfigurasi
      model_name    = @structure.model
      resource_name = @structure.resource_name.singularize.underscore.downcase
      entity        = @structure.entity || {}

      @actor                = @structure.actor
      @uploaders            = @structure.uploaders || []
      @search_able          = @structure.search_able || []
      @services             = @structure.domains || {}
      @controllers          = @structure.controllers || {}
      @contract_list        = @services.action_list.use_case.contract || []
      @contract_fetch_by_id = @services.action_fetch_by_id.use_case.contract || []
      @contract_create      = @services.action_create.use_case.contract || []
      @contract_update      = @services.action_update.use_case.contract || []
      @contract_destroy     = @services.action_destroy.use_case.contract || []
      @skipped_fields       = entity.skipped_fields || []
      @custom_fields        = entity.custom_fields || []
      @route_scope_path = @structure.controllers.route_scope.downcase rescue ''
      @route_scope_class = @route_scope_path.camelize rescue ''

      @variable_subject = model_name.split('::').last.underscore.downcase
      @scope_path       = resource_name.pluralize.underscore.downcase
      @scope_class      = @scope_path.camelize
      @model_class      = model_name.camelize.constantize
      @subject_class    = resource_name.camelize
      @fields           = contract_fields
    end

    def build_usecase_filename(action, suffix = '')
      "#{@actor}_#{action}_#{@variable_subject}#{suffix}".camelize
    end

    def create_root_folder
      empty_directory File.join('app/views', @route_scope_path.to_s, @scope_path.to_s)
    end

    def create_controller_file
      template 'controllers/controller.rb.tt', File.join('app/controllers', @route_scope_path.to_s, "#{@scope_path}_controller.rb")
    end

    def create_view_file
      template 'views/_form.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, '_form.html.erb')
      template 'views/edit.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'edit.html.erb')
      template 'views/index.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'index.html.erb')
      template 'views/new.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'new.html.erb')
      template 'views/show.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'show.html.erb')
    end

    def create_link_file
      template 'views/components/menu/link.html.erb.tt', File.join('app/views/components/menu', "_link_to_#{@scope_path}.html.erb")
      link_to = "                <li><%= render 'components/menu/#{"link_to_#{@scope_path}"}' %></li>\n"
      inject_into_file 'app/views/layouts/dashboard/_sidebar.html.erb', link_to, before: "                <%# generate_link %>\n"
    end

    def contract_fields
      skip_contract_fields = @skipped_fields.map(&:strip).uniq
      if RiderKick.scope_owner_column.present?
        skip_contract_fields << RiderKick.scope_owner_column.to_s
      end
      @model_class.columns.reject { |column| skip_contract_fields.include?(column.name.to_s) }.map(&:name).map(&:to_s)
    end

    def strong_params
      results = ''
      @controllers.form_fields.map { |tc| results << ":#{tc}," }
      results[0..-2]
    end
  end
end
