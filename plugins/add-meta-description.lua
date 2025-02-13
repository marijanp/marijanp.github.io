-- add-meta-description.lua
excerpts = HTML.select(page, "p#excerpt")
if Table.length(excerpts) > 1 then
  Plugin.fail("Found more than one excerpt, make sure there is not more than one excerpt")
end
excerpt = excerpts[1]
if excerpt == nil then
  Plugin.exit("No excerpt defined, nothing to do")
end

head = HTML.select_one(page, "head")
description = HTML.create_element("meta")
HTML.set_attribute(description, "name", "description")
HTML.set_attribute(description, "content", HTML.strip_tags(excerpt))
HTML.append_child(head, description)
HTML.delete(excerpt)
