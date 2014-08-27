--- This file contains the code for the user commands. They are called from publisher#dispatch.
--
--  commands.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("commands.lua")

require("publisher.fonts")
require("publisher.tabular")
local spotcolors = require("spotcolors")
local paragraph  = require("paragraph")
do_luafile("css.lua")

-- This module contains the commands in the layout file (the tags)
commands = {}

--- A
--- -----
--- Insert a hyperlink into the PDF.
function commands.a( layoutxml,dataxml )
    trace("A")
    local href = publisher.read_attribute(layoutxml,dataxml,"href","rawstring")
    local ai = node.new("action")
    ai.action_type = 3
    ai.data = string.format("/Subtype/Link/A<</Type/Action/S/URI/URI(%s)>>",href)
    local stl = node.new("whatsit","pdf_start_link")
    stl.action = ai
    stl.width = -1073741824
    stl.height = -1073741824
    stl.depth = -1073741824
    p = paragraph:new()
    p:append(stl)

    local tab = publisher.dispatch(layoutxml,dataxml)
    local objects = {}
    for i,j in ipairs(tab) do
        if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
            objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j))
        else
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    for _,j in ipairs(objects) do
        p:append(j,{})
    end
    local enl = node.new("whatsit","pdf_end_link")
    p:append(enl)


    return p
end

--- Action
--- ------
--- Create a whatsit node of type 44 (`user_defined`). The action
--- `AddToList` is not well tested. Actions are
--- processed  after page shipout. The idea behind that is that we don't
--- really know in advance which elements are put on a page and which are
--- broken to the next page. This way we can find out exactly where something
--- is  placed.
function commands.action( layoutxml,dataxml)
    local tab = publisher.dispatch(layoutxml,dataxml)
    p = paragraph:new()

    for _,j in ipairs(tab) do
        local eltname = publisher.elementname(j,true)
        if eltname == "AddToList" then
            local n = node.new("whatsit","user_defined")
            n.user_id = publisher.user_defined_addtolist
            n.type = 100  -- type 100: "value is a number"
            n.value = publisher.element_contents(j) -- pointer to the function (int)
            p:append(n)
        elseif eltname == "Mark" then
            local tab = publisher.element_contents(j)
            local n = node.new("whatsit","user_defined")
            if tab.append == true then
                n.user_id = publisher.user_defined_mark_append -- a magic number
            else
                n.user_id = publisher.user_defined_mark
            end
            n.type = 115  -- type 115: "value is a string"
            n.value = tab.selection
            p:append(n)
        end
    end
    return p
end



--- AddToList
--- ---------
--- Return a number. This number is an index to the table `publisher.user_defined_functions` and the value
--- is a function that sets a key of another table.
function commands.add_to_list( layoutxml,dataxml )
    local key        = publisher.read_attribute(layoutxml,dataxml,"key","rawstring")
    local listname   = publisher.read_attribute(layoutxml,dataxml,"list","rawstring")
    local selection  = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")

    local value = xpath.parse(dataxml,selection,layoutxml[".__ns"])
    local var = publisher.xpath.get_variable(listname)
    if not var then var = {} end
    publisher.xpath.set_variable(listname,var)

    local udef = publisher.user_defined_functions
    udef[udef.last + 1] = function() var[#var + 1] = { key , value } end
    udef.last = udef.last + 1
    return udef.last
end


--- Attribute
--- ---------
--- Create an attribute to be used in a XML structure. The XML structure can be formed via
--- Element and Attribute commands and writen to disk with SaveDataset.
function commands.attribute( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
    local attname   = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")

    if not selection then return { [".__type"]="attribute", [attname] = "" } end
    local ret = { [".__type"]="attribute", [attname] = publisher.xml_escape(xpath.textvalue(selection)) }
    return ret
end

--- AtPageCreation
--- -------------
--- Run these commands when a page is created (as soon as the first element is written to it).
--- You can add header/footer and other repeating elements. These commands are
--- not executed when encountered, rather in `publisher#setup_page()`.
function commands.atpagecreation( layoutxml,dataxml )
    return layoutxml
end

--- AtPageShipout
--- -------------
--- Run these commands when a page is ready to be put in
--- the PDF. You can add header/footer. These commands are
--- not executed when encountered, rather in `publisher#new_page()`.
function commands.atpageshipout( layoutxml,dataxml )
    return layoutxml
end

--- Barcode
--- -------
--- Create a EAN 13 barcode. The width of the barcode depends on the font
--- given in `fontface` (or the default `text`).
function commands.barcode( layoutxml,dataxml )
    trace("Command: Barcode")
    local width     = publisher.read_attribute(layoutxml,dataxml,"width"    ,"length_sp"     )
    local height    = publisher.read_attribute(layoutxml,dataxml,"height"   ,"height_sp"     )
    local typ       = publisher.read_attribute(layoutxml,dataxml,"type"     ,"rawstring"     )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select"   ,"xpath"         )
    local fontname  = publisher.read_attribute(layoutxml,dataxml,"fontface" ,"rawstring"     )
    local showtext  = publisher.read_attribute(layoutxml,dataxml,"showtext" ,"boolean", "yes")
    local overshoot = publisher.read_attribute(layoutxml,dataxml,"overshoot","number"        )

    width = width or xpath.get_variable("__maxwidth") * publisher.current_grid.gridwidth

    local fontfamily
    if fontname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
        if not fontfamily then
            err("Fontfamily %q not found.",fontname or "???")
            fontfamily = 1
        end
    else
        fontfamily = 1
    end
    if typ=="Code128" then
        return barcodes.code128(width,height,fontfamily,selection,showtext)
    elseif typ=="EAN13" then
        return barcodes.ean13(width,height,fontfamily,selection,showtext,overshoot)
    elseif typ=="QRCode" then
        return barcodes.qrcode(width,height,selection)
    else
        err("Unknown barcode type %q", typ or "?")
    end
end

--- Bold text (`<B>`)
--- -------------------
--- Set the contents of this element in boldface
function commands.bold( layoutxml,dataxml )
    local a = paragraph:new()

    local objects = {}
    local tab = publisher.dispatch(layoutxml,dataxml)

    for i,j in ipairs(tab) do
        if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
            objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j),{bold = true})
        else
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    for _,j in ipairs(objects) do
        a:append(j,{fontfamily = 0, bold = 1})
    end

    return a
end

--- Br
--- ---
--- Insert a newline
function commands.br( layoutxml,dataxml )
    a = paragraph:new()
    a:append("\n",{})
    return a
end

--- Box
--- ----
--- Draw a rectangular filled area
function commands.box( layoutxml,dataxml )
    local width     = publisher.read_attribute(layoutxml,dataxml,"width","length")
    local height    = publisher.read_attribute(layoutxml,dataxml,"height","length")
    local colorname = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","rawstring")
    local bleed     = publisher.read_attribute(layoutxml,dataxml,"bleed","string")

    local current_grid = publisher.current_grid

    -- Todo: document length or number
    if tonumber(width) ~= nil then
        width  = current_grid.gridwidth  * width
    else
        width = tex.sp(width)
    end

    if tonumber(height) ~= nil then
        height = current_grid.gridheight * height
    else
        height = tex.sp(height)
    end

    local shift_left,shift_up = 0,0

    if bleed then
        local trim = publisher.options.trim or 0
        local positions = string.explode(bleed,",")
        for i,v in ipairs(positions) do
            if v == "top" then
                height = height + trim
                shift_up = trim
            elseif v == "right" then
                width = width + trim
            elseif v == "bottom" then
                height = height + trim
            elseif v == "left" then
                width = width + trim
                shift_left = trim
            end
        end
    end

    local n = publisher.box(width,height,colorname)
    node.set_attribute(n, publisher.att_shift_left, shift_left)
    node.set_attribute(n, publisher.att_shift_up  , shift_up )
    return n
end

--- Bookmark
--- --------
--- PDF bookmarks (for the PDF viewer)
function commands.bookmark( layoutxml,dataxml )
    trace("Command: Bookmark")
    --- For bookmarks, we need two things:
    ---
    --- 1) a destination and
    --- 2) the bookmark itself that points to the destination.
    ---
    --- So we can safely insert the destination in our text flow but save the
    --- destination code (a number) for later. There is a slight problem now: as
    --- the text flow is asynchronous, we evaluate the bookmark during page
    --- shipout. Then we have the correct order (hopefully)
    local title  = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
    local level  = publisher.read_attribute(layoutxml,dataxml,"level", "number")
    local open_p = publisher.read_attribute(layoutxml,dataxml,"open",  "boolean")

    local hlist = publisher.mkbookmarknodes(level,open_p,title)
    local p = paragraph:new()
    p:append(hlist)
    return p
end

--- Color
--- -----
--- Set the color of the enclosed text.
function commands.color( layoutxml, dataxml )
    local colorname = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")
    local colortable
    if colorname then
        if not publisher.colors[colorname] then
            err("Color %q is not defined yet.",colorname)
        else
            colortable = publisher.colors[colorname].index
        end
    end

    local a = paragraph:new()

    local objects = {}
    local tab = publisher.dispatch(layoutxml,dataxml)

    for i,j in ipairs(tab) do
        if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
            objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j),{})
        else
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    for _,j in ipairs(objects) do
        a:append(j,{})
    end

    a:set_color(colortable)
    return a
end


--- Column
--- ------
--- Set defintions for a specific column of a table.
function commands.column( layoutxml,dataxml )
    local ret = {}
    ret.width            = publisher.read_attribute(layoutxml,dataxml,"width","rawstring")
    ret.backgroundcolor  = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","rawstring")
    ret.align            = publisher.read_attribute(layoutxml,dataxml,"align","string")
    ret.valign           = publisher.read_attribute(layoutxml,dataxml,"valign","string")

    return ret
end


--- Columns
--- -------
--- Set the width of a table to a fixed size. Expects multiple occurrences of element
--- Column as the child elements.
function commands.columns( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    return tab
end

--- CopyOf
--- ------
--- Return the contents of a variable. Warning: this function does not actually copy the contents, so the name is a bit misleading.
function commands.copy_of( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select", "rawstring")
    local ok
    if layoutxml[1] and #layoutxml[1] > 0 then
        return table.concat(layoutxml)
    else
        ok,selection = xpath.parse_raw(dataxml,selection,layoutxml[".__ns"])
        if not ok then
            err(selection)
            return nil
        end
        return selection
    end
end

--- DefineColor
--- -----------
--- Colors can be in model cmyk or rgb.
function commands.define_color( layoutxml,dataxml )
    local name  = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")
    local value = publisher.read_attribute(layoutxml,dataxml,"value","rawstring")
    local model = publisher.read_attribute(layoutxml,dataxml,"model","string")
    local colorname = publisher.read_attribute(layoutxml,dataxml,"colorname","rawstring")
    local overprint = publisher.read_attribute(layoutxml,dataxml,"overprint","boolean")


    local color = setmetatable({},
        {
           __index = function(tbl,idx)
               if idx == "pdfstring" and tbl.model == "spotcolor" then
                publisher.usespotcolor(tbl.colornum)
                local op
                if tbl.overprint then
                    op = "/GS0 gs"
                else
                    op = ""
                end
                return string.format("%s /CS%d cs 1 scn ",op,tbl.colornum)
               end
           end
        })
    color.overprint = overprint

    local op
    if overprint then
        op = "/GS0 gs"
    else
        op = ""
    end

    if model=="cmyk" then
        color.c = publisher.read_attribute(layoutxml,dataxml,"c","number")
        color.m = publisher.read_attribute(layoutxml,dataxml,"m","number")
        color.y = publisher.read_attribute(layoutxml,dataxml,"y","number")
        color.k = publisher.read_attribute(layoutxml,dataxml,"k","number")
        color.pdfstring = string.format("%s %g %g %g %g k %g %g %g %g K", op, color.c/100, color.m/100, color.y/100, color.k/100,color.c/100, color.m/100, color.y/100, color.k/100)
    elseif model=="rgb" then
        color.r = publisher.read_attribute(layoutxml,dataxml,"r","number") / 100
        color.g = publisher.read_attribute(layoutxml,dataxml,"g","number") / 100
        color.b = publisher.read_attribute(layoutxml,dataxml,"b","number") / 100
        color.pdfstring = string.format("%s %g %g %g rg %g %g %g RG", op, color.r, color.g, color.b, color.r,color.g, color.b)
    elseif model=="gray" then
        color.g = publisher.read_attribute(layoutxml,dataxml,"g","number")
        color.pdfstring = string.format("%s %g g %g G",op,color.g/100,color.g/100)
    elseif model=="spotcolor" then
        color.colornum = spotcolors.register(colorname)
    elseif value then
        local r,g,b
        if #value == 7 then
            model = "rgb"
            r,g,b = string.match(value,"#?(%x%x)(%x%x)(%x%x)")
            color.r = math.round(tonumber(r,16) / 255, 3)
            color.g = math.round(tonumber(g,16) / 255, 3)
            color.b = math.round(tonumber(b,16) / 255, 3)
            color.pdfstring = string.format("%s %g %g %g rg %g %g %g RG", op, color.r, color.g, color.b, color.r,color.g, color.b)
        elseif #value == 4 then
            model = "rgb"
            r,g,b = string.match(value,"#?(%x)(%x)(%x)")
            color.r = math.round(tonumber(r,16) / 15, 3)
            color.g = math.round(tonumber(g,16) / 15, 3)
            color.b = math.round(tonumber(b,16) / 15, 3)
            color.pdfstring = string.format("%s %g %g %g rg %g %g %g RG", op, color.r, color.g, color.b, color.r,color.g, color.b)
        end
    else
        err("Unknown color model: %s",model or "?")
    end

    log("Defining color %q",name)
    color.model = model
    color.index = publisher.register_color(name)
    publisher.colors[name]=color
end

--- Define Textformat
--- ----------------
--- A text format defines the alignment and indentation of a paragraph.
---
--- The rules for textformat:
---
--- * if a paragraph has a textformat then use it, end
--- * if the textblock has a textformat then use it, end
--- * use the textformat `text` end
function commands.define_textformat(layoutxml)
    trace("Command: DefineTextformat")
    local alignment    = publisher.read_attribute(layoutxml,dataxml,"alignment",   "string")
    local indentation  = publisher.read_attribute(layoutxml,dataxml,"indentation", "length")
    local name         = publisher.read_attribute(layoutxml,dataxml,"name",        "rawstring")
    local rows         = publisher.read_attribute(layoutxml,dataxml,"rows",        "number")
    local bordertop    = publisher.read_attribute(layoutxml,dataxml,"border-top",  "rawstring")
    local borderbottom = publisher.read_attribute(layoutxml,dataxml,"border-bottom","rawstring")
    local margintop     = publisher.read_attribute(layoutxml,dataxml,"margin-top",    "rawstring")
    local marginbottom  = publisher.read_attribute(layoutxml,dataxml,"margin-bottom", "rawstring")
    local paddingtop    = publisher.read_attribute(layoutxml,dataxml,"padding-top",   "rawstring")
    local paddingbottom = publisher.read_attribute(layoutxml,dataxml,"padding-bottom","rawstring")
    local breakbelow    = publisher.read_attribute(layoutxml,dataxml,"break-below",   "boolean", true)
    local orphan        = publisher.read_attribute(layoutxml,dataxml,"orphan",        "boolean", false)
    local widow         = publisher.read_attribute(layoutxml,dataxml,"widow",         "boolean", false)
    local hyphenate     = publisher.read_attribute(layoutxml,dataxml,"hyphenate",     "boolean", true)

    local fmt = {}

    if alignment == "leftaligned" or alignment == "rightaligned" or alignment == "centered" then
        fmt.alignment = alignment
    else
        fmt.alignment = "justified"
    end

    fmt.orphan = orphan
    fmt.widow = widow
    fmt.disable_hyphenation = not hyphenate

    if indentation then
        fmt.indent = tex.sp(indentation)
    end
    if rows then
        fmt.rows = rows
    else
        fmt.rows = 1
    end
    if bordertop then
        fmt.bordertop = tex.sp(bordertop)
    end
    if borderbottom then
        fmt.borderbottom = tex.sp(borderbottom)
    end
    if margintop then
        fmt.margintop = tex.sp(margintop)
    end
    if marginbottom then
        fmt.marginbottom = tex.sp(marginbottom)
    end
    if paddingtop then
        fmt.paddingtop = tex.sp(paddingtop)
    end
    if paddingbottom then
        fmt.paddingbottom = tex.sp(paddingbottom)
    end

    fmt.breakbelow = breakbelow


    publisher.textformats[name] = fmt
end

--- Define Fontfamily
--- -----------------
--- Define a font family. A font family must consist of a `Regular` shape, optional are `Bold`,
--- `BoldItalic` and `Italic`.
function commands.define_fontfamily( layoutxml,dataxml )
    local fonts = publisher.fonts
    local fam={}
    -- fontsize and baselineskip are in dtp points (bp, 1 bp ≈ 65782 sp)
    -- Concrete font instances are created here. fontsize and baselineskip are known
    local name         = publisher.read_attribute(layoutxml,dataxml,"name",    "rawstring" )
    local size         = publisher.read_attribute(layoutxml,dataxml,"fontsize","rawstring")
    local baselineskip = publisher.read_attribute(layoutxml,dataxml,"leading", "rawstring")

    if size == nil then
      err("DefineFontfamily: no size given.")
      return
    end
    if tonumber(size) == nil then
        size = tex.sp(size)
    else
        size = size * publisher.factor
    end

    if baselineskip == nil then
        err("DefineFontfamily: no leading given.")
        return
    end
    if tonumber(baselineskip) == nil then
        baselineskip = tex.sp(baselineskip)
    else
        baselineskip = baselineskip * publisher.factor
    end

    fam.size         = size
    fam.baselineskip = baselineskip
    fam.scriptsize   = fam.size * 0.8 -- subscript / superscript
    fam.scriptshift  = fam.size * 0.3

    local ok,tmp,elementname,fontface
    for i,v in ipairs(layoutxml) do
        elementname = publisher.translate_element(v[".__local_name"])
        fontface    = publisher.read_attribute(v,dataxml,"fontface","rawstring")
        if type(v) ~= "table" then
            -- ignore
        elseif elementname=="Regular" then
            ok,tmp=fonts.make_font_instance(fontface,fam.size)
            if ok then
                fam.normal = tmp
            else
                fam.normal = 1
                err("Fontinstance 'normal' could not be created for %q.",tostring(fontface))
            end
            ok,tmp=fonts.make_font_instance(fontface,fam.scriptsize)
            if ok then
                fam.normalscript = tmp
            end
        elseif elementname=="Bold" then
            ok,tmp=fonts.make_font_instance(fontface,fam.size)
            if ok then
                fam.bold = tmp
            end
            ok,tmp=fonts.make_font_instance(fontface,fam.scriptsize)
            if ok then
                fam.boldscript = tmp
            end
        elseif elementname =="Italic" then
            ok,tmp=fonts.make_font_instance(fontface,fam.size)
            if ok then
                fam.italic = tmp
            end
            ok,tmp=fonts.make_font_instance(fontface,fam.scriptsize)
            if ok then
                fam.italicscript = tmp
            end
        elseif elementname =="BoldItalic" then
            ok,tmp=fonts.make_font_instance(fontface,fam.size)
            if ok then
                fam.bolditalic = tmp
            end
            ok,tmp=fonts.make_font_instance(fontface,fam.scriptsize)
            if ok then
                fam.bolditalicscript = tmp
            end
        end
        if type(v) == "table" and not ok then
            err("Error creating font instance %q: %s", elementname or "??", tmp or "??")
        end
    end
    fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
    fonts.lookup_fontfamily_name_number[name]=#fonts.lookup_fontfamily_number_instance
    log("DefineFontfamily, family=%d, name=%q",#fonts.lookup_fontfamily_number_instance,name)
end

--- Element
--- -------
--- Create an element for use with Attribute and SaveDataset
function commands.element( layoutxml,dataxml )
    local elementname = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")

    local ret = { [".__local_name"] = elementname }

    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,v in ipairs(tab) do
        local contents = publisher.element_contents(v)
        if contents[".__type"]=="attribute" then
            -- Attribute
            for _k,_v in pairs(contents) do
                if _k ~= ".__type" then
                    ret[_k] = _v
                end
            end
        else
            -- .__local_name can be nil if we add Elements in another Element
            -- The Elements are stored in sub-tables
            if contents[".__local_name"] == nil then
                for i=1,#contents do
                    ret[#ret + 1] = contents[i]
                end
            else
                ret[#ret + 1] = contents
            end
        end
    end

    return ret
end


--- FontFace
--- --------
--- Set the font face (family) of the enclosed text.
function commands.fontface( layoutxml,dataxml )
    local fontfamily   = publisher.read_attribute(layoutxml,dataxml,"fontfamily","rawstring")
    local familynumber = publisher.fonts.lookup_fontfamily_name_number[fontfamily]
    if not familynumber then
        err("font: family %q unknown",fontfamily)
    else
        local a = paragraph:new()
        local tab = publisher.dispatch(layoutxml,dataxml)
        for i,j in ipairs(tab) do
            a:append(xpath.textvalue_raw(true,publisher.element_contents(j)),{fontfamily = familynumber})
        end
        return a
    end
end

--- ForAll
--- --------
--- Execute the child elements for all elements given by the `select` attribute.
function commands.forall( layoutxml,dataxml )
    trace("ForAll")
    local limit = publisher.read_attribute(layoutxml,dataxml,"limit","number")
    local tab = {}
    local tmp_tab
    local current_position = publisher.xpath.get_variable("__position")
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    limit = limit or #selection
    if limit > #selection then
        limit = #selection
    end
    for i=1,limit do
        publisher.xpath.set_variable("__position",i)
        tmp_tab = publisher.dispatch(layoutxml,selection[i])
        for j=1,#tmp_tab do
            tab[#tab + 1] = tmp_tab[j]
        end
    end
    publisher.xpath.set_variable("__position",current_position)
    return tab
end

--- Grid
--- -----
--- Set the grid in a group (also in a pagetype?)
function commands.grid( layoutxml,dataxml )
    local width  = publisher.read_attribute(layoutxml,dataxml,"width",  "length_sp")
    local height = publisher.read_attribute(layoutxml,dataxml,"height", "length_sp")
    local nx     = publisher.read_attribute(layoutxml,dataxml,"nx",     "rawstring")
    local ny     = publisher.read_attribute(layoutxml,dataxml,"ny",     "rawstring")

    return { width = width, height = height, nx = tonumber(nx), ny = tonumber(ny) }
end

--- Group
--- -----
--- Create a virtual area
function commands.group( layoutxml,dataxml )
    local elementname
    local grid
    publisher.setup_page()
    local groupname = publisher.read_attribute(layoutxml,dataxml,"name", "rawstring")

    if publisher.groups[groupname] == nil then
        log("Create »Group« %q.",groupname)
    else
        log("Re-use »Group« %q.",groupname)
        -- The old nodes are still in the group. We should clean the nodes
        -- but this cleans too much.
        -- copy-of should really copy the nodes. FIXME
        -- See qa/groups/reusegroup, commit d20aeb890b9
        -- node.flush_list(publisher.groups[groupname].contents)
        publisher.groups[groupname] = nil
    end

    for _,v in ipairs(layoutxml) do
        elementname=publisher.translate_element(v[".__local_name"])
        if type(v)=="table" and elementname=="Grid" then
            grid = commands.grid(v,dataxml)
        end
    end


    local r = publisher.grid:new(-999)
    r:set_margin(0,0,0,0)
    if grid then
        if grid.nx or grid.ny then
            err("Setting grid via nx or ny doesn't make sense in groups. Fallback to 1cm.")
            grid.width = tex.sp("1cm")
            grid.height = grid.width
        end
        r:set_width_height({wd = grid.width, ht = grid.height})
    else
        r:set_width_height({wd = publisher.current_page.grid.gridwidth, ht = publisher.current_page.grid.gridheight})
    end
    publisher.groups[groupname] = {
        contents = contents,
        grid     = r,
    }

    local save_grid      = publisher.current_grid
    local save_groupname = publisher.current_group

    publisher.current_group = groupname
    publisher.current_grid  = r

    for _,v in ipairs(layoutxml) do
        elementname=publisher.translate_element(v[".__local_name"])
        if type(v)=="table" and elementname=="Contents" then
            publisher.dispatch(v,dataxml)
        end
    end

    publisher.current_group  = save_groupname
    publisher.current_grid = save_grid
end

--- HSpace
--- ------
--- Create a horizontal space that stretches up to infinity
function commands.hspace( layoutxml,dataxml )
    a = paragraph:new()
    local n=node.new("glue")
    n.spec=node.new("glue_spec")
    n.spec.width = 0
    n.spec.stretch = 65536
    n.spec.stretch_order = 3
    a:append(n,{})
    return a
end

--- Hyphenation
--- -----------
--- The contents of this element must be a string such as `hy-phen-ation`.
-- FIXME: allow language attribute.
function commands.hyphenation( layoutxml,dataxml )
    local l = publisher.get_language(publisher.defaultlanguage)
    lang.hyphenation(l.l,layoutxml[1])
end

--- Include
--- -------
--- Dummy element for use in files that are included by the `xi:include` instruction.
function commands.include( layoutxml,dataxml )
    return publisher.dispatch(layoutxml,dataxml)
end

local box_lookup = {
    ["artbox"]   = "art",
    ["cropbox"]  = "crop",
    ["trimbox"]  = "trim",
    ["mediabox"] = "media",
    ["bleedbox"] =  "bleed",
}


--- Image
--- -----
--- Load an image from a file. To be used in a table cell and PlaceObject.
function commands.image( layoutxml,dataxml )
    local width     = publisher.read_attribute(layoutxml,dataxml,"width",      "rawstring")
    local height    = publisher.read_attribute(layoutxml,dataxml,"height",     "rawstring")
    local minwidth  = publisher.read_attribute(layoutxml,dataxml,"minwidth",   "rawstring")
    local minheight = publisher.read_attribute(layoutxml,dataxml,"minheight",  "rawstring")
    local maxwidth  = publisher.read_attribute(layoutxml,dataxml,"maxwidth",   "rawstring")
    local maxheight = publisher.read_attribute(layoutxml,dataxml,"maxheight",  "rawstring")
    local clip      = publisher.read_attribute(layoutxml,dataxml,"clip",       "boolean")
    local seite     = publisher.read_attribute(layoutxml,dataxml,"page",       "number")
    local nat_box   = publisher.read_attribute(layoutxml,dataxml,"naturalsize","string")
    local max_box   = publisher.read_attribute(layoutxml,dataxml,"maxsize",    "rawstring")
    local filename  = publisher.read_attribute(layoutxml,dataxml,"file",       "rawstring")
    local url       = publisher.read_attribute(layoutxml,dataxml,"href",       "rawstring")
    local dpiwarn   = publisher.read_attribute(layoutxml,dataxml,"dpiwarn",    "number")

    -- width = 100%  => take width from surrounding area
    -- auto on any value ({max,min}?{width,height}) is default

    local nat_box_intern = box_lookup[nat_box] or "crop"
    local max_box_intern = box_lookup[max_box] or "crop"

    local imageinfo
    if url ~= nil then
        imageinfo = publisher.get_image(url)
    else
        imageinfo = publisher.new_image(filename,seite,max_box_intern)
    end

    local image = img.copy(imageinfo.img)

    height    = publisher.set_image_length(height,   "height") or image.height
    width     = publisher.set_image_length(width,    "width" ) or image.width
    minheight = publisher.set_image_length(minheight,"height") or 0
    minwidth  = publisher.set_image_length(minwidth, "width" ) or 0
    maxheight = publisher.set_image_length(maxheight,"height") or publisher.maxdimen
    maxwidth  = publisher.set_image_length(maxwidth, "width" ) or publisher.maxdimen

    if not clip then
        width, height = publisher.calculate_image_width_height( image, width,height,minwidth,minheight,maxwidth, maxheight )
        if dpiwarn then
            local inch_x = width / publisher.factor / 72
            local inch_y = height / publisher.factor / 72
            if (image.xsize / inch_x) < dpiwarn then
                warning("Image dpi value too small (horizontal). Rendered is %d, requested minimum is %d. Filename: %q", image.xsize / inch_x,dpiwarn,filename)
            end
            if (image.ysize / inch_y) < dpiwarn then
                warning("Image dpi value too small (vertical). Rendered is %d, requested minimum is %d. Filename: %q", image.xsize / inch_x,dpiwarn,filename)
            end
        end
    end

    local overshoot
    if clip then
        local stretch_shrink
        if width / image.width > height / image.height then
            stretch_shrink = width / image.width
            overshoot = math.round(  (image.height * stretch_shrink - height ) / publisher.factor / 2,3)
            overshoot = -overshoot
        else
            stretch_shrink = height / image.height
            overshoot = math.round(  (image.width * stretch_shrink - width) / publisher.factor / 2 ,3)
        end
        width = image.width   * stretch_shrink
        height = image.height * stretch_shrink
    end

    local shift_left,shift_up = 0,0

    image.width  = width
    image.height = height

    local box
    if clip then
        local a=node.new("whatsit","pdf_literal")
        local ht = math.round(height / publisher.factor,4)
        local wd = math.round(width  / publisher.factor,4)
        local right,left,top,bottom
        -- overshoot > 0 if image is too wide else < 0
        if overshoot > 0 then
            right  = wd - overshoot
            left   = overshoot
            top    = ht
            bottom = 0
            shift_left = left * publisher.factor
        else
            right  = wd
            left   = 0
            top    = ht + overshoot
            bottom = -overshoot
            shift_up = bottom * publisher.factor
        end
        left   = math.round(left,3)
        right  = math.round(right,3)
        top    = math.round(top,3)
        bottom = math.round(bottom,3)

        pdf_save = node.new("whatsit","pdf_save")
        pdf_restore = node.new("whatsit","pdf_restore")

        a.data = string.format("%g %g m %g %g l %g %g l %g %g l W n ",left,bottom,right,bottom,right,top,left,top)
        i = img.node(image)
        node.insert_after(pdf_save,pdf_save,a)
        node.insert_after(a,a,i)
        box = node.hpack(pdf_save)
        box.depth = 0
        node.insert_after(box,node.tail(box),pdf_restore)
        box = node.vpack(box)

        local g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = -1 * shift_left
        g = node.insert_after(g,g,box)
        box = node.hpack(g)

        g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = -1 * shift_up
        g = node.insert_after(g,g,box)
        box = node.vpack(g)

        box.height = height - shift_up * 2
        box.width  = width  - shift_left * 2
    else
        box = node.hpack(img.node(image))
        node.set_attribute(box,publisher.att_lineheight,box.height)
    end
    -- node.set_attribute(box, publisher.att_shift_left, shift_left)
    -- node.set_attribute(box, publisher.att_shift_up  , shift_up  )
    return {box,imageinfo.allocate}
end

--- InsertPages
--- -----------
--- Insert previously saved pages with SavePages
function commands.insert_pages( layoutxml,dataxml )
    local pagestore_name = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")
    local thispagestore = publisher.pagestore[pagestore_name]
    for i=1,#thispagestore do
        tex.box[666] = thispagestore[i]
        tex.shipout(666)
    end
    publisher.current_pagenumber = publisher.current_pagenumber + #thispagestore
end


--- Italic text (`<I>`)
--- -------------------
--- Set the contents of this element in italic text
function commands.italic( layoutxml,dataxml )
    trace("Italic")
    local a = paragraph:new()
    local objects = {}
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
            objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j),{italic = true})
        else
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    for _,j in ipairs(objects) do
        a:append(j,{fontfamily = 0, italic = 1})
    end
    return a
end

--- List item (`<Li>`)
--- ------------------
--- An entry of an ordered or unordered list.
function commands.li(layoutxml,dataxml )
    local objects = {}
    local a = paragraph:new()
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
            objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j))
        else
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    for _,j in ipairs(objects) do
        a:append(j,{})
    end
    return a
end


--- Load Fontfile
--- -------------
--- Load a given font file (`name`). Actually the font file is not loaded yet, only stored in a table. See `publisher.font#load_fontfile()`.
function commands.load_fontfile( layoutxml,dataxml )
    local marginprotrusion = publisher.read_attribute(layoutxml,dataxml,"marginprotrusion","number")
    local space            = publisher.read_attribute(layoutxml,dataxml,"space",           "number")
    local smcp             = publisher.read_attribute(layoutxml,dataxml,"smallcaps",       "string")
    local filename         = publisher.read_attribute(layoutxml,dataxml,"filename",        "rawstring")
    local name             = publisher.read_attribute(layoutxml,dataxml,"name",            "rawstring")
    local osf              = publisher.read_attribute(layoutxml,dataxml,"oldstylefigures", "boolean")

    local extra_parameter = {
        space            = space      or 25,
        marginprotrusion = marginprotrusion or 0,
        otfeatures    = {
            smcp = smcp == "yes",
            onum = osf == true,
        },
    }
    log("Load Fontfile %q",filename or "?")
    publisher.fonts.load_fontfile(name,filename,extra_parameter)
end

--- Load Dataset
--- ------------
--- Load a data file (XML) and start processing its contents by calling the `Record`
--- elements in the layout file.
function commands.load_dataset( layoutxml,dataxml )
    local name = publisher.read_attribute(layoutxml,dataxml,"name", "rawstring")
    assert(name)
    local filename = tex.jobname .. "-" .. name .. ".dataxml"

    local ok,_ = lfs.attributes(filename)
    if ok == nil then
        -- at the first run, the file does not exist. That's ok
        return
    end

    local tmp_data = publisher.load_xml(filename)
    local root_name = tmp_data[".__local_name"]

    log("Selecting node: %q, mode=%q",root_name,"")
    publisher.dispatch(publisher.data_dispatcher[""][root_name],tmp_data)
end


--- Loop
--- ----
--- Repeat the contents several times (given by the attribute select). If the attribute
--- `variable` is given, store the current loop value there, if not, it is stored
--- in the variable `_loopcounter`.
function commands.loop( layoutxml, dataxml )
    local num = tonumber(publisher.read_attribute(layoutxml,dataxml,"select","xpath"))
    if not num then
        err("loop: can't parse number given in the attribute select: %q",tostring(num))
        return
    end
    local var = publisher.read_attribute(layoutxml,dataxml,"variable","rawstring")
    var = var or "_loopcounter"
    local ret = {}
    local tab
    for i=1,num do
        publisher.xpath.set_variable(var,i)
        tab = publisher.dispatch(layoutxml,dataxml)
        for j=1,#tab do
            ret[#ret + 1] = tab[j]
        end
    end
    return ret
end

--- Empty line
--- ----------
--- Create an empty row in the layout. Set the cursor to the next free line and
--- let an empty row between.
function commands.emptyline( layoutxml,dataxml )
    trace("Emtpy row, current row is %d",publisher.current_grid:current_row())
    local areaname = publisher.read_attribute(layoutxml,dataxml,"area","rawstring")
    local areaname = areaname or publisher.default_areaname
    local current_grid = publisher.current_grid
    local current_row = current_grid:find_suitable_row(1,current_grid:number_of_columns(),1,areaname)
    if not current_row then
        current_grid:set_current_row(1)
    else
        current_grid:set_current_row(current_row + 1)
    end
    current_grid:set_current_column(1)
end

--- Makeindex
--- ---------
--- Generate an index from data
function commands.makeindex( layoutxml,dataxml )
    local xpath       = publisher.read_attribute(layoutxml,dataxml,"select",  "xpathraw")
    local sortkey     = publisher.read_attribute(layoutxml,dataxml,"sortkey", "rawstring")
    local sectionname = publisher.read_attribute(layoutxml,dataxml,"section", "rawstring")

    publisher.stable_sort(xpath,function(elta,eltb)
        return string.lower(elta[sortkey]) < string.lower(eltb[sortkey])
    end)

    local section, lastname, lastindex
    local lastfirstletter = ""
    local ret = {}
    for i=1,#xpath do
        local startletter = string.upper(string.sub(xpath[i][sortkey],1,1))

        if startletter ~= lastfirstletter then
            -- create a new section
            section = { [".__local_name"] = sectionname, name = startletter }
            ret[#ret + 1] = section
        end
        -- Add current entry to this section
        -- The current implementation only concatenates page numbers
        if xpath[i].name == lastname then
            xpath[lastindex].page = xpath[lastindex].page .. ", " .. xpath[i].page
        else
            lastindex = i
            lastname = xpath[i].name
            section[#section + 1] = xpath[i]
        end
        lastfirstletter = startletter
    end
    return ret
end


--- Margin
--- ------
--- Set margin for this page.
function commands.margin( layoutxml,dataxml )
    local left   = publisher.read_attribute(layoutxml,dataxml,"left", "length")
    local right  = publisher.read_attribute(layoutxml,dataxml,"right","length")
    local top    = publisher.read_attribute(layoutxml,dataxml,"top",  "length")
    local bottom = publisher.read_attribute(layoutxml,dataxml,"bottom", "length")

    return function(_seite) _seite.grid:set_margin(left,top,right,bottom) end
end

--- Mark
--- ----
--- Set an invisible marker into the output (whatsit/user_defined)
function commands.mark( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
    local append    = publisher.read_attribute(layoutxml,dataxml,"append","boolean")
    return { selection = selection, append = append }
end

--- Message
--- -------
--- Write a message to the terminal
function commands.message( layoutxml, dataxml )
    local contents
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")
    local errcond   = publisher.read_attribute(layoutxml,dataxml,"error", "boolean",false)

    if selection then
        local tmp = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
        local ret = {}
        if tmp then
            for i=1,#tmp do
                ret[#ret + 1] = tostring(tmp[i])
            end
            contents = table.concat(ret)
        else
            contents = nil
        end
    else
        local tab = publisher.dispatch(layoutxml,dataxml)
        contents = tab
    end
    if type(contents)=="table" then
        local ret
        for i=1,#contents do
            local eltname = publisher.elementname(contents[i],true)
            local contents = publisher.element_contents(contents[i])

            if eltname == "Sequence" or eltname == "Value" then
                if type(contents) == "table" then
                    ret = ret or {}
                    if getmetatable(ret) == nil then
                        setmetatable(ret,{ __concat = table.__concat })
                    end
                    ret = ret .. contents
                elseif type(contents) == "string" then
                    ret = ret or ""
                    ret = ret .. contents
                elseif type(contents) == "number" then
                    ret = ret or ""
                    ret = ret .. tostring(contents)
                elseif type(contents) == "nil" then
                    -- ignorieren
                else
                    err("Unknown type: %q",type(contents))
                    ret = nil
                end
            end
        end
        if ret then
            contents = ret
        end
    end
    if errcond then
        err("%q", tostring(contents) or "?")
    else
        log("Message: %q", tostring(contents) or "?")
    end
end

--- NextFrame
--- ---------
--- Switch to the next frame of the given positioning area.
function commands.next_frame( layoutxml,dataxml )
    local areaname = publisher.read_attribute(layoutxml,dataxml,"area","rawstring")
    publisher.next_area(areaname)
end

--- Next Row
--- --------
--- Go to the next row in the current area.
function commands.next_row( layoutxml,dataxml )
    publisher.setup_page()
    local rownumber = publisher.read_attribute(layoutxml,dataxml,"row", "rawstring")
    local areaname  = publisher.read_attribute(layoutxml,dataxml,"area","rawstring")
    local rows      = publisher.read_attribute(layoutxml,dataxml,"rows","rawstring")
    local tmp

    if rownumber ~= nil then
        tmp = tonumber(rownumber)
        if tmp == nil then
            err("Cannot parse row in NextRow, number expected, but got %q",tostring(rownumber))
            rownumber = nil
        else
            rownumber = tmp
        end
    end

    if rows ~= nil then
        tmp = tonumber(rows)
        if tmp == nil then
            err("Cannot parse rows in NextRow, number expected, but got %q",tostring(rows))
            rows = nil
        else
            rows = tmp
        end
    end

    rows = rows or 1
    local areaname = areaname or publisher.default_areaname

    publisher.next_row(rownumber,areaname,rows)
end

--- NewPage
--- -------
--- Create a new page. Run the hooks in AtPageShipout.
function commands.new_page( layoutxml,dataxml )
    local pagetype     = publisher.read_attribute(layoutxml,dataxml,"pagetype","rawstring")
    local skippagetype = publisher.read_attribute(layoutxml,dataxml,"skippagetype","rawstring")
    local openon   = publisher.read_attribute(layoutxml,dataxml,"openon","string")

    if openon == "right" and math.fmod(publisher.current_pagenumber,2) == 1 then
        publisher.new_page()
        publisher.nextpage = skippagetype
        publisher.new_page()
        publisher.nextpage = pagetype
    elseif openon == "left" and math.fmod(publisher.current_pagenumber,2) == 0 then
        publisher.new_page()
        publisher.nextpage = skippagetype
        publisher.new_page()
        publisher.nextpage = pagetype
    else
        publisher.nextpage = pagetype
        publisher.new_page()
    end

end

--- Ordered list (`<Ol>`)
--- ------------------
--- A list with numbers
function commands.ol(layoutxml,dataxml )
    local ret = {}
    local labelwidth = tex.sp("5mm")
    publisher.textformats.__fivemm = {indent = labelwidth, alignment="justified",   rows = -1}
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        local a = paragraph:new("__fivemm")
        a:append(publisher.number_hbox(i,labelwidth),{})
        a:append(publisher.element_contents(j),{})
        ret[#ret + 1] = a
    end
    return ret
end


--- Options
--- -------
--- This is a top-level element in the layout definition file. It saves the options such as `show-grid`.
function commands.options( layoutxml,dataxml )
    publisher.options.cutmarks           = publisher.read_attribute(layoutxml,dataxml,"cutmarks",    "boolean")
    publisher.options.showgrid           = publisher.read_attribute(layoutxml,dataxml,"show-grid",   "boolean")
    publisher.options.showgridallocation = publisher.read_attribute(layoutxml,dataxml,"show-gridallocation","boolean")
    publisher.options.showhyphenation    = publisher.read_attribute(layoutxml,dataxml,"show-hyphenation","boolean")
    publisher.options.startpage          = publisher.read_attribute(layoutxml,dataxml,"startpage",   "number")
    publisher.options.trace              = publisher.read_attribute(layoutxml,dataxml,"trace",       "boolean")
    publisher.options.trim               = publisher.read_attribute(layoutxml,dataxml,"trim",        "length")
    publisher.options.ignoreeol          = publisher.read_attribute(layoutxml,dataxml,"ignoreeol",   "boolean")
    publisher.options.resetmarks         = publisher.read_attribute(layoutxml,dataxml,"resetmarks",  "boolean",false)
    publisher.options.colorprofile       = publisher.read_attribute(layoutxml,dataxml,"colorprofile",  "rawstring")
    local mainlanguage                   = publisher.read_attribute(layoutxml,dataxml,"mainlanguage","string","")

    if mainlanguage ~= "" then
        publisher.set_mainlanguage(mainlanguage,true)
    end
    if publisher.options.trim then
        publisher.options.trim = tex.sp(publisher.options.trim)
    end
end

--- Output
--- ------
--- This command is able to produce multi-area contents by pulling from the underlying command.
--- That means the children (currently only `<Text>`) must implement a function called `pull()`
--- taking two arguments: 1) parameters, 2) state. Parameters is a table with the following layout:
---
---     parameters = {
---         area = area,
---         maxheight = maxht,
---         width = wd,
---         balance = true/false,
---         current_grid = current_grid,
---         allocate = allocate,
---     }
--- The state is just a table that is empty in the beginning and re-passed into `pull()`
--- every time there is output left over.
---
--- The function `pull()` must return three values:
---
---  1. `obj`: The vbox that should be placed in the pdf at the current position
---  1. `state`: The table that is passed to the next iteration of `pull()`
---  1. `more_to_follow`: boolean which indicates that there is output left for the next area
function commands.output( layoutxml,dataxml )
    publisher.setup_page()
    local area     = publisher.read_attribute(layoutxml,dataxml,"area","rawstring")
    local allocate = publisher.read_attribute(layoutxml,dataxml,"allocate", "string", "yes")
    local row      = publisher.read_attribute(layoutxml,dataxml,"row","number")
    local tab  = publisher.dispatch(layoutxml,dataxml)
    area = area or publisher.default_areaname
    local last_area = publisher.xpath.get_variable("__area")
    local state
    publisher.xpath.set_variable("__area",area)
    publisher.next_row(row,area,1)


    local current_maxwidth = xpath.get_variable("__maxwidth")
    xpath.set_variable("__maxwidth", publisher.current_grid:number_of_columns(area))

    for i=1,#tab do
        local contents = publisher.element_contents(tab[i])

        local parameters
        local more_to_follow
        local obj
        local maxht,row,nextfreerow
        local objcount = 0
        -- We call pull so long as it is needed. Say we have enough
        -- material for three pages (areas), we call pull three times.
        -- So pull()'s duty is to assemble enough material for that area.
        -- pull needs to know the width and the height of the area.
        --
        -- Currently only the command Text implements pull.
        while true do
            objcount = objcount + 1
            publisher.setup_page()
            maxht,row,nextfreerow = publisher.get_remaining_height(area,allocate)
            current_grid = publisher.current_grid
            current_row = publisher.current_grid:current_row(area)

            parameters = {
                area = area,
                maxheight = maxht,
                width = current_grid:number_of_columns(area) * current_grid.gridwidth,
                balance = contents.balance,
                current_grid = current_grid,
                allocate = allocate,
            }
            obj,state,more_to_follow = contents.pull(parameters,state)
            if obj == nil then
                break
            else
                publisher.output_at({nodelist = obj, x = 1, y = row, allocate = true, area = area})
                -- We don't need to go to the next page when we are a the end
                if nextfreerow then
                    if nextfreerow <= row then
                        nextfreerow = row + 1
                    end
                    publisher.next_row(nextfreerow,area,0)
                else
                    if more_to_follow then
                        publisher.next_area(area)
                    end
                end
            end
        end
    end
    -- reset the current maxwidth
    xpath.set_variable("__maxwidth",current_maxwidth)
    _,row,_ = publisher.get_remaining_height(area,allocate)
    current_grid:set_current_row(row,area)
    publisher.xpath.set_variable("__area",last_area)
end


--- PageFormat
--- ----------
--- Set the dimensions of the page
function commands.page_format(layoutxml)
    trace("Pageformat")
    local width  = publisher.read_attribute(layoutxml,dataxml,"width","length")
    local height = publisher.read_attribute(layoutxml,dataxml,"height","length")
    publisher.set_pageformat(tex.sp(width),tex.sp(height))
end

--- PageType
--- --------
--- This command should be probably called Masterpage or something similar.
function commands.pagetype(layoutxml,dataxml)
    trace("Command: Pagetype")
    local tmp_tab = {}
    local test         = publisher.read_attribute(layoutxml,dataxml,"test","rawstring")
    local pagetypename = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")
    local tab = publisher.dispatch(layoutxml,dataxml)

    for i,j in ipairs(tab) do
        local eltname = publisher.elementname(j,true)
        if eltname=="Margin" or eltname == "AtPageShipout" or eltname == "AtPageCreation" or eltname=="Grid" or eltname=="PositioningArea" then
            tmp_tab [#tmp_tab + 1] = j
        else
            err("Element %q in »Pagetype« unknown",tostring(eltname))
            tmp_tab [#tmp_tab + 1] = j
        end
    end
    -- assert(type(test())=="boolean")
    publisher.masterpages[#publisher.masterpages + 1] = { is_pagetype = test, res = tmp_tab, name = pagetypename,ns=layoutxml[".__ns"] }
end

--- Paragraph
--- ---------
--- A paragraph is just a bunch of text that is not yet typeset.
--- It can have a font face, color,... but these can be also given
--- On the surrounding element (`Textblock`).
function commands.paragraph( layoutxml,dataxml )
    trace("Paragraph")
    local class = publisher.read_attribute(layoutxml,dataxml,"class","rawstring")
    local id    = publisher.read_attribute(layoutxml,dataxml,"id",   "rawstring")

    local css_rules = publisher.css:matches({element = 'paragraph', class=class,id=id}) or {}

    local textformat    = publisher.read_attribute(layoutxml,dataxml,"textformat","rawstring")
    local allowbreak    = publisher.read_attribute(layoutxml,dataxml,"allowbreak","rawstring")
    local fontname      = publisher.read_attribute(layoutxml,dataxml,"fontface",  "rawstring")
    local colorname     = publisher.read_attribute(layoutxml,dataxml,"color",     "rawstring")
    local language_name = publisher.read_attribute(layoutxml,dataxml,"language",  "string")

    colorname = colorname or css_rules["color"]
    fontname  = fontname  or css_rules["fontface"]
    local fontfamily
    if fontname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
        if fontfamily == nil then
            err("Fontfamily %q not found.",fontname)
            fontfamily = 0
        end
    else
        fontfamily = 0
    end

    local languagecode

    if language_name then
        languagecode = publisher.get_languagecode(language_name)
    else
        languagecode = publisher.defaultlanguage
    end

    local colortable
    if colorname then
        if not publisher.colors[colorname] then
            err("Color %q is not defined yet.",colorname)
        else
            colortable = publisher.colors[colorname].index
        end
    end


    local a = paragraph:new(textformat)
    local objects = {}
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        trace("Paragraph Elementname = %q",tostring(publisher.elementname(j,true)))
        local contents = publisher.element_contents(j)
        if publisher.elementname(j,true) == "Value" and type(contents) == "table" and #contents == 1 and type(contents[1]) == "string"  then
            objects[#objects + 1] = contents[1]
        elseif publisher.elementname(j,true) == "Value" and type(contents) == "table" then
            objects[#objects + 1] = publisher.parse_html(contents,{allowbreak = allowbreak})
        else
            objects[#objects + 1] = contents
        end
    end
    for _,j in ipairs(objects) do
        a:append(j,{fontfamily = fontfamily, languagecode = languagecode, allowbreak = allowbreak})
    end
    if #objects == 0 then
        -- nothing got through, why?? check
        warning("No contents found in paragraph.")
        a:append("",{fontfamily = fontfamily,languagecode = languagecode})
    end

    a:set_color(colortable)
    return a
end


--- PlaceObject
--- -----------
--- Emit a rectangular object. The object can be
--- one of `Textblock`, `Table`, `Image`, `Box` or `Rule`.
function commands.place_object( layoutxml,dataxml )
    trace("Command: PlaceObject")
    local absolute_positioning = false
    local column           = publisher.read_attribute(layoutxml,dataxml,"column",         "rawstring")
    local row              = publisher.read_attribute(layoutxml,dataxml,"row",            "rawstring")
    local area             = publisher.read_attribute(layoutxml,dataxml,"area",           "rawstring")
    local allocate         = publisher.read_attribute(layoutxml,dataxml,"allocate",       "string", "yes")
    local framecolor       = publisher.read_attribute(layoutxml,dataxml,"framecolor",     "rawstring")
    local backgroundcolor  = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","rawstring")
    local rulewidth_sp     = publisher.read_attribute(layoutxml,dataxml,"rulewidth",      "length_sp")
    local maxheight        = publisher.read_attribute(layoutxml,dataxml,"maxheight",      "number")
    local onpage           = publisher.read_attribute(layoutxml,dataxml,"page",           "rawstring")
    local keepposition     = publisher.read_attribute(layoutxml,dataxml,"keepposition",   "boolean",false)
    local frame            = publisher.read_attribute(layoutxml,dataxml,"frame",          "string")
    local background       = publisher.read_attribute(layoutxml,dataxml,"background",     "string")
    local groupname        = publisher.read_attribute(layoutxml,dataxml,"groupname",      "rawstring")
    local valign           = publisher.read_attribute(layoutxml,dataxml,"valign",         "string")
    local hreference       = publisher.read_attribute(layoutxml,dataxml,"hreference",     "string")
    local vreference       = publisher.read_attribute(layoutxml,dataxml,"vreference",     "string")

    if publisher.current_group and area then
        err("Areas can't be combined with groups")
    end
    area = area or publisher.default_areaname
    framecolor = framecolor or "black"

    if column and not tonumber(column) then
        -- looks like column is a string
        absolute_positioning = true
        column = tex.sp(column)
    end
    if row then
        local tmp = tonumber(row)
        if not tmp then
            -- looks row is a string
            absolute_positioning = true
            row = tex.sp(row)
        else
            row = tmp
        end
    end

    if absolute_positioning then
        if not ( row and column ) then
            err("»Column« and »Row« must be given with absolute positioning (PlaceObject).")
            return
        end
    end

    if onpage then
        if onpage == 'next' then
            onpage = publisher.current_pagenumber + 1
        elseif tonumber(onpage) then
            onpage = tonumber(onpage)
        end
    end

    publisher.setup_page(onpage)

    local cg = publisher.current_grid
    if onpage then
        current_grid = publisher.pages[onpage].grid
    else
        current_grid = publisher.current_grid
    end



    -- remember the current maximum width for later
    local current_maxwidth = xpath.get_variable("__maxwidth")
    local mw = current_grid:number_of_columns(area)
    if absolute_positioning == false and tonumber(column) then
        mw = mw - column + 1
    end
    xpath.set_variable("__maxwidth", mw)

    trace("Column = %q",tostring(column))
    trace("Row = %q",tostring(row))

    local current_row_start  = current_grid:current_row(area)
    if not current_row_start then
        return nil
    end
    local current_column_start = column or current_grid:current_column(area)

    -- current_height is the remaining space on the current page in sp
    local areaheight = ( maxheight or current_grid:number_of_rows(area) ) * current_grid.gridheight
    local optionen = {
        current_height = math.min(current_grid:remaining_height_sp(row,area),areaheight),
        ht_max     = areaheight,
    }
    if allocate == "no" then
        optionen.current_height = areaheight
    end

    local grid   = current_grid
    local tab    = publisher.dispatch(layoutxml,dataxml,optionen)

    -- reset the current maxwidth
    xpath.set_variable("__maxwidth",current_maxwidth)
    local objects = {}
    local object, objecttype

    if groupname then
        if not publisher.groups[groupname] then
            err("Unknown group %q in PlaceObject",groupname)
        else
            objects[1] = { object = node.copy(publisher.groups[groupname].contents),
                objecttype = string.format("Gruppe (%s)", groupname)}
        end
    else
        for i,j in ipairs(tab) do
            object = publisher.element_contents(j)
            objecttype = publisher.elementname(j,true)
            if objecttype == "Image" then
                -- return value is a table, #1 is the image, #2 is the allocation grid
                objects[#objects + 1] = {object = object[1], objecttype = objecttype, allocate_matrix = object[2] }
            else
                if type(object)=="table" then
                    for i=1,#object do
                        objects[#objects + 1] = {object = object[i], objecttype = objecttype }
                    end
                else
                    objects[#objects + 1] = {object = object, objecttype = objecttype }
                end
            end
        end
    end
    for i=1,#objects do
        object     = objects[i].object
        objecttype = objects[i].objecttype

        if background  == "full" then
            object = publisher.background(object,backgroundcolor)
        end
        if frame  == "solid" then
            object = publisher.frame(object,framecolor,rulewidth_sp)
        end
        if not object then
            err("Something is wrong with <PlaceObject>, content is missing")
            return
        end
        if publisher.options.trace then
            publisher.boxit(object)
        end

        local width_in_gridcells   = current_grid:width_in_gridcells_sp(object.width)
        local height_in_gridcells  = current_grid:height_in_gridcells_sp (object.height + object.depth)


        if absolute_positioning then
            if hreference == "right" then
                column = column - width_in_gridcells + 1
            end
            local top = row + current_grid.extra_margin
            if vreference == "bottom" then
                top = top - object.height
            end
            publisher.output_absolute_position(object,column + current_grid.extra_margin,top,allocate,objects[i].allocate_matrix)
        else
            -- Look for a place for the object
            -- local current_row = current_grid:current_row(area)
            trace("PlaceObject: calculate object width")
            if not node.has_field(object,"width") then
                warning("Can't calculate with object's width!")
            end
            trace("PlaceObject: finished calculating width: wd=%d,ht=%d",width_in_gridcells,height_in_gridcells)

            trace("PlaceObject: find suitable row for object, current_row = %d",row or current_grid:current_row(area) or "-1")
            if row then
                if vreference == "bottom" then
                    current_row = row - height_in_gridcells + 1
                else
                    current_row = row
                end
            else
                current_row = nil
            end

            -- While (not found a free area) switch to next frame
            while current_row == nil do
                if not column then
                    -- no row or column given. So I'll look for the values myself:
                    if current_column_start + width_in_gridcells - 1 > current_grid:number_of_columns() then
                        current_column_start = 1
                    end
                end
                -- This is not correct! Todo: fixme!
                if publisher.current_group then
                    current_row = 1
                else
                    -- the current grid is different when in a group
                    current_row = current_grid:find_suitable_row(current_column_start,width_in_gridcells,height_in_gridcells,area)
                    if not current_row then
                        warning("No suitable row found for object")
                        publisher.next_area(area)
                        publisher.setup_page()
                        current_grid = publisher.current_grid
                        current_row = current_grid:current_row(area)
                    end
                end
            end

            log("PlaceObject: %s in row %d and column %d, width=%d, height=%d (page %d)", objecttype, current_row, current_column_start,width_in_gridcells,height_in_gridcells,onpage or publisher.current_pagenumber)
            trace("PlaceObject: object placed at (%d,%d)",current_column_start,current_row)
            if hreference == "right" then
                current_column_start = current_column_start - width_in_gridcells + 1
            end
            publisher.output_at({ ["nodelist"] = object, x = current_column_start, y = current_row, allocate = ( allocate == "yes"), area = area, valign = valign, allocate_matrix = objects[i].allocate_matrix, pagenumber = onpage, keepposition = keepposition, grid = current_grid})
            trace("object placed")
            row = nil -- the current rows is not valid anymore because an object is already rendered
        end -- no absolute positioning
    end
    if not allocate == "yes" then
        current_grid:set_current_row(current_row_start)
    end

    if onpage then
        publisher.setup_page()
        current_grid = publisher.pages[publisher.current_pagenumber].grid
    end
    trace("objects placed")
end

--- ProcessRecord
--- -------------
--- This command takes the contents from the given attribute `select` (an
--- XPath- expression) and process this. If you feed garbage in, well,
--- probably nothing useful comes out. (This should be the only command to
--- process data, but at the moment there is the _static_ ProcessNode).
function commands.process_record( layoutxml,dataxml )
    -- FIXME: remove this, not needed anymore
    trace("ProcessRecord")
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")
    local limit     = publisher.read_attribute(layoutxml,dataxml,"limit","number")

    local record = xpath.parse(dataxml,selection,layoutxml[".__ns"])
    local layoutknoten

    if limit then
        limit = math.min(#record,limit)
    else
        if record then
            limit = #record or 0
        else
            limit = 0
        end
    end

    for i=1,limit do
        local eltname = dataxml[i]["inhalt"][".__local_name"]
        layoutknoten=publisher.data_dispatcher[""][eltname]
        log("Selecting node: %q",eltname or "???")
        publisher.xpath.set_variable("__position",i)
        publisher.dispatch(layoutknoten,publisher.element_contents(dataxml[i]))
    end
end

--- ProcessNode
--- -----------
--- Call the given (in attribute `select`) names of elements in the data file.
--- The optional attribute `mode` must match, if given. Since the attribute `select` is a fixed
--- string, this function is rather stupid but nevertheless currently the main
--- function for processing data.
function commands.process_node(layoutxml,dataxml)
    trace("process_node")
    local dataxml_selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    local mode              = publisher.read_attribute(layoutxml,dataxml,"mode","rawstring") or ""
    -- To restore the current value of `__position`, we save it.
    -- The value of `__position` is available from xpath (function position()).
    local current_position = publisher.xpath.get_variable("__position")
    local element_name
    local layoutnode
    local pos = 1
    if not dataxml_selection then return nil end
    for i=1,#dataxml_selection do
        element_name = dataxml_selection[i][".__local_name"]
        layoutnode = publisher.data_dispatcher[mode][element_name]
        if layoutnode then
            log("Selecting node: %q, mode=%q, pos=%d",element_name,mode,pos)
            publisher.xpath.set_variable("__position",pos)
            dataxml_selection[i][".__context"] = dataxml_selection
            publisher.dispatch(layoutnode,dataxml_selection[i])
            pos = pos + 1
        end
    end

    --- Now restore the value for the parent element
    publisher.xpath.set_variable("__position",current_position)
end


--- PositioningFrame
--- ----------------
--- Define a rectangular area on the page where content gets placed.
function commands.positioning_frame( layoutxml, dataxml )
    local column = publisher.read_attribute(layoutxml,dataxml,"column","number")
    local row    = publisher.read_attribute(layoutxml,dataxml,"row" ,"number")
    local width  = publisher.read_attribute(layoutxml,dataxml,"width","number")
    local height = publisher.read_attribute(layoutxml,dataxml,"height"  ,"number")
    return {
        column = column,
        row    = row,
        width  = width,
        height = height
    }
end

--- PositioningArea
--- ----------------
--- Contains one or more positioning frames.
function commands.positioning_area( layoutxml,dataxml )
    -- Warning: if we call publisher.dispatch now, the xpath functions
    -- might depend on values on the _current_ page, which is not set!
    local tab = {}
    tab.layoutxml = layoutxml
    local name = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")
    tab.name = name
    return tab
end


--- Record
--- ------
--- Matches an element name of the data file. To be called from ProcessNodes
function commands.record( layoutxml )
    local elementname = publisher.read_attribute(layoutxml,dataxml,"element","rawstring")
    local mode        = publisher.read_attribute(layoutxml,dataxml,"mode","rawstring")

    mode = mode or ""
    publisher.data_dispatcher[mode] = publisher.data_dispatcher[mode] or {}
    publisher.data_dispatcher[mode][elementname] = layoutxml
end


--- Rule
--- -----
--- Draw a horizontal or vertical rule
function commands.rule( layoutxml,dataxml )
    local direction     = publisher.read_attribute(layoutxml,dataxml,"direction",  "string")
    local length        = publisher.read_attribute(layoutxml,dataxml,"length",     "rawstring")
    local rulewidth     = publisher.read_attribute(layoutxml,dataxml,"rulewidth",  "rawstring")
    local color         = publisher.read_attribute(layoutxml,dataxml,"color",      "rawstring")

    local colorname = color or "black"

    if tonumber(length) then
        if direction == "horizontal" then
            length = publisher.current_grid.gridwidth * length
        elseif direction == "vertical" then
            length = publisher.current_grid.gridheight * length
        else
            err("Attribute »direction« with »Linie«: unknown direction: %q",direction)
        end
    else
        length = tex.sp(length)
    end
    length = sp_to_bp(length)

    rulewidth = rulewidth or "1pt"
    if tonumber(rulewidth) then
        if direction == "horizontal" then
            rulewidth = publisher.current_grid.gridwidth * rulewidth
        elseif direction == "vertical" or direction == "vertikal" then
            rulewidth = publisher.current_grid.gridheight * rulewidth
        end
    else
        rulewidth = tex.sp(rulewidth)
    end
    rulewidth = sp_to_bp(rulewidth)


    local n = node.new("whatsit","pdf_literal")
    n.mode = 0
    if direction == "horizontal" then
        n.data = string.format("q %d w %s 0 0 m %g 0 l S Q",rulewidth,publisher.colors[colorname].pdfstring,length)
    elseif direction == "vertical" then
        n.data = string.format("q %d w %s 0 0 m 0 %g l S Q",rulewidth,publisher.colors[colorname].pdfstring,-length)
    else
        --
    end
    n = node.hpack(n)
    return n
end

--- SaveDataset
--- -----------
--- Write a Lua table representing an XML file to the disk. See `#load_dataset` for the opposite.
function commands.save_dataset( layoutxml,dataxml )
    local towrite, tmp,tab
    local filename    = publisher.read_attribute(layoutxml,dataxml,"filename",  "rawstring")
    local elementname = publisher.read_attribute(layoutxml,dataxml,"elementname","rawstring")
    local selection   = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")
    local attributes  = publisher.read_attribute(layoutxml,dataxml,"attributes","xpathraw")

    assert(filename)
    assert(elementname)

    tmp = {}
    if attributes then
        for i=1,#attributes do
            if publisher.elementname(attributes[i],true) == "Attribute" then
                for k,v in pairs(publisher.element_contents(attributes[i])) do
                    if k ~= ".__type" then
                        tmp[k] = v
                    end
                end
            end
        end
    end

    if selection then
        local ok
        ok, tab = xpath.parse_raw(dataxml,selection,layoutxml[".__ns"])
        if not ok then err(tab) return end
    else
        tab = publisher.dispatch(layoutxml,dataxml)
    end

    for i=1,#tab do
        if tab[i].elementname=="Element" then
            tmp[#tmp + 1] = publisher.element_contents(tab[i])
        elseif tab[i].elementname=="SortiereSequenz" or tab[i].elementname=="Sequenz" or tab[i].elementname=="elementstructure" or tab[i].elementname=="Makeindex" then
            for j=1,#publisher.element_contents(tab[i]) do
                tmp[#tmp + 1] = publisher.element_contents(tab[i])[j]
            end
        else
            tmp[#tmp + 1] = tab[i]
        end
    end

    --- tmp has now this structure:
    ---    tmp = {
    ---      [1] = {
    ---        [".__parent"] =
    ---        [".__local_name"] = "bar"
    ---        ["att1"] = "1"
    ---      },
    ---      [2] = {
    ---        [".__parent"] =
    ---        [".__local_name"] = "bar"
    ---        ["att2"] = "2"
    ---      },
    ---      [3] = {
    ---        [".__parent"] =
    ---        [".__local_name"] = "bar"
    ---        ["att3"] = "3"
    ---      },
    ---    },
    tmp[".__local_name"] = elementname
    local full_filename = tex.jobname .. "-" .. filename .. ".dataxml"
    local file = io.open(full_filename,"wb")
    towrite = publisher.xml_to_string(tmp)
    file:write(towrite)
    file:close()
end

--- SavePages
--- ---------
--- Save pages for later restore
function commands.save_pages( layoutxml,dataxml )
    thispage = publisher.current_pagenumber
    local pagestore_name = publisher.read_attribute(layoutxml,dataxml,"name","rawstring")
    publisher.current_pagestore_name = pagestore_name
    publisher.pagestore[pagestore_name] = {}
    local tab = publisher.dispatch(layoutxml,dataxml)
    publisher.new_page()
    for i=thispage,publisher.current_pagenumber - 1 do
        publisher.pages[i] = nil
    end
    publisher.current_pagestore_name = nil
    publisher.current_pagenumber = thispage
    return tab
end

--- SetGrid
--- -------
--- Set the grid to the given values.
function commands.set_grid(layoutxml)
    trace("Command: SetGrid")
    local wd = publisher.read_attribute(layoutxml,dataxml,"width", "rawstring")
    local ht = publisher.read_attribute(layoutxml,dataxml,"height","rawstring")
    local nx = publisher.read_attribute(layoutxml,dataxml,"nx",    "rawstring")
    local ny = publisher.read_attribute(layoutxml,dataxml,"ny",    "rawstring")

    local _nx = tonumber(nx)
    local _ny = tonumber(ny)
    if _nx then
        publisher.options.gridcells_x = _nx
        publisher.options.gridwidth = 0
    else
        if tonumber(wd) then
            err("SetGrid: width must be a length (with unit). Setting it to 1cm.")
            wd = "1cm"
        end
        if wd == nil then
            err("Gridwidth not set")
        else
            publisher.options.gridwidth = tex.sp(wd)
        end
    end
    if _ny then
        publisher.options.gridcells_y = _ny
        publisher.options.gridheight = 0
    else
        if tonumber(ht) then
            err("SetGrid: height must be a length (with unit). Setting it to 1cm.")
            ht = "1cm"
        end
        publisher.options.gridheight  = tex.sp(ht)
    end
end


--- Sequence
--- --------
--- Get parts of the data. Can be stored in a variable.
function commands.sequence( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    return selection
end

--- SetVariable
--- -----------
--- Assign a value to a variable.
function commands.setvariable( layoutxml,dataxml )
    local trace_p = publisher.read_attribute(layoutxml,dataxml,"trace","boolean")
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")

    -- FIXME: wenn in der Variablen schon nodelisten sind, dann müssen diese gefreed werden!
    local varname = publisher.read_attribute(layoutxml,dataxml,"variable","rawstring")

    trace("SetVariable, Variable = %q",varname or "???")
    if not varname then
        err("Variable name in »SetVariable« not recognized")
        return
    end
    local contents

    if selection then
        contents = xpath.parse(dataxml,selection,layoutxml[".__ns"])
    else
        local tab = publisher.dispatch(layoutxml,dataxml)
        contents = tab
    end

    if type(contents)=="table" then
        local ret
        for i=1,#contents do
            local eltname = publisher.elementname(contents[i],true)
            local element_contents = publisher.element_contents(contents[i])
            if eltname == "Sequence" or eltname == "Value" or eltname == "SortSequence" then
                if type(element_contents) == "table" then
                    ret = ret or {}
                    if getmetatable(ret) == nil then
                        setmetatable(ret,{ __concat = table.__concat })
                    end
                    ret = ret .. element_contents
                elseif type(element_contents) == "string" then
                    ret = ret or ""
                    ret = ret .. element_contents
                elseif type(element_contents) == "number" then
                    ret = ret or ""
                    ret = ret .. tostring(element_contents)
                elseif type(element_contents) == "nil" then
                    -- ignorieren
                else
                    err("Unknown type: %q",type(element_contents))
                    ret = nil
                end
            elseif eltname == "elementstructure" then
                for j=1,#element_contents do
                    ret = ret or {}
                    ret[#ret + 1] = element_contents[j]
                end
            elseif eltname == "Element" then
                ret = ret or {}
                ret[#ret + 1] = element_contents
            end
        end
        if ret then
            contents = ret
        end
    end
    if trace_p then
        log("SetVariable, variable name = %q, value = %q",varname or "???", tostring(contents))
        printtable("SetVariable",contents)
    end
    publisher.xpath.set_variable(varname,contents)
end

--- SortSequence
--- ------------
--- Sort a sequence. Warning: it changes the order in the variable.
function commands.sort_sequence( layoutxml,dataxml )
    local selection        = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")
    local removeduplicates = publisher.read_attribute(layoutxml,dataxml,"removeduplicates","rawstring")
    local criterium        = publisher.read_attribute(layoutxml,dataxml,"criterium","rawstring")

    local sequence = xpath.parse(dataxml,selection,layoutxml[".__ns"])
    trace("SortSequence: Record = %q, criterium = %q",selection,criterium or "???")
    local sortkey = criterium
    local tmp = {}
    if #sequence == 0 then
        tmp[1] = sequence
    else
        for i,v in ipairs(sequence) do
            tmp[i] = sequence[i]
        end
    end

    table.sort(tmp, function(a,b) return a[sortkey]  < b[sortkey] end)

    if removeduplicates then
        local ret = {}
        local deleteme = {}
        local last_entry = {}
        for i,v in ipairs(tmp) do
            if v[removeduplicates] == last_entry[removeduplicates] then
                deleteme[#deleteme + 1] = i
            end
            last_entry = v
        end

        for i=#deleteme,1,-1 do
            -- backwards, otherwise the indexes would be mangled
            table.remove(tmp,deleteme[i])
        end
    end
    return tmp
end

--- Stylesheet
--- ----------
--- Load a CSS file
function commands.stylesheet( layoutxml,dataxml )
    local filename = publisher.read_attribute(layoutxml,dataxml,"filename","rawstring")
    if not filename then
        warning("CSS: no filename given")
        return
    end
    publisher.css:parse(filename)
end

--- Sub
--- ---
--- Subscript. The contents of this element should be written in subscript (smaller, lower)
function commands.sub( layoutxml,dataxml )
    local a = paragraph:new()
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        a:script(publisher.element_contents(j),1,{fontfamily = 0})
    end
    return a
end

--- Sup
--- ---
--- Superscript. The contents of this element should be written in superscript (smaller, higher)
function commands.sup( layoutxml,dataxml )
    local a = paragraph:new()
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        a:script(publisher.element_contents(j),2,{fontfamily = 0})
    end
    return a
end

--- Switch
--- ------
--- A case / switch instruction. Can be used on any level.
function commands.switch( layoutxml,dataxml )
    local case_matched = false
    local otherwise,ret,elementname
    for _,case_or_otherwise_element in ipairs(layoutxml) do
        elementname = publisher.translate_element(case_or_otherwise_element[".__local_name"])
        if type(case_or_otherwise_element)=="table" and elementname=="Case" and case_matched ~= true then
            local test = publisher.read_attribute(case_or_otherwise_element,dataxml,"test","rawstring")
            local ok, tab = xpath.parse_raw(dataxml,test,layoutxml[".__ns"])
            if not ok then
                err(tab)
            elseif tab[1] then
                case_matched = true
                ret = publisher.dispatch(case_or_otherwise_element,dataxml)
            end
        elseif type(case_or_otherwise_element)=="table" and elementname=="Otherwise" then
            otherwise = case_or_otherwise_element
        end -- case/otherwise
    end
    if otherwise and case_matched==false then
        ret = publisher.dispatch(otherwise,dataxml)
    end
    if not ret then return {} end
    return ret
end


--- Table
--- -----
--- Typesets tabular material. Mostly like an HTML table.
function commands.table( layoutxml,dataxml,optionen )
    local width          = publisher.read_attribute(layoutxml,dataxml,"width",         "length")
    local padding        = publisher.read_attribute(layoutxml,dataxml,"padding",       "length")
    local columndistance = publisher.read_attribute(layoutxml,dataxml,"columndistance","length")
    local rowdistance    = publisher.read_attribute(layoutxml,dataxml,"leading",       "length")
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface",      "rawstring")
    local autostretch    = publisher.read_attribute(layoutxml,dataxml,"stretch",       "string")
    local eval           = publisher.read_attribute(layoutxml,dataxml,"eval",          "xpath")
    local collapse       = publisher.read_attribute(layoutxml,dataxml,"border-collapse",  "string", "separate")

    -- FIXME: leading -> rowdistance or so
    padding        = tex.sp(padding        or "0pt")
    columndistance = tex.sp(columndistance or "0pt")
    rowdistance    = tex.sp(rowdistance    or "0pt")
    publisher.setup_page()

    if width == nil then
        if xpath.get_variable("__maxwidth") == nil then
            err("Can't determine the current width. Tables in groups and data cells must contain explicit widths.")
            width = 50 * 2^16
        else
            width = xpath.get_variable("__maxwidth") * publisher.current_grid.gridwidth
        end
    else
        if tonumber(width) ~= nil then
            width  = publisher.current_grid.gridwidth  * width
        else
            width = tex.sp(width)
        end
    end

    if not width then
        err("Can't get the width of the table!")
        rule = publisher.add_rule(nil,"head",{height=100*2^16,width=100*2^16})
        local v = node.vpack(rule)
        return v
    end

    if not fontname then fontname = "text" end
    fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]

    if fontfamily == nil then
        err("Fontfamily %q not found.",fontname or "???")
        fontfamily = 1
    end
    local tab = {}
    local tab_tmp = publisher.dispatch(layoutxml,dataxml)
    for i=1,#tab_tmp do
        local eltname = publisher.elementname(tab_tmp[i],true)
        if eltname == "Tr" or eltname == "Columns" or eltname == "Tablehead" or eltname == "Tablefoot" or eltname == "Tablerule" then
            tab[#tab + 1] = tab_tmp[i]
        else
            if eltname and eltname ~= "elementstructure" then
                warning("Ignore %q in table",eltname)
            end
        end
    end

    local tabular = publisher.tabular:new()

    tabular.tab = tab
    tabular.optionen       = optionen or { ht_max=99999*2^16 } -- FIXME! Test - this is for tabular in tabular
    tabular.layoutxml      = layoutxml
    tabular.dataxml        = dataxml
    tabular.width          = width
    tabular.fontfamily     = fontfamily
    tabular.padding_left   = padding
    tabular.padding_top    = padding
    tabular.padding_right  = padding
    tabular.padding_bottom = padding
    tabular.colsep         = columndistance
    tabular.rowsep         = rowdistance
    tabular.autostretch    = autostretch
    tabular.bordercollapse_horizontal = collapse == "collapse"
    tabular.bordercollapse_vertical   = collapse == "collapse"
    if columndistance > 0 then tabular.bordercollapse_horizontal = false end
    if rowdistance    > 0 then tabular.bordercollapse_vertical   = false end

    xpath.set_variable("_last_tr_data","")

    local n = tabular:make_table()
    -- Helpful for debugging purpose:
    -- for i=1,#n do
    --     node.set_attribute(n[i],publisher.att_origin,publisher.origin_table)
    -- end
    trace("Done with table()")
    return n
end

--- Tablefoot
--- ---------
--- The foot gets repeated on every page.
function commands.tablefoot( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local attribute = {
        ["page"]           = "string",
    }

    for attname,atttyp in pairs(attribute) do
        tab[attname] = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
    end
    tab._layoutxml = layoutxml
    tab._dataxml = dataxml
    return tab
end

--- Tablehead
--- ---------
--- The foot gets repeated on every page.
function commands.tablehead( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local page = publisher.read_attribute(layoutxml,dataxml,"page","string","all")
    tab.page = page
    tab._layoutxml = layoutxml
    tab._dataxml = dataxml
    return tab
end

--- Tablerule
--- ---------
--- A horizontal rule that is placed between two rows.
function commands.tablerule( layoutxml,dataxml )
    local rulewidth = publisher.read_attribute(layoutxml,dataxml,"rulewidth","length")
    local color     = publisher.read_attribute(layoutxml,dataxml,"color","rawstring")
    local start     = publisher.read_attribute(layoutxml,dataxml,"start","number")
    return { rulewidth = rulewidth, farbe = color, start = start }
end

--- Tr
--- ----
--- A table row. Consists of several Td's
function commands.tr( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)

    local attribute = {
        ["data"]            = "xpath",
        ["valign"]          = "string",
        ["backgroundcolor"] = "rawstring",
        ["minheight"]       = "number",
        ["top-distance"]    = "rawstring",
        ["break-below"]     = "string",
        ["sethead"]         = "boolean",
    }

    for attname,atttyp in pairs(attribute) do
        tab[attname] = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
    end

    tab.align = publisher.read_attribute(layoutxml,dataxml,"align","string",nil,"align")
    -- Remove this err in 2014
    if layoutxml.align == "links" or layoutxml.align == "rechts" then
        err("Tr, attribute align. Values 'links' and 'rechts' should be 'left' and 'right'")
    end

    if tab["top-distance"] then
        if tonumber(tab["top-distance"]) then
            tab["top-distance"] = publisher.current_grid.gridheight * tab["top-distance"]
        else
            tab["top-distance"] = tex.sp(tab["top-distance"])
        end
    end

    return tab
end

--- Td
--- -----
--- A table cell. Can have anything in it that is a horizontal box.
function commands.td( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)

    local class = publisher.read_attribute(layoutxml,dataxml,"class","rawstring")
    local id    = publisher.read_attribute(layoutxml,dataxml,"id",   "rawstring")

    local css_rules = publisher.css:matches({element = "td", class=class,id=id})

    if css_rules and type(css_rules) == "table" then
        for k,v in pairs(css_rules) do
            tab[k] = v
        end
    end

    local attribute = {
        ["colspan"]          = "number",
        ["rowspan"]          = "number",
        ["padding"]          = "length",
        ["padding-top"]      = "length",
        ["padding-right"]    = "length",
        ["padding-bottom"]   = "length",
        ["padding-left"]     = "length",
        ["backgroundcolor"]  = "rawstring",
        ["valign"]           = "string",
        ["border-left"]      = "length",
        ["border-right"]     = "length",
        ["border-top"]       = "length",
        ["border-bottom"]    = "length",
        ["border-left-color"]      = "rawstring",
        ["border-right-color"]     = "rawstring",
        ["border-top-color"]       = "rawstring",
        ["border-bottom-color"]    = "rawstring",
    }

    local tmpattr
    for attname,atttyp in pairs(attribute) do
        tmpattr = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
        if tmpattr then
            tab[attname] = tmpattr
        end
    end

    tab.align = publisher.read_attribute(layoutxml,dataxml,"align","string",nil,"align")

    if tab.padding then
        tab.padding_left   = tex.sp(tab.padding)
        tab.padding_right  = tex.sp(tab.padding)
        tab.padding_top    = tex.sp(tab.padding)
        tab.padding_bottom = tex.sp(tab.padding)
    end
    if tab["padding-top"]    then tab.padding_top    = tex.sp(tab["padding-top"])    end
    if tab["padding-bottom"] then tab.padding_bottom = tex.sp(tab["padding-bottom"]) end
    if tab["padding-left"]   then tab.padding_left   = tex.sp(tab["padding-left"])   end
    if tab["padding-right"]  then tab.padding_right  = tex.sp(tab["padding-right"])  end
    return tab
end

--- Text
--- ----
--- Text is currently the only function / command that implements the pull-interface defined by output.
function commands.text(layoutxml,dataxml)
    -- balance is currently not supported
    -- local balance = publisher.read_attribute(layoutxml,dataxml,"balance",   "rawstring")
    local tab = publisher.dispatch(layoutxml,dataxml)

    tab.balance = balance
    -- pull returns 'obj', 'state', 'more_to_follow'

    -- pull() gets called whenever we want to fill an area (perhaps the whole page).
    -- We get the height (parameter.maxheight) and the width (parameter.width)
    -- of the area to be filled.
    tab.pull = function(parameter,state)
            -- When pull is called the first time the state is not set yet.
            -- Currently we format all sub-objects (paragraphs),
            -- add them into the "object list" (state.objects) and
            -- call vsplit on the object list.
            if not state then
                state = {}
                local objects = {}
                state.total_height = 0
                state.objects = objects
                for i=1,#tab do
                    local contents = publisher.element_contents(tab[i])
                    objects[#objects + 1] = contents:format(parameter.width,nil,parameter)
                end
            end
            if #state.objects > 0 then
                local obj
                obj = paragraph.vsplit(state.objects,parameter.maxheight)
                return obj,state, #state.objects > 0
            else
                return nil,nil, false
            end
        end
   return tab
end

--- Textblock
--- ---------
--- A rectangular block of text. Return a vertical nodelist.
function commands.textblock( layoutxml,dataxml )
    trace("Textblock")
    local fontfamily
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface","rawstring")
    local colorname      = publisher.read_attribute(layoutxml,dataxml,"color",   "rawstring", "black")
    local width          = publisher.read_attribute(layoutxml,dataxml,"width",   "length_sp")
    local angle          = publisher.read_attribute(layoutxml,dataxml,"angle",   "number")
    local columns        = publisher.read_attribute(layoutxml,dataxml,"columns", "number")
    local columndistance = publisher.read_attribute(layoutxml,dataxml,"columndistance","rawstring")
    local textformat     = publisher.read_attribute(layoutxml,dataxml,"textformat","rawstring")

    width = width or xpath.get_variable("__maxwidth") * publisher.current_grid.gridwidth

    if not width then
        err("Can't evaluate width in textblock")
        rule = publisher.add_rule(nil,"head",{height=100*2^16,width=100*2^16})
        local v = node.vpack(rule)
        return v
    end

    columns = columns or 1
    if not columndistance then columndistance = "3mm" end
    if tonumber(columndistance) then
        columndistance = publisher.current_grid.gridwidth * columndistance
    else
        columndistance = tex.sp(columndistance)
    end

    if not fontname then fontname = "text" end
    fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
    if fontfamily == nil then
        err("Fontfamily %q not found.",fontname or "???")
        fontfamily = 1
    end

    local colortable
    if colorname then
        if not publisher.colors[colorname] then
            err("Color %q is not defined.",colorname)
        else
            colortable = publisher.colors[colorname].index
        end
    end

    -- FIXME: remove width_sp
    local width_sp = width

    local objects, nodes = {},{}
    local nodelist,parameter

    local tab = publisher.dispatch(layoutxml,dataxml)

    for i,j in ipairs(tab) do
        local eltname = publisher.elementname(j,true)
        trace("Textblock: Element = %q",tostring(eltname))
        if eltname == "Paragraph" then
            objects[#objects + 1] = publisher.element_contents(j)
        elseif eltname == "Ul" or eltname == "Ol" then
            for j,w in ipairs(publisher.element_contents(j)) do
                objects[#objects + 1] = w
            end
        elseif eltname == "Text" then
            assert(false)
        elseif eltname == "Action" then
            objects[#objects + 1] = publisher.element_contents(j)
        elseif eltname == "Bookmark" then
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    trace("Textblock: #objects=%d",#objects)

    if columns > 1 then
        width_sp = math.floor(  (width_sp - columndistance * ( columns - 1 ) )   / columns)
    end
    for _,paragraph in ipairs(objects) do
        if paragraph.id == 8 then -- whatsit
            -- todo: document how this can be!
            nodes[#nodes + 1] = paragraph
        else
            nodelist = paragraph.nodelist
            assert(nodelist)
            publisher.set_fontfamily_if_necessary(nodelist,fontfamily)
            paragraph.nodelist = publisher.set_color_if_necessary(nodelist,colortable)
            node.slide(nodelist)
            nodelist = paragraph:format(width_sp,textformat)

            nodes[#nodes + 1] = nodelist
        end
    end

    if #objects == 0 then
        warning("Textblock: no objects found!")
        local vrule = {  width = 10 * 2^16, height = -1073741824}
        nodes[1] = publisher.add_rule(nil,"head",vrule)
    end

    --- Multi column typesetting
    if columns > 1 then
        local rows = {}
        local number_of_rows = 0
        local neue_nodes = {}
        for i=1,#nodes do
            for n in node.traverse_id(0,nodes[i].list) do
                number_of_rows = number_of_rows + 1
                rows[number_of_rows] = n
            end
        end

        local rows_in_multicolumn = math.ceil(number_of_rows / columns)
        for i=1,rows_in_multicolumn do
            local current_row,hbox_current_row
            hbox_current_row = rows[i] -- first column
            local tail = hbox_current_row
            for j=2,columns do -- second and following columns
                local g1 = node.new("glue")
                g1.spec = node.new("glue_spec")
                g1.spec.width = columndistance
                tail.next = g1
                g1.prev = tail
                current_row = (j - 1) * rows_in_multicolumn + i
                if current_row <= number_of_rows then
                    tail = rows[current_row]
                    g1.next = tail
                    tail.prev = g1
                end
            end
            tail.next = nil
            neue_nodes[#neue_nodes + 1] = node.hpack(hbox_current_row)
        end
        nodes=neue_nodes
    end

    local tail
    for i=2,#nodes do
        tail = node.tail(nodes[i-1])
        tail.next = nodes[i]
        nodes[i].prev = tail
    end

    trace("Textbock: vpack()")
    nodelist = node.vpack(nodes[1])
    if angle then
        nodelist = publisher.rotate(nodelist,angle)
    end
    trace("Textbock: end")
    return nodelist
end


--- Underline
--- ---------
--- Underline text. This is done by setting the `att_underline` attribute and in the "finalizer"
--- drawing a line underneath the text.
function commands.underline( layoutxml,dataxml )
    trace("Underline")

    local a = paragraph:new()
    local objects = {}
    local tab = publisher.dispatch(layoutxml,dataxml)

    for i,j in ipairs(tab) do
        if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
            objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j),{underline = true})
        else
            objects[#objects + 1] = publisher.element_contents(j)
        end
    end
    for _,j in ipairs(objects) do
        a:append(j,{fontfamily = 0, underline = 1})
    end
    return a
end

--- Unordered list (`<Ul>`)
--- ------------------
--- A list with bullet points.
function commands.ul(layoutxml,dataxml )
    local ret = {}
    local labelwidth = tex.sp("5mm")
    publisher.textformats.__fivemm = {indent = labelwidth, alignment="justified",   rows = -1}
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        local a = paragraph:new("__fivemm")
        a:append(publisher.bullet_hbox(labelwidth),{})
        a:append(publisher.element_contents(j),{})
        ret[#ret + 1] = a
    end
    return ret
end


--- Until
--- -----
--- A repeat .. until loop. Use the condition in `test` to determine if the loop should exit
function commands.until_do( layoutxml,dataxml )
    local test = publisher.read_attribute(layoutxml,dataxml,"test","rawstring")
    assert(test)
    repeat
        publisher.dispatch(layoutxml,dataxml)
    until xpath.parse(dataxml,test,layoutxml[".__ns"])
end


--- URL
--- ---
--- Format the current URL. It should make the URL active.
function commands.url(layoutxml,dataxml)
    local a = paragraph:new()
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        a:append(xpath.textvalue_raw(true,publisher.element_contents(j)),{})
        a.nodelist = publisher.break_url(a.nodelist)
    end
    return a
end


--- Value
--- -----
--- Get the value of an xpath expression (attribute `select`) or of the literal string.
function commands.value( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","rawstring")
    local ok = true
    local tab
    if selection then
        local ok
        ok, tab = xpath.parse_raw(dataxml,selection,layoutxml[".__ns"])
        if not ok then err(tab) return end
    else
        -- Change all br elements to \n
        for i=1,#layoutxml do
            if type(layoutxml[i]) == "table" and string.match(layoutxml[i][".__local_name"],"^[bB][rR]$") then
                layoutxml[i] = "\n"
            end
        end
        tab = table.concat(layoutxml)
    end
    return tab
end

--- VSpace
--- ------
--- Create a vertical space that stretches up to infinity
function commands.vspace( layoutxml,dataxml )
    local n=node.new("glue")
    n.spec=node.new("glue_spec")
    n.spec.width = 0
    n.spec.stretch = 65536
    n.spec.stretch_order = 3
    node.set_attribute(n,publisher.att_origin,publisher.origin_vspace)
    return n
end


--- While
--- -----
--- A while loop. Use the condition in `test` to determine if the loop should be entered
function commands.while_do( layoutxml,dataxml )
    local test = publisher.read_attribute(layoutxml,dataxml,"test","rawstring")
    assert(test)

    while xpath.parse(dataxml,test,layoutxml[".__ns"]) do
        publisher.dispatch(layoutxml,dataxml)
    end
end

file_end("commands.lua")
return commands

