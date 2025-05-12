-- Sitemap generator
-- SPDX-FileCopyrightText: © 2025 marijan <marijan.petricevic94@gmail.com> (https://marijan.pro)
-- SPDX-License-Identifier: MIT

Plugin.require_version("4.0.0")

data = {}

date_input_formats = soupault_config["index"]["date_formats"]

custom_options = soupault_config["custom_options"]

if not Table.has_key(custom_options, "site_url") then
  Plugin.fail([[custom_options["site_url"] option is required when sitemap generation is enabled]])
end


data["site_url"] = custom_options["site_url"]

function in_section(entry)
  return (entry["nav_path"][1] == config["use_section"])
end

function tags_match(entry)
  if config["use_tag"] then
    return (Regex.match(entry["tags"], format("\\b%s\\b", config["use_tag"])))
  else
    return 1
  end
end

entries = {}

-- Original, unfiltered entries index
local n = 1

-- Index of the new array of entries we are building
local m = 1

local count = size(site_index)
while (n <= count) do
  entry = site_index[n]
  if (in_section(entry) and tags_match(entry)) then
    if entry["date"] then
      entry["date"] = Date.reformat(entry["date"], date_input_formats, "%Y-%m-%dT%H:%M:%S%:z")
    end
    entries[m] = entry
    m = m + 1
  end
  n = n + 1
end

data["entries"] = entries

sitemap_template = Sys.read_file(config["template"])

sitemap = String.render_template(sitemap_template, data)

Sys.write_file(Sys.join_path(target_dir, "../sitemap.xml"), String.trim(sitemap))
