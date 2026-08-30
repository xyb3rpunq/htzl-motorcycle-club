# frozen_string_literal: true

require_relative "../lib/htzl/locales"

module HTZL
  # Membuat satu halaman Jekyll untuk tiap kombinasi cetak biru x bahasa,
  # sehingga setiap bahasa punya URL sendiri dan bisa diindeks terpisah.
  class LocalizedPages < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      HTZL::LOCALES.each do |locale|
        dict = site.data.dig("i18n", locale)
        raise "Data i18n untuk '#{locale}' tidak ditemukan" if dict.nil?

        HTZL::BLUEPRINTS.each do |blueprint|
          site.pages << build_page(site, locale, dict, blueprint)
        end
      end

      site.pages << build_404(site)
    end

    private

    def build_page(site, locale, dict, blueprint)
      permalink = "#{dict['prefix']}/#{blueprint[:path]}"
      page = Jekyll::PageWithoutAFile.new(site, site.source, "", "#{locale}-#{blueprint[:id]}.html")

      page.data.merge!(
        "layout"      => blueprint[:layout],
        "permalink"   => permalink,
        "lang"        => locale,
        "html_lang"   => dict["html_lang"],
        "page_id"     => blueprint[:id],
        "nav_key"     => blueprint[:nav],
        "brand"       => blueprint[:brand],
        "brand_key"   => blueprint[:brand_key],
        "title"       => page_title(dict, blueprint),
        "description" => dict.dig("meta", blueprint[:meta]),
        "alternates"  => alternates(site, blueprint),
        "is_default"  => locale == HTZL::DEFAULT_LOCALE
      )
      page
    end

    def page_title(dict, blueprint)
      case blueprint[:id]
      when "home"    then dict.dig("meta", "home_title")
      when "catalog" then dict.dig("catalog", "title")
      when "gallery" then dict.dig("gallery", "title")
      when "reserve" then dict.dig("reserve", "title")
      else blueprint[:brand]
      end
    end

    # Daftar versi bahasa lain untuk tag hreflang dan pemilih bahasa.
    def alternates(site, blueprint)
      HTZL::LOCALES.map do |locale|
        dict = site.data.dig("i18n", locale)
        {
          "lang"      => locale,
          "html_lang" => dict["html_lang"],
          "name"      => dict["name"],
          "short"     => dict["short"],
          "flag"      => dict["flag"],
          "url"       => "#{dict['prefix']}/#{blueprint[:path]}"
        }
      end
    end

    def build_404(site)
      page = Jekyll::PageWithoutAFile.new(site, site.source, "", "404.html")
      page.data.merge!(
        "layout"    => "notfound",
        "permalink" => "/404.html",
        "lang"      => HTZL::DEFAULT_LOCALE,
        "html_lang" => "id",
        "page_id"     => "notfound",
        "title"       => site.data.dig("i18n", HTZL::DEFAULT_LOCALE, "notfound", "title"),
        "description" => site.data.dig("i18n", HTZL::DEFAULT_LOCALE, "notfound", "text"),
        "sitemap"     => false
      )
      page
    end
  end
end
