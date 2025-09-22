module SunSword
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path('templates_scaffold', __dir__)

    argument :arg_structure, type: :string, default: '', banner: ''
    argument :arg_scope, type: :hash, default: '', banner: 'scope:dashboard'

    def running
      setup_variables
      create_root_folder
      create_controller_file
      create_view_file
      create_link_file
    end

    private

    def setup_variables
      config     = YAML.load_file("db/structures/#{arg_structure}_structure.yaml")
      @structure = Hashie::Mash.new(config)

      # Mengambil detail konfigurasi
      model_name    = @structure.model
      resource_name = @structure.resource_name.singularize.underscore.downcase
      entity        = @structure.entity || {}

      @actor                = @structure.actor
      @resource_owner_id    = @structure.resource_owner_id
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

      @variable_subject = model_name.split('::').last.underscore.downcase
      @scope_path       = resource_name.pluralize.underscore.downcase
      @scope_class      = @scope_path.camelize
      @scope_subject    = @scope_path.singularize
      @model_class      = model_name.camelize.constantize
      @subject_class    = @variable_subject.camelize
      @fields           = contract_fields
      @form_fields      = @controllers.form_fields

      @route_scope_path = arg_scope['scope'].to_s.downcase rescue ''
      @route_scope_class = @route_scope_path.camelize rescue ''

      @mapping_fields = {
        string:    :text_field,
        text:      :text_area,
        integer:   :number_field,
        float:     :number_field,
        decimal:   :number_field,
        boolean:   :check_box,
        date:      :date_select,
        datetime:  :datetime_select,
        timestamp: :datetime_select,
        time:      :time_select,
        enum:      :select,
        file:      :file_field,
        files:     :file_fields
      }
    end

    def generate_form_fields_html
      form_fields_html = ''
      @form_fields.each do |field|
        field_name     = field[:name].to_sym
        field_type     = field[:type].to_sym
        form_helper    = @mapping_fields[field_type] || :text_field
        input_id       = "#{@variable_subject}_#{field_name}"
        label_input_id = case form_helper
        when :date_select, :datetime_select then "#{input_id}_1i" # Year
        when :time_select then "#{input_id}_4i" # Hour
        else input_id
        end
        field_html = <<-HTML

        <div class="sm:grid sm:grid-cols-3 sm:items-start sm:gap-4 sm:py-6">
          <%= form.label :#{field_name}, for: '#{label_input_id}', class: "block text-sm font-medium text-gray-700 sm:pt-1.5" %>
          <div class="mt-2 sm:col-span-2 sm:mt-0">
        HTML

        case form_helper
        when :text_field, :number_field
          field_html += <<-HTML
            <%= form.#{form_helper} :#{field_name}, id: '#{input_id}', class: "block w-full rounded-md border-gray-300 py-1.5 text-gray-700 shadow-sm focus:ring-2 focus:ring-gray-300 focus:border-gray-300 sm:max-w-md sm:text-sm" %>
          HTML
        when :text_area
          field_html += <<-HTML
            <%= form.text_area :#{field_name}, id: '#{input_id}', rows: 3, class: "block w-full max-w-2xl rounded-md border-gray-300 py-1.5 text-gray-700 shadow-sm focus:ring-2 focus:ring-gray-300 focus:border-gray-300 sm:text-sm" %>
          HTML
        when :check_box
          field_html += <<-HTML
            <div class="relative flex items-start">
              <div class="flex h-6 items-center">
                <%= form.check_box :#{field_name}, id: '#{input_id}', class: "h-4 w-4 rounded border-gray-300 text-gray-600 focus:ring-gray-300 focus:border-gray-300" %>
              </div>
              <div class="ml-3 text-sm">
                <%= form.label :#{field_name}, for: '#{input_id}', class: "font-medium text-gray-700" %>
              </div>
          </div>
          HTML
        when :select
          field_html += <<-HTML
            <%= form.select :#{field_name}, options_for_select([['Option 1', 1], ['Option 2', 2]]), {}, { id: '#{input_id}', class: "block w-full rounded-md border-gray-300 py-1.5 text-gray-700 shadow-sm focus:ring-2 focus:ring-gray-300 focus:border-gray-300 sm:max-w-xs sm:text-sm" } %>
          HTML
        when :datetime_select, :date_select, :time_select
          field_html += <<-HTML
            <%= form.#{form_helper} :#{field_name}, { discard_second: true, id_prefix: '#{input_id}' }, { class: "text-gray-700 shadow-sm focus:ring-2 focus:ring-gray-300 focus:border-gray-300 sm:text-sm" } %>
          HTML
        when :file_fields
          field_html += <<-HTML
            <div class="flex max-w-2xl justify-center rounded-lg border border-dashed border-gray-300 px-6 py-10">
              <div class="text-center">
                <!-- SVG Icon -->
                  <svg class="mx-auto size-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" data-slot="icon">
                    <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 0 1 2.25-2.25h16.5A2.25 2.25 0 0 1 22.5 6v12a2.25 2.25 0 0 1-2.25 2.25H3.75A2.25 2.25 0 0 1 1.5 18V6ZM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0 0 21 18v-1.94l-2.69-2.689a1.5 1.5 0 0 0-2.12 0l-.88.879.97.97a.75.75 0 1 1-1.06 1.06l-5.16-5.159a1.5 1.5 0 0 0-2.12 0L3 16.061Zm10.125-7.81a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Z" clip-rule="evenodd" />
                  </svg>
                <div class="mt-4 flex text-sm text-gray-600">
                  <label for="<%= '#{input_id}' %>" class="relative cursor-pointer rounded-md bg-white font-semibold text-gray-600 hover:text-gray-500">
                    <span>Upload a file</span>
                    <%= form.file_field :#{field_name}, id: '#{input_id}', class: "sr-only", multiple: true %>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs text-gray-600">PNG, JPG, GIF, DOC etc.</p>
              </div>
            </div>
          HTML
        when :file_field
          field_html += <<-HTML
            <div class="flex max-w-2xl justify-center rounded-lg border border-dashed border-gray-300 px-6 py-10">
              <div class="text-center">
                <!-- SVG Icon -->
                  <svg class="mx-auto size-12 text-gray-300" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" data-slot="icon">
                    <path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 0 1 2.25-2.25h16.5A2.25 2.25 0 0 1 22.5 6v12a2.25 2.25 0 0 1-2.25 2.25H3.75A2.25 2.25 0 0 1 1.5 18V6ZM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0 0 21 18v-1.94l-2.69-2.689a1.5 1.5 0 0 0-2.12 0l-.88.879.97.97a.75.75 0 1 1-1.06 1.06l-5.16-5.159a1.5 1.5 0 0 0-2.12 0L3 16.061Zm10.125-7.81a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Z" clip-rule="evenodd" />
                  </svg>
                <div class="mt-4 flex text-sm text-gray-600">
                  <label for="<%= '#{input_id}' %>" class="relative cursor-pointer rounded-md bg-white font-semibold text-gray-600 hover:text-gray-500">
                    <span>Upload a file</span>
                    <%= form.file_field :#{field_name}, id: '#{input_id}', class: "sr-only" %>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs text-gray-600">PNG, JPG, GIF, DOC etc.</p>
              </div>
            </div>
          HTML
        else
          field_html += <<-HTML
            <%= form.#{form_helper} :#{field_name}, id: '#{input_id}', class: "block w-full rounded-md border-gray-300 py-1.5 text-gray-700 shadow-sm focus:ring-2 focus:ring-gray-300 focus:border-gray-300 sm:max-w-md sm:text-sm" %>
          HTML
        end

        field_html += <<-HTML
          </div>
        </div>
        HTML

        form_fields_html += field_html
      end
      form_fields_html
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
      @form_fields_html = generate_form_fields_html
      template 'views/_form.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, '_form.html.erb')
      template 'views/edit.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'edit.html.erb')
      template 'views/index.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'index.html.erb')
      template 'views/new.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'new.html.erb')
      template 'views/show.html.erb.tt', File.join('app/views', @route_scope_path.to_s, @scope_path.to_s, 'show.html.erb')
    end

    def namespace_exists?
      routes_file   = 'config/routes.rb'
      scope_pattern = "namespace :#{@route_scope_path} do\n"
      if File.exist?(routes_file)
        file_content = File.read(routes_file)
        file_content.include?(scope_pattern)
      else
        false
      end
    end

    def create_link_file
      partial_path = File.join('app/views/components/menu', "_link_to_#{@scope_path}.html.erb")
      template 'views/components/menu/link.html.erb.tt', partial_path unless File.exist?(partial_path)

      sidebar = 'app/views/components/layouts/_sidebar.html.erb'
      marker  = "                <%# generate_link %>\n"
      link_to = "                <li><%= render 'components/menu/#{"link_to_#{@scope_path}"}' %></li>\n"
      inject_into_file(sidebar, link_to, before: marker) unless File.read(sidebar).include?(link_to)

      routes_file = 'config/routes.rb'
      if @route_scope_path.present?
        unless namespace_exists?
          scope_code = "  namespace :#{@route_scope_path} do\n  end\n"
          insert_into_file routes_file, scope_code, after: "Rails.application.routes.draw do\n" unless File.read(routes_file).include?(scope_code)
        end
        resource_line = "    resources :#{@scope_path}\n"
        inject_into_file routes_file, resource_line, after: "namespace :#{@route_scope_path} do\n" unless File.read(routes_file).include?(resource_line)
      else
        resource_line = "  resources :#{@scope_path}\n"
        inject_into_file routes_file, resource_line, after: "Rails.application.routes.draw do\n" unless File.read(routes_file).include?(resource_line)
      end
    end

    def contract_fields
      skip_contract_fields = @skipped_fields.map(&:strip).uniq
      @model_class.columns.reject { |column| skip_contract_fields.include?(column.name.to_s) }.map(&:name).map(&:to_s)
    end

    def strong_params
      # pakai controllers.form_fields kalau ada, kalau tidak jatuh ke kolom model (contract_fields)
      raw_fields = @controllers&.form_fields || contract_fields

      # normalisasi jadi pasangan [name, type]
      pairs = raw_fields.map do |f|
        if f.respond_to?(:name)
          [f.name.to_s, f.type.to_s]
        else
          column_type = @model_class.columns_hash[f.to_s]&.type.to_s
          [f.to_s, column_type.presence || 'string']
        end
      end

      permitted = pairs.map do |name, type|
        case type
        when 'files' then "{ #{name}: [] }"  # multiple
        when 'json', 'jsonb', 'hash' then "{ #{name}: {} }"
        when 'array' then "{ #{name}: [] }"
        else ":#{name}"
        end
      end

      permitted.join(', ')
    end
  end
end
