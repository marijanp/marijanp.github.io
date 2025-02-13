-- article-wrapper.lua
if Regex.match(page_file, "index\\.html$") then
  Plugin.exit("Found index page, ignoring")
end
default_content_selector = soupault_config["settings"]["default_content_selector"]
content = HTML.select_one(page, default_content_selector)
if not HTML.is_element(content) then
  Plugin.fail("No content found")
end
article = HTML.create_element("article")
HTML.add_class(article, "prose")
content_children = HTML.children(content)
idx = 1
while content_children[idx] do
  local child = content_children[idx]
  HTML.append_child(article, child)
  idx = idx + 1
end
HTML.append_child(content, article)
