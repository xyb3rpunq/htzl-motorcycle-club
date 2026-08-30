# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.1"

# Generator situs statis berbasis Ruby. Dipakai GitHub Pages lewat GitHub Actions.
gem "jekyll", "~> 4.3"

group :jekyll_plugins do
  gem "jekyll-sitemap", "~> 1.4"   # sitemap.xml otomatis
  gem "jekyll-seo-tag", "~> 2.8"   # meta OG/Twitter/JSON-LD
end

group :development, :test do
  gem "minitest", "~> 5.20"        # test suite (padanan Rails test)
  gem "rake", "~> 13.1"
end

# Dependensi Windows
gem "tzinfo-data", platforms: [:windows, :jruby]
gem "wdm", "~> 0.1", platforms: [:windows]
