# frozen_string_literal: true

require "json"

module HTZL
  # Generator Jekyll yang menerbitkan katalog sebagai JSON statis di
  # /assets/catalog.json. Berguna untuk integrasi lain (bot WhatsApp, aplikasi
  # mobile, atau spreadsheet stok) tanpa perlu server API.
  class CatalogApi < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      items = site.data["catalog"]
      return if items.nil? || items.empty?

      payload = {
        "generated_by" => "lib/seed_catalog.rb",
        "site"         => site.config["title"],
        "count"        => items.length,
        "currency"     => "IDR",
        "items"        => items.map { |item| compact(item) }
      }

      site.pages << json_page(site, "catalog.json", JSON.pretty_generate(payload))
    end

    private

    def compact(item)
      {
        "sku"         => item["sku"],
        "name"        => item["name"],
        "slug"        => item["slug"],
        "category"    => item["category"],
        "subcategory" => item["subcategory"],
        "brand"       => item["brand"],
        "price"       => item["price"],
        "price_old"   => item["price_old"],
        "stock"       => item["stock"],
        "rating"      => item["rating"],
        "specs"       => item["specs"]
      }
    end

    def json_page(site, name, content)
      page = Jekyll::PageWithoutAFile.new(site, site.source, "assets", name)
      page.content = content
      page.data["layout"] = nil
      page.data["sitemap"] = false
      page.output = content
      page
    end
  end
end
