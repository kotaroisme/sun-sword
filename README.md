# SunSword
Rails generators for a **modern frontend stack**: Vite, Tailwind (v4), Hotwire (Turbo + Stimulus), plus view scaffolds aligned with your domain.

This gem provides helper interfaces and classes to assist in the construction of application with
Clean Architecture, as described in [Robert Martin's seminal book](https://www.amazon.com/gp/product/0134494164).

---
## ✨ Features

- **One-shot frontend setup**  
  Installs and wires **Vite**, **Tailwind v4**, **Turbo**, **Stimulus**, HMR, and sensible defaults.
- **Scaffolded views & components**  
  Opinionated but flexible ERB views, partials, and Stimulus controllers.
- **Clean integration with Rails 8 + Vite Ruby**  
  Ships `vite.config.ts`, `config/vite.json`, `Procfile.dev`, `bin/watch`, and entrypoints.

---
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rider-kick'
gem 'sun-sword'
```


And then execute:
```bash
    $ rails generate sun_sword:frontend
    $ rubocop -A
```
---
## Usage
```bash
Description:
     Clean Architecture CRUD generator

Example:
    To Generate Frontend:
        bin/rails  generate sun_sword:init
        bin/rails  generate sun_sword:frontend --setup
        
    To Generate scaffold:
        bin/rails  generate sun_sword:scaffold Models::Contact actor:user
```
---
## Generated structure
```text
app/
    frontend/
      entrypoints/
        application.js
        stimulus.js
      pages/
        web.js
        stimulus.js
      stylesheets/
        application.css   # Tailwind v4 style (@import, @plugin, @source)
      assets/
```
---
## Philosophy

The intention of this gem is to help you build applications that are built from the use case down,
and decisions about I/O can be deferred until the last possible moment.

### Clean Architecture
This structure provides helper interfaces and classes to assist in the construction of application with Clean Architecture, as described in Robert Martin's seminal book.

```
- app
  - controllers
    - ...
  - models
    - models
      - ...
  - domains 
    - entities (Contract Response)
    - builder
    - repositories (Business logic)
    - use_cases (Just Usecase)
    - utils (Class Reusable)
```
### Screaming architecture - use cases as an organisational principle
Uncle Bob suggests that your source code organisation should allow developers to easily find a listing of all use cases your application provides. Here's an example of how this might look in a this application.
```
- app
  - controllers
    - ...
  - models
    - models
      - ...
  - domains 
    - core
      ...
      - usecase
        - retail_customer_opens_bank_account.rb
        - retail_customer_makes_deposit.rb
        - ...
```
Note that the use case name contains:

- the user role
- the action
- the (sometimes implied) subject
```ruby
    [user role][action][subject].rb
    # retail_customer_opens_bank_account.rb
    # admin_fetch_info.rb [specific usecase]
    # fetch_info.rb [generic usecase] every role can access it
```
---
## Contributing

- Fork & bundle install
- ```bin/rails generate sun_sword:frontend --setup``` in a throwaway app to test changes
- Add/adjust generator tests where possible
- ```bundle exec rspec```
- Open a PR 🎉

See CONTRIBUTING.md for more.