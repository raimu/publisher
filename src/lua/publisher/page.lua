--
--  page.lua
--  speedata publisher
--
--  Copyright 2010-2014 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


local grid = require("publisher.grid")

page = {}

function page.new( self,width,height,additional_margin, trim,pagenumber )
  assert(self)
  if not width then return nil,"No information about page width found. Did you give the command <Pageformat>?" end
  assert(height)

  additional_margin = additional_margin or 0
  trim              = trim              or 0

  local s = {
    grid = grid:new(pagenumber),
    width  = width,
    height = height,
    pagebox = node.new("vlist"),
  }

  s.grid.extra_margin      = additional_margin
  s.grid.trim = trim

  tex.pagewidth  = width   + additional_margin * 2
  tex.pageheight = height  + additional_margin * 2

	setmetatable(s, self)
	return s
end

return page