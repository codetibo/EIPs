#!/usr/bin/env ruby
# frozen_string_literal: true

# validate_listing_filters.rb
#
# Validates that the Liquid filters used in listing pages (core.html, erc.html, etc.)
# match the actual front matter of EIP files in the EIPS/ directory.
#
# Each listing page filters EIPs using `where` conditions in a Liquid `assign` tag.
# If a filter references a field (e.g. `type`, `category`) that doesn't exist in the
# matching EIP files' front matter, those EIPs are silently excluded and the page
# appears empty — like the erc.html bug that was fixed.
#
# Usage:
#   ruby scripts/validate_listing_filters.rb
#
# Must be run from the project root directory.

require 'pathname'

ROOT = Pathname.new(__dir__).parent.freeze

# Define each listing page and the fields its Liquid filter expects to work on.
# - :category => the category value it filters by (e.g. "Core", "ERC")
# - :type     => the type value it filters by (e.g. "Standards Track", "Meta")
# If a field is not listed, the page does not filter by it.
LISTING_PAGES = {
  'core.html'          => { category: 'Core',           type: 'Standards Track' },
  'networking.html'    => { category: 'Networking',     type: 'Standards Track' },
  'interface.html'     => { category: 'Interface',      type: 'Standards Track' },
  'erc.html'           => { category: 'ERC' },
  'meta.html'          => { type: 'Meta' },
  'informational.html' => { type: 'Informational' }
}.freeze

# Extract the list of `where` conditions from the Liquid assign filter.
# Returns an array of [field, value] pairs.
def extract_where_conditions(file_path)
  content = File.read(file_path)
  assign_match = content.match(/\{% assign eips=site\.pages\|(.+?)%\}/)
  return [] unless assign_match

  filter_str = assign_match[1]
  filter_str.scan(/\|where:"([^"]+)","([^"]+)"/)
end

# ---------------------------------------------------------------------------
# Validation logic
# ---------------------------------------------------------------------------

def validate_listing_page(page_rel)
  page_path = ROOT.join(page_rel)
  errors = []

  unless page_path.exist?
    errors << "ERROR: #{page_rel} not found"
    return errors
  end

  expected = LISTING_PAGES.fetch(page_rel)
  category_filter = expected[:category]
  type_filter     = expected[:type]

  # --- Check 1: Do the HTML file's Liquid filters match what we expect? ---
  conditions = extract_where_conditions(page_path)
  condition_fields = conditions.map(&:first)

  if category_filter
    unless condition_fields.include?('category')
      errors << "CONFIG: #{page_rel} does not filter by \"category\" — expected category=\"#{category_filter}\""
    else
      actual = conditions.select { |f, _| f == 'category' }.map(&:last)
      unless actual.include?(category_filter)
        errors << "CONFIG: #{page_rel} filters category by \"#{actual.join(', ')}\" — expected \"#{category_filter}\""
      end
    end
  end

  if type_filter
    unless condition_fields.include?('type')
      errors << "CONFIG: #{page_rel} does not filter by \"type\" — expected type=\"#{type_filter}\""
    else
      actual = conditions.select { |f, _| f == 'type' }.map(&:last)
      unless actual.include?(type_filter)
        errors << "CONFIG: #{page_rel} filters type by \"#{actual.join(', ')}\" — expected \"#{type_filter}\""
      end
    end
  end

  errors
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main
  all_errors = []

  LISTING_PAGES.each_key do |page|
    all_errors.concat(validate_listing_page(page))
  end

  if all_errors.empty?
    puts "\u2705 All listing page filters are valid!"
    exit 0
  else
    puts "\u274c Found #{all_errors.size} listing filter issue(s):"
    all_errors.each { |e| puts "  #{e}" }
    exit 1
  end
end

main if __FILE__ == $PROGRAM_NAME
