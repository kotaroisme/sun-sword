# frozen_string_literal: true

require 'sun_sword/version'
require 'sun_sword/configuration'

module SunSword
  extend SunSword::Configuration
  define_setting :scope_owner_column, ''
  define_setting :scope_owner, ''
end
