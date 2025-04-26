-- Atom feed generator
-- SPDX-FileCopyrightText: © 2020 Daniil Baturin
-- SPDX-FileCopyrightText: © 2025 marijan <marijan.petricevic94@gmail.com> (https://marijan.pro)
-- SPDX-License-Identifier: MIT
-- Forked from soupault-blueprints-blog/plugins/atom.lua

Plugin.require_version("4.0.0")

data = {}

date_input_formats = soupault_config["index"]["date_formats"]

feed_file = config["feed_file"]

custom_options = soupault_config["custom_options"]

if not Table.has_key(custom_options, "site_url") then
  Plugin.fail([[custom_options["site_url"] option is required when feed generation is enabled]])
end


data["site_url"] = custom_options["site_url"]
data["soupault_version"] = Plugin.soupault_version()

data["feed_url"] = Sys.join_path(Sys.join_path(custom_options["site_url"], config["use_section"]), feed_file)
data["feed_author"] = custom_options["site_author"]
data["feed_author_email"] = custom_options["site_author_email"]
data["feed_title"] = custom_options["site_title"]
data["feed_icon"] = custom_options["site_icon"]


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

if (soupault_config["index"]["sort_descending"] or
   (not Table.has_key(soupault_config["index"], "sort_descending")))
then
  data["feed_last_updated"] = entries[1]["date"]
else
  data["feed_last_updated"] = entries[size(entries)]["date"]
end

data["entries"] = entries

feed_template = Sys.read_file(config["template"])

feed = String.render_template(feed_template, data)

Sys.write_file(Sys.join_path(target_dir, feed_file), String.trim(feed))
