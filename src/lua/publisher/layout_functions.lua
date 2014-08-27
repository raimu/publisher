--
--  layout-functions.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.


file_start("layout_functions.lua")

local luxor = do_luafile("luxor.lua")
local sha1  = require('sha1')

local function current_page(  )
  publisher.setup_page()
  return publisher.current_pagenumber
end

local function current_row(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:current_row(arg and arg[1])
end

--- Get the page number of a marker
local function pagenumber(dataxml,arg)
  local m = publisher.markers[arg[1]]
  if m then
    return m.page
  else
    return nil
  end
end

local function current_column(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:current_column(arg and arg[1])
end

local function alternating(dataxml, arg )
  local alt_type = arg[1]
  if not publisher.alternating[alt_type] then
    publisher.alternating[alt_type] = 1
  else
    publisher.alternating[alt_type] = math.fmod( publisher.alternating[alt_type], #arg - 1 ) + 1
  end
  return arg[publisher.alternating[alt_type] + 1]
end

local function reset_alternating( dataxml,arg )
  local alt_type = arg[1]
  publisher.alternating[alt_type] = 0
end

local function number_of_datasets(dataxml,d)
  if not d then return 0 end
  local count = 0
  for i=1,#d do
    if type(d[i]) == 'table' then
      count = count + 1
    end
  end
  return count
end

local function number_of_columns(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:number_of_columns(arg and arg[1])
end

--- Merge numbers like '1,2,3,4,5, 8, 9,10,11' into '1-5, 8-10'
local function merge_pagenumbers(dataxml,arg )
    local pagenumbers_string = string.gsub(arg[1] or "","%s","")
    local mergechar = arg[2] or "–"
    local spacer    = arg[3] or ", "

    local pagenumbers = string.explode(pagenumbers_string,",")
    -- let's remove duplicates now
    local dupes = {}
    local withoutdupes = {}
    local cap1,cap2
    for i=1,#pagenumbers do
        local num = pagenumbers[i]
        cap1, cap2 = string.match(num,"^(.)-(.)$")
        if cap1 then
            for i=tonumber(cap1),tonumber(cap2) do
                num = tostring(i)
                if (not dupes[num]) then
                    withoutdupes[#withoutdupes+1] = num
                    dupes[num] = true
                end
            end
        else
            if (not dupes[num]) then
                withoutdupes[#withoutdupes+1] = num
                dupes[num] = true
            end
        end
    end
    publisher.stable_sort(withoutdupes,function(elta,eltb)
          return tonumber(elta) < tonumber(eltb)
      end)

    if mergechar ~= "" then
        local buckets = {}
        local bucket
        local cur
        local prev = -99
        for i=1,#withoutdupes do
            cur = tonumber(withoutdupes[i])
            if cur == prev + 1 then
                -- same bucket
                bucket[#bucket + 1] = cur
            else
                bucket = { cur }
                buckets[#buckets + 1] = bucket
            end
            prev = cur
        end
        for i=1,#buckets do
            if #buckets[i] > 2 then
                buckets[i] = buckets[i][1] .. mergechar .. buckets[i][#buckets[i]]
            elseif #buckets[i] == 2 then
                buckets[i] = buckets[i][1] .. spacer .. buckets[i][#buckets[i]]
            else
                buckets[i] = buckets[i][1]
            end
        end
        return table.concat(buckets,spacer)
    else
        return table.concat(withoutdupes, spacer)
    end
end

local function number_of_rows(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:number_of_rows(arg and arg[1])
end

local function number_of_pages(dataxml,arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  return img.img.pages
end

local function bildbreite(dataxml, arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  publisher.setup_page()
  local tmp = publisher.current_grid:width_in_gridcells_sp(img.img.width)
  return tmp
end

local function imageheight(dataxml, arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  publisher.setup_page()
  return publisher.current_grid:height_in_gridcells_sp(img.img.height)
end

local function file_exists(dataxml, arg )
    local filename = arg[1]
    if not filename then return false end
    if filename == "" then return false end
    return find_file_location(filename) ~= nil
end

--- Insert 1000's separator and comma separator
local function format_number(dataxml,arg)
  local num, thousandssep,commasep = arg[1], arg[2], arg[3]
  local sign,digits,commadigits = string.match(tostring(num),"([%-%+]?)(%d*)%.?(%d*)")
  local first_digits = math.fmod(#digits,3)
  local ret = {}
  if first_digits > 0 then
    ret[1] = string.sub(digits,0,first_digits)
  end
  for i=1, ( #digits - first_digits) / 3 do
    ret[#ret + 1] = string.sub(digits,first_digits + ( i - 1) * 3 + 1 ,first_digits + i * 3 )
  end
  ret = table.concat(ret, thousandssep)
  if commadigits and #commadigits > 0 then
    return  sign .. ret .. commasep .. commadigits
  else
    return sign .. ret
  end
end

local function format_string( dataxml,arg )
  return string.format(arg[2],arg[1])
end


local function even(dataxml, arg )
  return math.fmod(arg[1],2) == 0
end

local function groupwidth(dataxml, arg )
  publisher.setup_page()
  local groupname=arg[1]
  local groupcontents=publisher.groups[groupname].contents
  local grid = publisher.current_grid
  local width = grid:width_in_gridcells_sp(groupcontents.width)
  return width
end

local function current_frame_number(dataxml,arg)
  local framename = arg[1]
  if framename == nil then return 1 end
  local current_framenumber = current_grid:framenumber(framename)
  return current_framenumber
end

local function groupheight(dataxml, arg )
  publisher.setup_page()
  local groupname=arg[1]
  if not publisher.groups[groupname] then
    err("Can't find group with the name %q",groupname)
    return 0
  end

  local groupcontents=publisher.groups[groupname].contents
  if not groupcontents then
    err("Can't find group with the name %q",groupname)
    return 0
  end
  local grid = publisher.current_grid
  local height = grid:height_in_gridcells_sp(groupcontents.height)
  return height
end

local function odd(dataxml, arg )
  return math.fmod(arg[1],2) ~= 0
end

local function variable(dataxml, arg )
  local varname = table.concat(arg)
  local var = publisher.xpath.get_variable(varname)
  return var
end

local function variable_exists(dataxml,arg)
  local var = publisher.xpath.get_variable(arg[1])
  return var ~= nil
end

local function shaone(dataxml,arg)
    local message = table.concat(arg)
    local ret = sha1.sha1(message)
    return ret
end

local function decode_html( dataxml, arg )
    arg = arg[1]
    local ok
    if type(arg) == "string" then
        ok,ret = pcall(luxor.parse_xml,"<dummy>" .. arg .. "</dummy>")
        if ok then
          return ret
        else
          err("decode-html failed for input string %q (1)",arg)
        end
        return arg
    end
  for i=1,#arg do
    for j=1,#arg[i] do
      local txt = arg[i][j]
      if type(txt) == "string" then
        if string.find(txt,"<") then
          local x = luxor.parse_xml(txt)
          arg[i][j] = x
        end
      end
    end
  end
  return arg
end

local function count_saved_paged(dataxml,arg)
    return #publisher.pagestore[arg[1]]
end

local function loremipsum( )
    local lorem = [[
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
    ]]
    return lorem:gsub("^%s*(.-)%s*$","%1"):gsub("[%s\n]+"," ")
end

local register = publisher.xpath.register_function
register("urn:speedata:2009/publisher/functions/en","number-of-rows",number_of_rows)
register("urn:speedata:2009/publisher/functions/de","anzahl-zeilen",number_of_rows)

register("urn:speedata:2009/publisher/functions/en","number-of-columns",number_of_columns)
register("urn:speedata:2009/publisher/functions/de","anzahl-spalten",number_of_columns)

register("urn:speedata:2009/publisher/functions/en","number-of-pages",number_of_pages)
register("urn:speedata:2009/publisher/functions/de","anzahl-seiten",number_of_pages)

register("urn:speedata:2009/publisher/functions/en","current-page",current_page)
register("urn:speedata:2009/publisher/functions/de","aktuelle-seite",current_page)

register("urn:speedata:2009/publisher/functions/en","current-column",current_column)
register("urn:speedata:2009/publisher/functions/de","aktuelle-spalte",current_column)

register("urn:speedata:2009/publisher/functions/en","decode-html",decode_html)
register("urn:speedata:2009/publisher/functions/de","html-dekodieren",decode_html)

register("urn:speedata:2009/publisher/functions/en","file-exists",file_exists)
register("urn:speedata:2009/publisher/functions/de","datei-vorhanden",file_exists)

register("urn:speedata:2009/publisher/functions/en","number-of-datasets",number_of_datasets)
register("urn:speedata:2009/publisher/functions/de","anzahl-datensätze",number_of_datasets)
register("urn:speedata:2009/publisher/functions/de","anzahl-datensaetze",number_of_datasets)

register("urn:speedata:2009/publisher/functions/en","even",even)
register("urn:speedata:2009/publisher/functions/de","gerade",even)

register("urn:speedata:2009/publisher/functions/en","odd",odd)
register("urn:speedata:2009/publisher/functions/de","ungerade",odd)

register("urn:speedata:2009/publisher/functions/en","pagenumber",pagenumber)
register("urn:speedata:2009/publisher/functions/de","seitennummer",pagenumber)

register("urn:speedata:2009/publisher/functions/en","variable",variable)
register("urn:speedata:2009/publisher/functions/de","variable",variable)

register("urn:speedata:2009/publisher/functions/en","variable-exists",variable_exists)
register("urn:speedata:2009/publisher/functions/de","variable-vorhanden",variable_exists)

register("urn:speedata:2009/publisher/functions/en","merge-pagenumbers",merge_pagenumbers)
register("urn:speedata:2009/publisher/functions/de","seitenzahlen-zusammenfassen",merge_pagenumbers)

register("urn:speedata:2009/publisher/functions/en","current-row",current_row)
register("urn:speedata:2009/publisher/functions/de","aktuelle-zeile",current_row)

register("urn:speedata:2009/publisher/functions/en","current-framenumber",current_frame_number)
register("urn:speedata:2009/publisher/functions/de","aktuelle-rahmennummer",current_frame_number)

register("urn:speedata:2009/publisher/functions/en","alternating",alternating)
register("urn:speedata:2009/publisher/functions/de","alternierend",alternating)

register("urn:speedata:2009/publisher/functions/en","group-height",groupheight)
register("urn:speedata:2009/publisher/functions/en","groupheight",groupheight)
register("urn:speedata:2009/publisher/functions/de","gruppenhöhe",groupheight)

register("urn:speedata:2009/publisher/functions/en","group-width",groupwidth)
register("urn:speedata:2009/publisher/functions/en","groupwidth",groupwidth)
register("urn:speedata:2009/publisher/functions/de","gruppenbreite",groupwidth)

register("urn:speedata:2009/publisher/functions/en","format-number",format_number)
register("urn:speedata:2009/publisher/functions/de","formatiere-zahl",format_number)

register("urn:speedata:2009/publisher/functions/en","format-string",format_string)
register("urn:speedata:2009/publisher/functions/de","formatiere-string",format_string)

register("urn:speedata:2009/publisher/functions/en","imagewidth",bildbreite)
register("urn:speedata:2009/publisher/functions/de","bildbreite",bildbreite)

register("urn:speedata:2009/publisher/functions/en","imageheight",imageheight)
register("urn:speedata:2009/publisher/functions/de","bildhöhe",imageheight)

register("urn:speedata:2009/publisher/functions/en","reset_alternating",reset_alternating) -- backward comp.
register("urn:speedata:2009/publisher/functions/en","reset-alternating",reset_alternating)
register("urn:speedata:2009/publisher/functions/de","alternierend_zurücksetzen",reset_alternating)

register("urn:speedata:2009/publisher/functions/en","count-saved-pages",count_saved_paged)
register("urn:speedata:2009/publisher/functions/de","anzahl-gespeicherte-seiten",count_saved_paged)

register("urn:speedata:2009/publisher/functions/en","sha1",shaone)
register("urn:speedata:2009/publisher/functions/de","sha1",shaone)

register("urn:speedata:2009/publisher/functions/en","dummytext",loremipsum)
register("urn:speedata:2009/publisher/functions/de","blindtext",loremipsum)
register("urn:speedata:2009/publisher/functions/en","loremipsum",loremipsum)
register("urn:speedata:2009/publisher/functions/de","loremipsum",loremipsum)

file_end("layout_functions.lua")
