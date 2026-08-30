# frozen_string_literal: true

# Adapter tipis: seluruh logika filter berada di lib/htzl/filters.rb supaya
# bisa diuji tanpa menjalankan Jekyll.
require_relative "../lib/htzl/filters"

Liquid::Template.register_filter(HTZL::Filters)
Liquid::Template.register_filter(HTZL::I18nFilters)
