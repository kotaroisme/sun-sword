# frozen_string_literal: true

require_relative "lib/sun_sword/version"

Gem::Specification.new do |spec|
  spec.name                  = "sun-sword"
  spec.version               = SunSword::VERSION
  spec.authors               = ["Kotaro Minami"]
  spec.email                 = ["kotaroisme@gmail.com"]

  spec.summary               = "Rails generators: Vite + Tailwind + Hotwire + Clean Architecture scaffolds"
  spec.description           = "SunSword men-setup frontend (Vite/Stimulus/Tailwind) dan men-generate "\
    "struktur Clean Architecture untuk Rails 7.1/7.2/8 dengan generator yang "\
    "idempotent, reversible, dan minim gesekan."
  spec.license               = "MIT" # SPDX id
  spec.homepage              = "https://github.com/kotaroisme/sun-sword"
  spec.required_ruby_version = ">= 3.2"

  # ==== Files yang dirilis ====
  # Hanya kirim file yang memang diperlukan untuk runtime & template
  root = File.expand_path(__dir__)
  spec.files = Dir.chdir(root) do
    `git ls-files -z`.split("\x0").select do |f|
      f.match?(%r{\A(?:lib|exe|config|templates|README|CHANGELOG|UPGRADING|LICENSE|Rakefile|Gemfile)\b}) &&
        !f.end_with?(".gem")
    end
  end

  spec.bindir        = "exe"
  spec.executables   = Dir.glob("exe/*").map { File.basename(_1) }
  spec.require_paths = ["lib"]

  # ==== Metadata untuk Rubygems (discoverability & trust) ====
  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "homepage_uri"          => spec.homepage,
    "changelog_uri"         => "https://github.com/kotaroisme/sun-sword/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "https://github.com/kotaroisme/sun-sword/issues",
    "documentation_uri"     => "https://github.com/kotaroisme/sun-sword#readme"
    # "funding_uri"         => "https://github.com/sponsors/kotaroisme"
  }

  # ==== Runtime dependencies (minimal & aman) ====
  # railties/activesupport untuk integrasi generator + railtie,
  # thor untuk template generator (opsi/behavior).
  spec.add_dependency "activesupport", ">= 7.0", "< 9.0"
  spec.add_dependency "hashie", ">= 5.0", "< 6.0"
  spec.add_dependency "thor", ">= 1.2", "< 2.0"

  # ==== Dev dependencies (untuk repo) ====
  spec.add_development_dependency "appraisal", "~> 2.5"   # uji matrix Rails 7.1/7.2/8.0
  spec.add_development_dependency "bundler",   ">= 2.4", "< 3.0"
  spec.add_development_dependency "generator_spec", ">= 0.9", "< 1.0"
  spec.add_development_dependency "rake",      ">= 13.0", "< 14.0"
  spec.add_development_dependency "rspec",     ">= 3.12", "< 4.0"
  spec.add_development_dependency "rubocop",   ">= 1.63", "< 2.0"
end
