-- extract-canonical.lua
canonical_link = HTML.select(page, "link[rel=\"canonical\"]")
if Table.length(canonical_link) > 1 then
  Plugin.fail("Found more than one canoncial link, make sure there is not more than one canonical link")
end
canonical_link = canonical_link[1]
if canonical_link == nil then
  Plugin.exit("No canonical link defined, nothing to do")
end

head = HTML.select_one(page, "head")
HTML.append_child(head, canonical_link)
HTML.delete(excerpt, canonical_link)
