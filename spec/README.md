# Test Documentation

This directory contains RSpec tests for the SunSword gem.

## Test Structure

```
spec/
├── generators/
│   └── sun_sword/
│       ├── frontend_generator_spec.rb      # Tests for FrontendGenerator
│       ├── scaffold_generator_spec.rb      # Tests for ScaffoldGenerator
│       └── templates_frontend/
│           └── helpers/
│               └── application_helper_spec.rb  # Tests for ApplicationHelper
├── support/
│   ├── generator_helpers.rb                # Helper methods for generator tests
│   └── shared_examples/
│       └── generator_template_examples.rb # Shared examples for template testing
├── sun_sword_spec.rb                       # Tests for SunSword module
└── spec_helper.rb                          # RSpec configuration
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/generators/sun_sword/frontend_generator_spec.rb

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test
bundle exec rspec spec/generators/sun_sword/frontend_generator_spec.rb:109
```

## Test Coverage

### FrontendGenerator (~90%+ coverage)
- Integration test for `#setup` method
- Tests for all private methods:
  - `#remove_assets_folder`
  - `#install_vite`
  - `#configure_vite`
  - `#modify_application_js`
  - `#generate_default_frontend`
  - `#generate_components`
  - `#generate_controllers_site`
  - `#app_name`
  - `#source_code_dir`
  - `#modify_layout_for_vite`

### ApplicationHelper (100% coverage)
- Tests for all helper methods:
  - `#post_to`
  - `#delete_to`
  - `#patch_to`
  - `#flash_type`
  - `#truncate_html`

### ScaffoldGenerator (~90%+ coverage)
- Tests for form field generation covering all field types
- Tests for file creation methods
- Tests for route and sidebar injection
- Integration test for `#running` method
- Tests for engine detection

### SunSword Module (Complete coverage)
- Tests for VERSION constant
- Tests for `scope_owner_column` setting

## Test Patterns

### Generator Testing
Generators are tested using `generator_spec` gem. Tests use temporary directories to avoid polluting the file system:

```ruby
let(:destination_root) { File.expand_path('../tmp', __dir__) }

before do
  FileUtils.mkdir_p(destination_root) unless Dir.exist?(destination_root)
end

after do
  FileUtils.rm_rf(destination_root) if Dir.exist?(destination_root)
end
```

### Mocking Shell Commands
Shell commands are mocked to avoid actual execution:

```ruby
allow(generator).to receive(:run).and_return(true)
expect(generator).to have_received(:run).with('bun install')
```

### Testing Template Files
Template file generation is verified by checking method calls:

```ruby
allow(generator).to receive(:template)
generator.send(:method_name)
expect(generator).to have_received(:template).with(source, destination)
```

### Testing File System Operations
File system operations are tested within temporary directories:

```ruby
Dir.chdir(destination_root) do
  # test code
end
```

## Test Helpers

### GeneratorHelpers
Located in `spec/support/generator_helpers.rb`, provides:
- `create_temp_directory`: Creates temporary directories for testing
- `cleanup_temp_directory`: Cleans up temporary directories
- `create_mock_rails_structure`: Creates mock Rails application structure

### Shared Examples
Located in `spec/support/shared_examples/`, provides reusable test patterns:
- `a generator that creates template files`: Tests template file creation
- `a generator that creates directories`: Tests directory creation
- `a generator that runs shell commands`: Tests shell command execution

## Writing New Tests

When adding new tests:

1. **Follow existing patterns**: Use the same structure and naming conventions
2. **Use temporary directories**: Always use `destination_root` for file operations
3. **Mock external dependencies**: Mock shell commands, Rails methods, etc.
4. **Test edge cases**: Include tests for error conditions and edge cases
5. **Group related tests**: Use `describe` and `context` blocks to organize tests
6. **Add documentation**: Include comments for complex test scenarios

## Test Requirements

- Ruby 2.7+
- RSpec 3.x
- generator_spec gem
- FileUtils for file operations

## Continuous Integration

Tests are run automatically in CI. Ensure all tests pass before submitting PRs.

