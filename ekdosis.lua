--[[
This file is part of the `ekdosis' package

ekdosis -- Typesetting TEI xml-compliant critical editions
Copyright (C) 2020--2021  Robert Alessi

Please send error reports and suggestions for improvements to Robert
Alessi <alessi@robertalessi.net>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see
<http://www.gnu.org/licenses/>.
--]]

-- `'
-- This table will hold the functions:
ekdosis = {}

-- lpeg equivalent for string.gsub()
local function gsub(s, patt, repl)
  patt = lpeg.P(patt)
  patt = lpeg.Cs((patt / repl + 1)^0)
  return lpeg.match(patt, s)
end

-- some basic patterns:
local letters = lpeg.R("az", "AZ")
local ascii = lpeg.R("az", "AZ", "@@")
local dblbkslash = lpeg.Cs("\\")
local bsqbrackets = lpeg.Cs{ "[" * ((1 - lpeg.S"[]") + lpeg.V(1))^0 * "]" }
local bcbraces = lpeg.Cs{ "{" * ((1 - lpeg.S"{}") + lpeg.V(1))^0 * "}" }
local spce = lpeg.Cs(" ")
local spcenc = lpeg.P(" ")
local cmdstar = lpeg.Cs(spce * lpeg.P("*"))
local bsqbracketsii = lpeg.Cs(bsqbrackets^-2)
local bcbracesii = lpeg.Cs(bcbraces^-2)
local cmd = lpeg.Cs(dblbkslash * ascii^1 * cmdstar^-1)
local rawcmd = lpeg.Cs(dblbkslash * ascii^1)
local aftercmd = lpeg.Cs(lpeg.S("*[{,.?;:'`\"") + dblbkslash)
local cmdargs = lpeg.Cs(spce^-1 * bsqbracketsii * bcbracesii * bsqbrackets^-1)
local app = lpeg.Cs("app")
local lemrdg = lpeg.Cs(lpeg.Cs("lem") + lpeg.Cs("rdg"))
local note = lpeg.Cs("note")
local lnbrk = lpeg.Cs("\\\\")
local poemline = lpeg.Cs(lnbrk * spcenc^-1 * lpeg.S("*!")^-1 * bsqbrackets^-1 * spcenc^-1)
local poemlinebreak = lpeg.Cs(lnbrk * spcenc^-1 * lpeg.P("&gt;") * bsqbrackets^-1 * spcenc^-1)
local linegroup = lpeg.Cs{ "<lg" * ((1 - lpeg.S"<>") + lpeg.V(1))^0 * ">" }
local bclinegroup = lpeg.Cs(linegroup + lpeg.P("</lg>"))
local endpoem = lpeg.Cs(lnbrk * lpeg.S("*!") * bsqbrackets^-1) -- not used
local sections = lpeg.Cs(lpeg.P("book") + lpeg.P("part") + lpeg.P("chapter")
			    + lpeg.P("section") + lpeg.P("subsection")
			    + lpeg.P("subsubsection"))
local par =  lpeg.P(lpeg.P("\\par") * spce^0)
local parb = lpeg.P(lpeg.P("\\p@rb") * spce^0)
local para = lpeg.P(lpeg.P("\\p@ra") * spce^0)
local labelrefcmds = lpeg.Cs(lpeg.P("label")
			       + lpeg.P("linelabel")
			       + lpeg.P("lineref")
			       + lpeg.P("ref")
			       + lpeg.P("pageref")
			       + lpeg.P("vref")
			       + lpeg.P("vpageref"))
local citecmds = lpeg.Cs(lpeg.P("icite")
			    + lpeg.P("cite")
			    + lpeg.P("Cite")
			    + lpeg.P("cite *")
			    + lpeg.P("parencite")
			    + lpeg.P("Parencite")
			    + lpeg.P("parencite *")
			    + lpeg.P("footcite")
			    + lpeg.P("footcitetext")
			    + lpeg.P("textcite")
			    + lpeg.P("Textcite")
			    + lpeg.P("smartcite")
			    + lpeg.P("Smartcite")
			    + lpeg.P("autocite")
			    + lpeg.P("Autocite")
			    + lpeg.P("autocite *")
			    + lpeg.P("Autocite *")
)
--
-- Bind to local variables
local next = next

-- General
local xmlids = {}
table.insert(xmlids, {xmlid = "scholars"} )

local function xmlidfound(element)
   for i = 1,#xmlids do
      if xmlids[i].xmlid == element then
	 return true
      end
   end
   return false
end

local function checkxmlid(str)
   if string.find(str, "^[0-9]")
      or string.find(str, "[:; ]")
   then
      return false
   else
      return true
   end
end

-- Witnesses
local listWit = {}
-- Persons/Scholars
local listPerson = {}

local idsRend = {}
local shorthands = {}

local function isfound(table, value)
   for i = 1,#table do
      if table[i] == value then
	 return true
      end
   end
   return false
end

local function isintable(table, value)
   for i = 1,#table do
      if table[i].a == value then
	 return true
      end
   end
   return false
end

local function get_a_index(id, table)
   local idfound = nil
   for i = 1,#table
   do
      if table[i].a == id then
	 idfound = i
	 break
      end
   end
   return idfound
end

local function getindex(id, table)
   local idfound = nil
   for i = 1,#table
   do
      if table[i].xmlid == id then
	 idfound = i
	 break
      end
   end
   return idfound
end

function ekdosis.newwitness(id,
			    siglum,
			    description,
			    Settlement,
			    Institution,
			    Repository,
			    Collection,
			    Idno,
			    MsName,
			    OrigDate)
   if xmlidfound(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" already exists as an xml:id. "
      	 ..
      	 "Please pick another id.}}")
   elseif not checkxmlid(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" is not a valid xml:id. \\MessageBreak "
      	 ..
      	 "Please pick another id.}}")
   else
      table.insert(xmlids, {xmlid = id})
      table.sort(xmlids, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      table.insert(idsRend, {xmlid = id, abbr = siglum})
      table.sort(idsRend, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      table.insert(listWit, {xmlid = id,
			     abbr = siglum,
			     detailsDesc = description,
			     msIdentifier = {
				settlement = Settlement,
				institution = Institution,
				repository = Repository,
				collection = Collection,
				idno = Idno,
				msName = MsName}
                             })
      local indexwit = getindex(id, listWit)
      if OrigDate ~= "" then
	 listWit[indexwit].history = {}
	 listWit[indexwit].history.origin = {origDate = OrigDate}
      end
   end
   return true
end

function ekdosis.newhand(id, witid, siglum, description)
   if xmlidfound(id) or not xmlidfound(witid)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" already exists as an xml:id. "
      	 ..
      	 "Please pick another id.}}")
   elseif not checkxmlid(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" is not a valid xml:id. \\MessageBreak "
      	 ..
      	 "Please pick another id.}}")
   else
      table.insert(xmlids, {xmlid = id})
      table.sort(xmlids, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      table.insert(idsRend, {xmlid = id, abbr = siglum})
      table.sort(idsRend, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      local indexwit = getindex(witid, listWit)
      -- listWit[indexwit].handDesc = {xmlid = id, abbr = siglum, handNote = description}
      if listWit[indexwit].handDesc == nil
      then
	 listWit[indexwit].handDesc = {}
      else
      end
      table.insert(listWit[indexwit].handDesc,
		   {xmlid = id, abbr = siglum, detailsDesc = description})
   end
   return true
end

function ekdosis.newshorthand(id, rend, xmlids)
   if isintable(shorthands, id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" already exists as a shorthand. "
      	 ..
      	 "Please pick another shorthand.}}")
   else
      table.insert(shorthands, { a = id, b = rend, c = xmlids })
      table.sort(shorthands, function(a ,b) return(#a.a > #b.a) end)
      table.insert(idsRend, {xmlid = id, abbr = rend})
      table.sort(idsRend, function(a ,b) return(#a.xmlid > #b.xmlid) end)
   end
   return true
end

function ekdosis.newscholar(id,
			    siglum,
			    rawname,
			    Forename,
			    Surname,
			    AddName,
			    Note)
   if xmlidfound(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" already exists as an xml:id. "
      	 ..
      	 "Please pick another id.}}")
   elseif not checkxmlid(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" is not a valid xml:id. \\MessageBreak "
      	 ..
      	 "Please pick another id.}}")
   else
      table.insert(xmlids, {xmlid = id})
      table.sort(xmlids, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      table.insert(idsRend, {xmlid = id, abbr = siglum})
      table.sort(idsRend, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      if rawname ~= ""
      then
	 table.insert(listPerson, {xmlid = id,
				   abbr = siglum,
				   note = Note,
				   persName = {
				      name = rawname}
	 })
      else
	 table.insert(listPerson, {xmlid = id,
				   abbr = siglum,
				   note = Note,
				   persName = {
				      forename = Forename,
				      surname = Surname,
				      addName = AddName}
	 })
      end
   end
   return true
end

local xmlbibresource = nil

function ekdosis.addxmlbibresource(str)
   if string.find(str, "%.xml$")
   then
      xmlbibresource = str
   else
      xmlbibresource = str..".xml"
   end
   return true
end

function ekdosis.newsource(id, siglum)
   if xmlidfound(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
	    ..id..
	    "\" already exists as an xml:id. "
	    ..
	    "Please pick another id.}}")
   elseif not checkxmlid(id)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..id..
      	 "\" is not a valid xml:id. \\MessageBreak "
      	 ..
      	 "Please pick another id.}}")
   else
      table.insert(xmlids, {xmlid = id})
      table.sort(xmlids, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      table.insert(idsRend, {xmlid = id, abbr = siglum})
      table.sort(idsRend, function(a ,b) return(#a.xmlid > #b.xmlid) end)
   end
   return true
end

function ekdosis.getsiglum(str, opt)
   str = str..","
   str = string.gsub(str, "%s-(%,)", "%1")
   ctrl = str
   if opt == "tei" then
      for i = 1,#shorthands do
	 str = string.gsub(str, shorthands[i].a, shorthands[i].c)
      end
      for i = 1,#idsRend do
	 str  = string.gsub(str, "(%f[%w])"..idsRend[i].xmlid.."(%,)",
			    "%1#"..idsRend[i].xmlid.."%2")
	 ctrl = string.gsub(ctrl, idsRend[i].xmlid.."%,", "")
      end
      str = string.gsub(str, "%,(%s-)([%#])", " %2")
      str = string.gsub(str, "%,$", "")
   else
      for i = 1,#idsRend do
	 str  = string.gsub(str, idsRend[i].xmlid.."%,", idsRend[i].abbr)
	 ctrl = string.gsub(ctrl, idsRend[i].xmlid.."%,", "")
      end
   end
   -- if string.find(ctrl, "[A-Za-z0-9]")
   if string.find(ctrl, "%S")
   then
      return "<??>"
   else
      return str
   end
end

-- begin totei functions

local cmdtotags = {
   {a="textsuperscript", b="hi", c=" rend=\"sup\""},
   {a="textsubscript", b="hi", c=" rend=\"sub\""},
   {a="LRfootnote", b="note", c=" place=\"bottom\""},
   {a="RLfootnote", b="note", c=" place=\"bottom\""},
   {a="enquote *", b="quote", c=""},
   {a="marginpar", b="note", c=" place=\"margin\""},
   {a="footnote", b="note", c=" place=\"bottom\""},
   {a="enquote", b="quote", c=""},
   {a="txtrans", b="s", c=" xml:lang=\"ar-Latn\" type=\"transliterated\""},
   {a="textbf", b="hi", c=" rend=\"bold\""},
   {a="textit", b="hi", c=" rend=\"italic\""},
   {a="textsc", b="hi", c=" rend=\"smallcaps\""},
   {a="textsf", b="hi", c=" rend=\"sf\""},
   {a="arbup", b="hi", c=" rend=\"sup\""},
   {a="txarb", b="s", c=" xml:lang=\"arb\""},
   {a="arb", b="foreign",
    c=" xml:lang=\"ar-Latn\" type=\"transliterated\" subtype=\"arabtex\""}
}

local texpatttotags = {
   {a="\\addentries%s+%[(.-)%]{(.-)}", b=""},
   {a="\\addentries%s+{(.-)}", b=""},
   {a="\\setverselinenums%s+{(.-)}{(.-)}", b=""},
   {a="\\resetvlinenumber%s+%[(.-)%]", b=""},
   {a="\\resetvlinenumber%s+", b=""},
   {a="\\resetlinenumber%s+%[(.-)%]", b=""},
   {a="\\resetlinenumber%s+", b=""},
   {a="\\indentpattern%s+{(.-)}", b=""},
   {a="\\settowidth%s+{(.-)}{(.-)}", b=""},
   {a="\\poemlines%s+{(.-)}", b=""},
   {a="\\pagebreak%s+%[[1-4]%]", b=""},
   {a="\\pagebreak%s+", b=""},
   {a="\\altrfont%s+", b=""},
   {a="\\mbox%s+{(.-)}", b="%1"},
   {a="\\LR%s+{(.-)}", b="%1"},
   {a="\\RL%s+{(.-)}", b="%1"},
   {a="\\%=%=%=%s?", b="—"},
   {a="\\%-%-%-%s?", b="—"},
   {a="\\%=%=%s?", b="–"},
   {a="\\%-%-%s?", b="–"},
   {a="\\%=%/%s?", b="‐"},
   {a="\\%-%/%s?", b="‐"},
   {a="\\vin%s+", b=""}
}

local envtotags = {
   {a="flushright", b="p", c=" rend=\"align(right)\""},
   {a="flushleft", b="p", c=" rend=\"align(left)\""},
   {a="quotation", b="quote", c=""},
   {a="txarabtr", b="p", c=" xml:lang=\"ar-Latn\" type=\"transliterated\""},
   {a="quoting", b="quote", c=""},
   {a="ekdpar", b="p", c=""},
   {a="txarab", b="p", c=" xml:lang=\"arb\""},
   {a="center", b="p", c=" rend=\"align(center)\""},
   {a="arab", b="p",
    c=" xml:lang=\"ar-Latn\" type=\"transliterated\" subtype=\"arabtex\""}
}

local close_p = {
   "p",
   "lg"
}

local forbid_xmlid = true

function ekdosis.newcmdtotag(cmd, tag, attr)
   if forbid_xmlid
   then
      attr = string.gsub(attr, "xml:id", "n") -- xml:id is not allowed here
   else
   end
   if isintable(cmdtotags, cmd)
   then
      local index = get_a_index(cmd, cmdtotags)
      table.remove(cmdtotags, index)
      table.insert(cmdtotags, {a = cmd, b = tag, c = " "..attr})
      table.sort(cmdtotags, function(a ,b) return(#a.a > #b.a) end)
   else
      table.insert(cmdtotags, {a = cmd, b = tag, c = " "..attr})
      table.sort(cmdtotags, function(a ,b) return(#a.a > #b.a) end)
   end
   return true
end

function ekdosis.newpatttotag(pat, repl)
   pat = string.gsub(pat, "([%[%]])", "%%%1")
   pat = string.gsub(pat, "%#[1-9]", "(.-)")
   repl = string.gsub(repl, "%#([1-9])", "%%%1")
   if isintable(texpatttotags, pat)
   then
      local index = get_a_index(pat, texpatttotags)
      table.remove(texpatttotags, index)
      table.insert(texpatttotags, { a = pat, b = repl })
      table.sort(texpatttotags, function(a ,b) return(#a.a > #b.a) end)
   else
      table.insert(texpatttotags, { a = pat, b = repl })
      table.sort(texpatttotags, function(a ,b) return(#a.a > #b.a) end)
   end
   return true
end

function ekdosis.newenvtotag(env, tag, attr, closep)
   if forbid_xmlid
   then
      attr = string.gsub(attr, "xml:id", "n") -- xml:id is not allowed here
   else
   end
   if isintable(envtotags, env)
   then
      local index = get_a_index(env, envtotags)
      table.remove(envtotags, index)
      table.insert(envtotags, {a = env, b = tag, c = " "..attr, d = closep})
      table.sort(envtotags, function(a ,b) return(#a.a > #b.a) end)
   else
      table.insert(envtotags, {a = env, b = tag, c = " "..attr, d = closep})
      table.sort(envtotags, function(a ,b) return(#a.a > #b.a) end)
   end
   return true
end

-- Get values of attributes
local function get_attr_value(str, attr)
   str = str..","
   str = string.gsub(str, "%b{}", function(body)
			body = string.gsub(body, attr, attr.."@ekd")
			return string.format("%s", body)
   end)
   local attrval = string.match(str, "%f[%w]"..attr.."%s?%=%s?%b{}")
      or string.match(str, "%f[%w]"..attr.."%s?%=%s?.-%,")
      or ""
   attrval = string.gsub(attrval, attr.."%s?%=%s?(%b{})", function(bbraces)
			    bbraces = string.sub(bbraces, 2, -2)
			    return string.format("%s", bbraces)
   end)
   attrval = string.gsub(attrval, attr.."%s?%=%s?(.-)%s?%,", "%1")
   str = string.gsub(str, attr.."@ekd", attr)
   return attrval
end

local function xml_entities(str)
   str = string.gsub(str, "%<", "&lt;")
   str = string.gsub(str, "%>", "&gt;")
   return str
end

local function note_totei(str)
   str = gsub(str,
	      dblbkslash *
		 note *
		 spcenc^-1 *
		 bsqbrackets *
		 bcbraces *
		 spcenc^-1,
	      function(bkslash, cmd, opt, arg)
		 opt = string.sub(opt, 2, -2)
		 arg = string.sub(arg, 2, -2)
		 teitype = get_attr_value(opt, "type")
		 if teitype ~= "" then teitype = " type=\""..teitype.."\"" else end
		 right = get_attr_value(opt, "labelb")
		 left = get_attr_value(opt, "labele")
		 if right == ""
		 then
		    return string.format("<%s>%s</%s>", cmd, arg, cmd)
		 else
		    if left ~= ""
		    then
		       return string.format(
			  "<%s%s target=\"#range(right(%s),left(%s))\">%s</%s><anchor xml:id=\"%s\"/>",
			  cmd, teitype, right, left, arg, cmd, right)
		    elseif left == ""
		    then
		       return string.format(
			  "<%s%s target=\"#right(%s)\">%s</%s><anchor xml:id=\"%s\"/>",
			  cmd, teitype, right, arg, cmd, right)
		    end
		 end
   end)
   return str
end

local function app_totei(str)
   str = gsub(str,
	      dblbkslash *
		 app *
		 spcenc^-1 *
		 bsqbrackets *
		 bcbraces *
		 spcenc^-1,
	      function(bkslash, cmd, opt, arg)
		 opt = string.sub(opt, 2, -2)
		 arg = string.sub(arg, 2, -2)
		 opt = get_attr_value(opt, "type")
		 if opt ~= "" then opt = " type=\""..opt.."\"" else end
		 return app_totei(string.format("<%s%s>%s</%s>",
						cmd, opt, arg, cmd))
   end)
   return str
end

local function rdgGrp_totei(str)
   str = gsub(str,
	      dblbkslash *
		 lpeg.Cs("rdgGrp") *
		 spcenc^-1 *
		 bsqbrackets *
		 bcbraces *
		 spcenc^-1,
	      function(bkslash, cmd, opt, arg)
		 opt = string.sub(opt, 2, -2)
		 arg = string.sub(arg, 2, -2)
		 teitype = get_attr_value(opt, "type")
		 if teitype ~= "" then teitype = " type=\""..teitype.."\"" else end
		 if opt == ""
		 then
		    return rdgGrp_totei(string.format("<%s>%s</%s>",
						       cmd, arg, cmd))
		 else
		    return rdgGrp_totei(string.format("<%s%s>%s</%s>",
						       cmd, teitype, arg, cmd))
		 end
   end)
   return str
end

local function lem_rdg_totei(str)
   str = gsub(str,
	      spcenc^-1 *
		 dblbkslash *
		 lemrdg *
		 spcenc^-1 *
		 bsqbrackets *
		 bcbraces *
		 spcenc^-1,
	      function(bkslash, cmd, opt, arg)
		 opt = string.sub(opt, 2, -2)
		 arg = string.sub(arg, 2, -2)
		 -- opt = get_attr_value(opt, "wit")
		 --
		 teiwit = get_attr_value(opt, "wit")
		 if teiwit ~= "" then teiwit = " wit=\""..ekdosis.getsiglum(teiwit, "tei").."\"" else end
		 teisource = get_attr_value(opt, "source")
		 if teisource ~= "" then teisource = " source=\""..ekdosis.getsiglum(teisource, "tei").."\"" else end
		 teiresp = get_attr_value(opt, "resp")
		 if teiresp ~= "" then teiresp = " resp=\""..ekdosis.getsiglum(teiresp, "tei").."\"" else end
		 teitype = get_attr_value(opt, "type")
		 if teitype ~= "" then teitype = " type=\""..teitype.."\"" else end
		 --
		 if opt == ""
		 then
		    return lem_rdg_totei(string.format("<%s>%s</%s>",
						       cmd, arg, cmd))
		 else
		    -- opt = ekdosis.getsiglum(opt, "tei")
		    return lem_rdg_totei(string.format("<%s%s%s%s%s>%s</%s>",
						       cmd, teiwit, teisource, teiresp, teitype, arg, cmd))
		 end
   end)
   str = gsub(str, spcenc^-0 * dblbkslash * lemrdg * spcenc^-1 * bcbraces * spcenc^-1,
	      function(bkslash, cmd, arg)
		 arg = string.sub(arg, 2, -2)
		 return lem_rdg_totei(string.format("<%s>%s</%s>", cmd, arg, cmd))
   end)
   return str
end

local function relocate_notes(str)
   str = string.gsub(str, "(%<lem.-%>.-)(%<note.->.-%<%/note%>)(.-%<%/lem%>)", "%1%3%2")
   return str
end

local function linestotei(str)
   if not string.find(str, "^%s?<lg")
   then
      str = "\n<l>"..str
   end
   str = gsub(str, poemline * spcenc^0 * bclinegroup, "</l>\n%2")
   str = gsub(str, linegroup * -(spcenc^0 * bclinegroup), "%1\n<l>")
   str = gsub(str, lpeg.Cs("</lg>") * -(spcenc^0 * (bclinegroup + -1)), "%1\n<l>")
   -- str = gsub(str, poemline * spcenc^-1 * -1, "</l>\n")
   str = gsub(str, poemlinebreak, "<lb/> ")
   -- str = gsub(str, poemline * spcenc^-1 * lpeg.Cs("<lg"), "</l>%2")
   -- str = gsub(str, lpeg.Cs("</lg>") * spcenc^1 * -lpeg.P("<l"), "%1\n<l>")
   str = gsub(str, poemline, "</l>\n<l>")
   return str
end

local function stanzatotei(str)
   str = string.gsub(str, "\\begin%s?%{ekdstanza%}(%b[])(.-)\\end%s?%{ekdstanza%}", function(opt, arg)
			arg = string.gsub(arg, "\\par%s?", "")
			opt = string.sub(opt, 2, -2)
			teitype = get_attr_value(opt, "type")
			if teitype ~= "" then teitype = " type=\""..teitype.."\"" else end
			if opt == ""
			then
			   return string.format("<lg>%s</lg>", arg)
			else
			   return string.format("<lg%s>%s</lg>", teitype, arg)
			end
   end)
   str = string.gsub(str, "\\begin%s?%{ekdstanza%}(.-)\\end%s?%{ekdstanza%}", function(arg)
			arg = string.gsub(arg, "\\par%s?", "")
			return string.format("<lg>%s</lg>", arg)
   end)
   return str
end

-- better use lpeg: look into this later
local function versetotei(str)
   str = string.gsub(str, "\\begin%s?%{ekdverse%}(%b[])(.-)\\end%s?%{ekdverse%}", function(opt, arg)
			arg = string.gsub(arg, "\\par%s?", "")
			arg = string.gsub(arg, "\\begin%s?%{patverse%*?%}", "")
			arg = string.gsub(arg, "\\end%s?%{patverse%*?%}", "")
			arg = string.gsub(arg, "\\indentpattern%s?%b{}", "")
			opt = string.sub(opt, 2, -2)
			teitype = get_attr_value(opt, "type")
			if teitype ~= "" then teitype = " type=\""..teitype.."\"" else end
			if opt == ""
			then
			   return "\\p@rb "..linestotei(string.format("<lg>%s</lg>", arg)).."\\p@ra "
			else
			   return "\\p@rb "..linestotei(string.format("<lg%s>%s</lg>", teitype, arg)).."\\p@ra "
			end
   end)
   str = string.gsub(str, "\\begin%s?%{ekdverse%}(.-)\\end%s?%{ekdverse%}", function(arg)
			arg = string.gsub(arg, "\\par%s?", "")
			return "\\p@rb "..linestotei(string.format("<lg>%s</lg>", arg)).."\\p@ra "
   end)
   str = string.gsub(str, "\\begin%s?%{verse%}%b[](.-)\\end%s?%{verse%}", function(arg)
			arg = string.gsub(arg, "\\par%s?", "")
			return "\\p@rb "..linestotei(string.format("<lg>%s</lg>", arg)).."\\p@ra "
   end)
   str = string.gsub(str, "\\begin%s?%{verse%}(.-)\\end%s?%{verse%}", function(arg)
			arg = string.gsub(arg, "\\par%s?", "")
			return "\\p@rb "..linestotei(string.format("<lg>%s</lg>", arg)).."\\p@ra "
   end)
   return str
end

local function envtotei(str)
   for i = 1,#envtotags
   do
      if envtotags[i].b ~= ""
      then
	 if isfound(close_p, envtotags[i].b) or envtotags[i].d == "yes"
	 then
	    str = gsub(str, lpeg.P("\\begin") * spcenc^-1 * lpeg.P("{")
			  * lpeg.Cs(envtotags[i].a) * lpeg.P("}")
			  * bsqbracketsii * bcbracesii * spcenc^-1,
		       "\\p@rb <"..envtotags[i].b..envtotags[i].c..">")
	    str = gsub(str, spcenc^-1 * lpeg.P("\\end") * spcenc^-1 * lpeg.P("{")
			  * lpeg.Cs(envtotags[i].a) * lpeg.P("}"),
		       "</"..envtotags[i].b..">\\p@ra ")
	 else
	    str = gsub(str, lpeg.P("\\begin") * spcenc^-1 * lpeg.P("{")
			  * lpeg.Cs(envtotags[i].a) * lpeg.P("}")
			  * bsqbracketsii * bcbracesii * spcenc^-1,
		       "<"..envtotags[i].b..envtotags[i].c..">")
	    str = gsub(str, spcenc^-1 * lpeg.P("\\end") * spcenc^-1 * lpeg.P("{")
			  * lpeg.Cs(envtotags[i].a) * lpeg.P("}"),
		       "</"..envtotags[i].b..">")
	 end
      else
	 str = gsub(str, lpeg.P("\\begin") * spcenc^-1 * lpeg.P("{")
		       * lpeg.Cs(envtotags[i].a) * lpeg.P("}")
		       * bsqbracketsii * bcbracesii * spcenc^-1,
		    "")
	 str = gsub(str, spcenc^-1 * lpeg.P("\\end") * spcenc^-1 * lpeg.P("{")
		       * lpeg.Cs(envtotags[i].a) * lpeg.P("}"),
		    "")
      end
   end
   str = gsub(str, lpeg.P("\\begin") * spcenc^-1 * lpeg.P("{")
		 * lpeg.Cs(ascii^1) * lpeg.P("}") * bsqbracketsii
		 * bcbracesii * spcenc^-1,
	      "<%1>")
   str = gsub(str, spcenc^-1 * lpeg.P("\\end") * spcenc^-1 * lpeg.P("{")
		 * lpeg.Cs(ascii^1) * lpeg.P("}") * bsqbracketsii
		 * bcbracesii,
	      "</%1>")
   return str
end

local function texpatttotei(str)
   for i = 1,#texpatttotags do
      str = string.gsub(str, texpatttotags[i].a, texpatttotags[i].b)
   end
   return str
end

local function icitetotei(str)
   str = gsub(str, lpeg.P("\\")
		 * citecmds
		 * spcenc^-1
		 * bsqbrackets
		 * bsqbrackets
		 * bcbraces
		 * (bsqbrackets + bcbraces)^-1,
	      function(cmd, pre, post, body, opt)
		 pre = string.sub(pre, 2, -2)
		 post = string.sub(post, 2, -2)
		 body = string.sub(body, 2, -2)
		 if not checkxmlid(body)
		 then
		    tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
				 ..body..
				 "\" is not a valid xml:id. \\MessageBreak "
				 ..
				 "Please pick another id.}}")
		 else
		 end
		 return string.format("%s <ref target=\"#%s\">%s</ref>", pre, body, post)
   end)
   str = gsub(str, lpeg.P("\\")
		 * citecmds
		 * spcenc^-1
		 * bsqbrackets
		 * bcbraces
		 * (bsqbrackets + bcbraces)^-1,
	      function(cmd, post, body, opt)
		 post = string.sub(post, 2, -2)
		 body = string.sub(body, 2, -2)
		 if not checkxmlid(body)
		 then
		    tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
				 ..body..
				 "\" is not a valid xml:id. \\MessageBreak "
				 ..
				 "Please pick another id.}}")
		 else
		 end
		 return string.format("<ref target=\"#%s\">%s</ref>", body, post)
   end)
   str = gsub(str, lpeg.P("\\")
		 * citecmds
		 * spcenc^-1
		 * bcbraces
		 * (bsqbrackets + bcbraces)^-1,
	      function(cmd, body, opt)
		 body = string.sub(body, 2, -2)
		 if not checkxmlid(body)
		 then
		    tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
				 ..body..
				 "\" is not a valid xml:id. \\MessageBreak "
				 ..
				 "Please pick another id.}}")
		 else
		 end
		 return string.format("<ptr target=\"#%s\"/>", body)
   end)
   return str
end

local function cmdtotei(str)
   for i = 1,#cmdtotags
   do
      str = gsub(str, lpeg.P("\\") * lpeg.Cs(cmdtotags[i].a) * spcenc^-1 * bsqbrackets * -bcbraces, "\\%1%2{}")
      str = gsub(str, lpeg.P("\\") * lpeg.Cs(cmdtotags[i].a) * spcenc^-1 * -(bsqbrackets + bcbraces), "\\%1[]{}")
      str = string.gsub(str, "(\\"..cmdtotags[i].a..")%s?%*?(%b{})", "%1[]%2")
      str = string.gsub(str, "(\\"..cmdtotags[i].a..")%s?%*?(%b[])(%b{})",
			function(cmd, arg, body)
			   body = string.sub(body, 2, -2)
			   arg = string.sub(arg, 2, -2)
			   arg = string.gsub(arg, "(%b{})", function(braces)
						braces = string.sub(braces, 2, -2)
						return string.format("\"%s\"", braces)
			   end)
			   body = cmdtotei(body)
			   -- return string.format("<"..cmdtotags[i].b..cmdtotags[i].c.." %s>%s</"..cmdtotags[i].b..">", arg, body)
			   if cmdtotags[i].b ~= ""
			   then
			      return string.format("<"..cmdtotags[i].b..cmdtotags[i].c..">%s</" ..
						   cmdtotags[i].b..">", body)
			   else
			      return ""
			   end
      end)
   end
   -- temporarily:
   str = string.gsub(str, "\\(getsiglum)%s?(%b{})",
		     function(cmd, body)
			body = string.sub(body, 2, -2)
			teisiglum = ekdosis.getsiglum(body, "tei")
 			printsiglum = ekdosis.getsiglum(body)
 			-- body = cmdtotei(body)
			return string.format("<ref target=\"%s\">%s</ref>",
					     teisiglum, printsiglum)
   end)
   str = string.gsub(str, "\\(gap)%s?(%b{})",
		     function(cmd, body)
			body = string.sub(body, 2, -2)
			teireason = get_attr_value(body, "reason")
			if teireason ~= "" then teireason = " reason=\""..teireason.."\"" else end
			teiunit = get_attr_value(body, "unit")
			if teiunit ~= "" then teiunit = " unit=\""..teiunit.."\"" else end
			teiquantity = get_attr_value(body, "quantity")
			if teiquantity ~= "" then teiquantity = " quantity=\""..teiquantity.."\"" else end
			teiextent = get_attr_value(body, "extent")
			if teiextent ~= "" then teiextent = " extent=\""..teiextent.."\"" else end
			return string.format("<gap%s%s%s%s/>", teireason, teiunit, teiquantity, teiextent)
   end)
   str = gsub(str, lpeg.P("\\") * labelrefcmds * spcenc^-1 * bcbraces,
	      function(cmd, body)
		 body = string.sub(body, 2, -2)
		 if not checkxmlid(body)
		 then
		    tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
				 ..body..
				 "\" is not a valid xml:id. \\MessageBreak "
				 ..
				 "Please pick another id.}}")
		 else
		 end
		 if string.find(cmd, "label")
		 then
		    return string.format("<anchor xml:id=\"%s\"/>", body)
		 else
		    return string.format("<ptr target=\"#%s\"/>", body)
		 end
   end)
   str = string.gsub(str, "\\(%a+)%s?%*?(%b[])(%b{})",
		     function(cmd, opt, body)
			body = string.sub(body, 2, -2)
			body = cmdtotei(body)
			return string.format("<%s>%s</%s>", cmd, body, cmd)
   end)
   str = string.gsub(str, "\\(%a+)%s?%*?(%b{})",
		     function(cmd, body)
			body = string.sub(body, 2, -2)
			body = cmdtotei(body)
			return string.format("<%s>%s</%s>", cmd, body, cmd)
   end)
   str = string.gsub(str, "(%s)(%>)", "%2")
   return str
end

local teiautopar = true

function ekdosis.setteiautopar(choice)
   if choice == "yes"
   then
      teiautopar = true
   else
      teiautopar = false
   end
   return true
end

local function partotei(str)
   if teiautopar
   then
      str = gsub(str, lpeg.P(lpeg.P("\\par") * spcenc^1)^1, "\\par ")
      str = gsub(str, ((para + parb) * par^-1)^2, "\\p@r ")
      str = string.gsub(str, "\\p@ra%s+", "<p>")
      str = string.gsub(str, "\\p@rb%s+", "</p>")
      str = string.gsub(str, "\\p@r%s+", "")
      str = string.gsub(str, "%s?\\par%s?", "<p>", 1)
      str = string.gsub(str, "(%<p%>)(%s-)(%<%/?div%d?)", "%3")
      str = string.gsub(str, "%s?\\par%s?", "</p><p>")
      str = string.gsub(str, "<p>%s?</p>", "")
      str = string.gsub(str, "(%<p%>)%s?(%</div%>)$", "%2")
      str = string.gsub(str, "(%<p%>)%s?$", "")
      str = string.gsub(str, "(<p>)%s?(<div.->)", "%2%1")
   else
      str = gsub(str, par + para + parb, "")
   end
   return str
end

local function self_close_tags(str)
   str = gsub(str, lpeg.P("<" * -lpeg.S("/"))
		 * lpeg.Cs(letters^1)
		 * lpeg.Cs((1 - lpeg.S"<>")^0)
		 * lpeg.P(">")
		 * lpeg.P("</")
		 * lpeg.Cs(letters^1)
		 * lpeg.P(">"), function(ftag, arg, ltag)
		    if ftag == ltag
		    then
		       return string.format("<%s%s/>", ftag, arg)
		    else
		    end
   end)
   return str
end

local divdepth = {
   book = 1,
   part = 2,
   chapter = 3,
   section = 4,
   subsection = 5,
   subsubsection = 6
}

function ekdosis.mkdivdepths(...)
   divdepth = {}
   local num = 1
   for _, y in ipairs{...}
   do
      if y == "book" or "part" or "chapter"
	 or "section" or "subsection" or "subsubsection"
      then
	 divdepth[y] = num
	 num = num + 1
      else
      end
   end
   return true
end

-- LaTeX side: format the divisions
local fmtdiv = {}

function ekdosis.fmtdiv(n, fmtb, fmte)
   if isintable(fmtdiv, n)
   then
      local index = get_a_index(n, fmtdiv)
      table.remove(fmtdiv, index)
   else
   end
   table.insert(fmtdiv, { a = n, formatb = fmtb, formate = fmte} )
   return true
end

function ekdosis.getfmtdiv(n, pos)
   local index = get_a_index(n, fmtdiv)
   if index ~= nil
   then
      if pos == "b"
      then
	 return fmtdiv[index].formatb
      elseif pos == "e"
      then
	 return fmtdiv[index].formate
      end
   else
      return ""
   end
end

local ekddivs = true

function ekdosis.setekddivsfalse()
   ekddivs = false
end

local function ekddivs_totei(str)
   str = gsub(str, dblbkslash * lpeg.Cs("ekddiv") * spce^-1 * bcbraces,
	      function(bkslash, cmd, space, arg)
		 if ekddivs
		 then
		    arg = string.sub(arg, 2, -2)
		    teitype = get_attr_value(arg, "type")
		    tein = get_attr_value(arg, "n")
		    teihead = get_attr_value(arg, "head")
		    teidepth = get_attr_value(arg, "depth")
		    if teitype ~= "" then teitype = " type=\""..teitype.."\"" else end
		    if tein ~= "" then tein = " n=\""..tein.."\"" else end
		    if teidepth ~= ""
		    then
		       teidepth = " depth=\""..teidepth.."\""
		    else
		       teidepth = " depth=\"1\""
		    end
		    return string.format("\\p@rb <div%s%s%s><head>%s</head>\\p@ra ",
					 teitype, tein, teidepth, teihead)
		 else
		    return ""
		 end
   end)
   return str
end

local function section_totei(str)
   str = gsub(str, dblbkslash * sections * spce^-1 * bcbraces, "%1%2%3[]%4")
   str = gsub(str, dblbkslash * sections * spce^-1 * bsqbrackets * bcbraces,
	      function(bkslash, secname, space, opt, arg)
		 if ekddivs
		 then
		    return ""
		 else
		    ctr = divdepth[secname]
		    arg = string.sub(arg, 2, -2)
		    return string.format("\\p@rb <div%s type=\"%s\"><head>%s</head>\\p@ra ",
					 ctr, secname, arg)
		 end
   end)
   return str
end

local used_ndivs = {}

local function close_ekddivs_at_end(str)
   local isdiv = false
   if string.find(str, "</div>$")
   then
      isdiv = true
      str = string.gsub(str, "(.*)(</div>)$", "%1")
   else
   end
   -- collect used depth numbers
   for i in string.gmatch(str, "<div .-depth%=\"%d\".->")
   do
      i = string.match(i, "depth=\"%d\"")
      i = string.match(i, "%d")
      if isintable(used_ndivs, i)
      then
      else
	 table.insert(used_ndivs, {a = i} )
      end
   end
   if next(used_ndivs) ~= nil
   then
      table.sort(used_ndivs, function(a ,b) return(#a.a > #b.a) end)
   else
   end
   local firstdiv = string.match(str, "<div .-depth%=\"%d\".->") or ""
   firstdiv = string.match(firstdiv, "depth%=\"%d\"") or ""
   firstdiv = string.match(firstdiv, "%d") or ""
   local lastdiv = string.match(string.reverse(str), ">.-\"%d\"%=htped.- vid<") or ""
   lastdiv = string.match(lastdiv, "\"%d\"%=htped") or ""
   lastdiv = string.match(lastdiv, "%d") or ""
   local firstdivindex = get_a_index(firstdiv, used_ndivs)
   local lastdivindex = get_a_index(lastdiv, used_ndivs)
   firstdivindex = tonumber(firstdivindex)
   lastdivindex = tonumber(lastdivindex)
   local closedivs = ""
   if isintable(used_ndivs, firstdiv)
   then
      while lastdivindex >= firstdivindex
      do
	 closedivs = closedivs.."</div>"
	 lastdivindex = lastdivindex - 1
      end
   end
   if isdiv
   then
      return str..closedivs.."</div>"
   else
      return str..closedivs
   end
end

local function close_ndivs_at_end(str)
   local isdiv = false
   if string.find(str, "</div>$")
   then
      isdiv = true
      str = string.gsub(str, "(.*)(</div>)$", "%1")
   else
   end
   -- collect used div numbers
   for i in string.gmatch(str, "<div[1-6]")
   do
      i = string.match(i, "[1-6]")
      if isintable(used_ndivs, i)
      then
      else
   	 table.insert(used_ndivs, {a = i} )
      end
   end
   if next(used_ndivs) ~= nil
   then
      table.sort(used_ndivs, function(a ,b) return(#a.a > #b.a) end)
   else
   end
   local firstdiv = string.match(str, "<div[1-6]") or ""
   firstdiv = string.match(firstdiv, "[1-6]") or ""
   local lastdiv = string.match(string.reverse(str), "[1-6]vid<") or ""
   lastdiv = string.match(lastdiv, "[1-6]") or ""
   local firstdivindex = get_a_index(firstdiv, used_ndivs)
   local lastdivindex = get_a_index(lastdiv, used_ndivs)
   firstdivindex = tonumber(firstdivindex)
   lastdivindex = tonumber(lastdivindex)
   local closedivs = ""
   if isintable(used_ndivs, firstdiv)
   then
      while lastdivindex >= firstdivindex
      do
	 closedivs = closedivs.."</div"..used_ndivs[lastdivindex].a..">"
	 lastdivindex = lastdivindex - 1
      end
   end
   if isdiv
   then
      return str..closedivs.."</div>"
   else
      return str..closedivs
   end
end

local function close_ekddivs_in_between(str)
   local maxdepth = 1
   for i in string.gmatch(str, "<div.-depth=\"(%d)\".->", "%1")
   do
      if tonumber(i) > tonumber(maxdepth)
      then
	 maxdepth = i
      else
      end
   end
   for ndivi = 1, maxdepth
   do
      str = string.gsub(str, "(<div [^%>]-[Dd]epth%=\")("..ndivi..")(\".->)(.-)(<div [^%>]-depth%=\")(%d)(\".->)",
			function(bdivi, ndivi, edivi, between, bdivii, ndivii, edivii)
			   local firstdiv = ndivi
			   local lastdiv = ndivii
			   local firstdivindex = get_a_index(firstdiv, used_ndivs)
			   local lastdivindex = get_a_index(lastdiv, used_ndivs)
			   firstdivindex = tonumber(firstdivindex)
			   lastdivindex = tonumber(lastdivindex)
			   local closedivs = ""
			   if firstdivindex >= lastdivindex
			   then
			      while firstdivindex >= lastdivindex
			      do
				 closedivs = closedivs.."</div>"
				 firstdivindex = firstdivindex - 1
			      end
			   end
			   bdivii = string.gsub(bdivii, "depth", "Depth")
			   return string.format("%s%s%s%s%s%s%s%s",
						bdivi, ndivi, edivi, between,
						closedivs, bdivii, ndivii, edivii)
      end)
   end
   return str
end

local function clean_ekddivs(str)
   str = string.gsub(str, "(<div.-)(%s[Dd]epth%=\"%d\")(.->)", "%1%3")
   used_ndivs = {}
   return str
end

local function close_ndivs_in_between(str)
   for ndivi = 1, 6
   do
      str = string.gsub(str, "(<[Dd]iv)("..ndivi..")(.->)(.-)(<div)([1-6])(.->)",
			function(bdivi, ndivi, edivi, between, bdivii, ndivii, edivii)
			   local firstdiv = ndivi
			   local lastdiv = ndivii
			   local firstdivindex = get_a_index(firstdiv, used_ndivs)
			   local lastdivindex = get_a_index(lastdiv, used_ndivs)
			   firstdivindex = tonumber(firstdivindex)
			   lastdivindex = tonumber(lastdivindex)
			   local closedivs = ""
			   if firstdivindex >= lastdivindex
			   then
			      while firstdivindex >= lastdivindex
			      do
			   	 closedivs = closedivs.."</div"..used_ndivs[firstdivindex].a..">"
			   	 firstdivindex = firstdivindex - 1
			      end
			   end
			   bdivii = string.gsub(bdivii, "div", "Div")
			   return string.format("%s%s%s%s%s%s%s%s",
						bdivi, ndivi, edivi, between,
						closedivs, bdivii, ndivii, edivii)
   end)
   end
   return str
end

local function clean_latexdivs(str)
   str = string.gsub(str, "(<Div)([1-6])(.->)", "<div%2%3")
   used_ndivs = {}
   return str
end

local function textotei(str)
   str = xml_entities(str)
   str = texpatttotei(str)
   str = note_totei(str)
   str = app_totei(str)
   str = rdgGrp_totei(str)
   str = lem_rdg_totei(str)
   str = relocate_notes(str)
   str = stanzatotei(str)
   str = versetotei(str)
   str = envtotei(str)
   str = ekddivs_totei(str)
   str = section_totei(str)
   str = icitetotei(str)
   str = cmdtotei(str)
   str = self_close_tags(str)
   str = partotei(str)
   if ekddivs
   then
      str = close_ekddivs_at_end(str)
      str = close_ekddivs_in_between(str)
      str = close_ekddivs_in_between(str)
      str = clean_ekddivs(str)
   else
      str = close_ndivs_at_end(str)
      str = close_ndivs_in_between(str)
      str = close_ndivs_in_between(str)
      str = clean_latexdivs(str)
   end
   return str
end

local teifilename = tex.jobname.."-tei"

function ekdosis.setteifilename(str)
   teifilename = str
   return true
end

function ekdosis.openteistream()
   local f = io.open(teifilename.."_tmp.xml", "a+")
   f:write('<?xml version="1.0" encoding="utf-8"?>', "\n")
   f:write("<TEI xmlns=\"http://www.tei-c.org/ns/1.0\">", "\n")
   f:write("<teiHeader>", "\n")
   f:write("<fileDesc>", "\n")
   f:write("<titleStmt>", "\n")
   f:write("<title><!-- Title --></title>", "\n")
   f:write("<respStmt>", "\n")
   f:write("<resp><!-- Edited by --></resp>", "\n")
   f:write("<name><!-- Name --></name>", "\n")
   f:write("</respStmt>", "\n")
   f:write("</titleStmt>", "\n")
   f:write("<publicationStmt>", "\n")
   f:write("<distributor><!-- Distributor name  --></distributor>", "\n")
   f:write("</publicationStmt>", "\n")
   f:write("<sourceDesc>", "\n")
   if next(listWit) == nil and next(listPerson) == nil
   then
      f:write("<p>No source, born digital</p>", "\n")
   else
      if next(listWit) ~= nil
      then
	 f:write("<listWit>", "\n")
	 for i = 1,#listWit do
	    f:write('<witness xml:id=\"', listWit[i].xmlid, "\">", "\n")
	    f:write('<abbr type="siglum">', textotei(listWit[i].abbr), "</abbr>", "\n")
	    f:write(textotei(listWit[i].detailsDesc), "\n")
	    f:write("<msDesc>", "\n")
	    if listWit[i].msIdentifier.settlement == ""
	       and listWit[i].msIdentifier.institution == ""
	       and listWit[i].msIdentifier.repository == ""
	       and listWit[i].msIdentifier.collection == ""
	       and listWit[i].msIdentifier.idno == ""
	       and listWit[i].msIdentifier.msName == ""
	    then
	       f:write("<msIdentifier/>", "\n")
	    else
	       f:write("<msIdentifier>", "\n")
	       if listWit[i].msIdentifier.settlement ~= "" then
		  f:write("<settlement>", textotei(listWit[i].msIdentifier.settlement), "</settlement>", "\n")
	 else end
	       if listWit[i].msIdentifier.institution ~= "" then
		  f:write("<institution>", textotei(listWit[i].msIdentifier.institution), "</institution>", "\n")
	 else end
	       if listWit[i].msIdentifier.repository ~= "" then
		  f:write("<repository>", textotei(listWit[i].msIdentifier.repository), "</repository>", "\n")
	 else end
	       if listWit[i].msIdentifier.collection ~= "" then
		  f:write("<collection>", textotei(listWit[i].msIdentifier.collection), "</collection>", "\n")
	 else end
	       if listWit[i].msIdentifier.idno ~= "" then
		  f:write("<idno>", textotei(listWit[i].msIdentifier.idno), "</idno>", "\n")
	 else end
	       if listWit[i].msIdentifier.msName ~= "" then
		  f:write("<msName>", textotei(listWit[i].msIdentifier.msName), "</msName>", "\n")
	 else end
	       f:write("</msIdentifier>", "\n")
	    end
	    if listWit[i].handDesc ~= nil then
	       f:write("<physDesc>", "\n")
	       f:write("<handDesc hands=\"", #listWit[i].handDesc, "\">", "\n")
	       local j = 1
	       while listWit[i].handDesc[j]
	       do
		  f:write("<handNote xml:id=\"", listWit[i].handDesc[j].xmlid, "\">", "\n")
		  f:write('<abbr type="siglum">', textotei(listWit[i].handDesc[j].abbr), "</abbr>", "\n")
		  f:write("<p>", textotei(listWit[i].handDesc[j].detailsDesc), "</p>", "\n")
		  f:write("</handNote>", "\n")
		  j = j + 1
	       end
	       f:write("</handDesc>", "\n")
	       f:write("</physDesc>", "\n")
      else end
	    if listWit[i].history ~= nil then
	       f:write("<history>", "\n")
	       f:write("<origin>", "\n")
	       f:write("<origDate>", textotei(listWit[i].history.origin.origDate), "</origDate>", "\n")
	       f:write("</origin>", "\n")
	       f:write("</history>", "\n")
	    end
	    f:write("</msDesc>", "\n")
	    f:write("</witness>", "\n")
	 end
	 f:write("</listWit>", "\n")
      end
      if next(listPerson) ~= nil
      then
	 f:write("<listPerson xml:id=\"scholars\">", "\n")
	 for i = 1,#listPerson do
	    f:write('<person xml:id=\"', listPerson[i].xmlid, "\">", "\n")
	    f:write('<persName>', "\n")
	    f:write('<abbr type="siglum">', textotei(listPerson[i].abbr), "</abbr>", "\n")
	    if listPerson[i].persName.name ~= nil
	    then
	       f:write(textotei(listPerson[i].persName.name))
	    else
	       if listPerson[i].persName.forename ~= ""
	       then
		  f:write("<forename>", textotei(listPerson[i].persName.forename), "</forename>", "\n")
	       else
		  f:write("<forename><!-- forename --></forename>", "\n")
	       end
	       if textotei(listPerson[i].persName.surname) ~= ""
	       then
		  f:write("<surname>", textotei(listPerson[i].persName.surname), "</surname>", "\n")
	       else
		  f:write("<surname><!-- surname --></surname>", "\n")
	       end
	       if textotei(listPerson[i].persName.addName) ~= ""
	       then
		  f:write("<addName>", textotei(listPerson[i].persName.addName), "</addName>", "\n")
	       end
	    end
	    if listPerson[i].note ~= ""
	    then
	       f:write("<note>", textotei(listPerson[i].note), "</note>", "\n")
	    end
	    f:write('</persName>', "\n")
	    f:write('</person>', "\n")
	 end
	 f:write("</listPerson>", "\n")
      end
   end
   f:write("</sourceDesc>", "\n")
   f:write("</fileDesc>", "\n")
   f:write("<encodingDesc>", "\n")
   f:write('<variantEncoding method="parallel-segmentation" location="internal"/>', "\n")
   f:write("</encodingDesc>", "\n")
   f:write("</teiHeader>", "\n")
   f:write("<text>", "\n")
   f:write("<body>", "\n")
   f:close()
   return true
end

local tidy = nil

local function cleanup_tei()
   local f = assert(io.open(teifilename.."_tmp.xml", "r"))
   t = f:read("*a")
   t = string.gsub(t, "%<p%>%s?%</p%>", "")
   t = string.gsub(t, "^\n", "")
   f:close()
   local fw = assert(io.open(teifilename.."_tmp.xml", "w"))
   fw:write(t)
   fw:close()
   return true
end

function ekdosis.closeteistream(opt)
   local f = io.open(teifilename.."_tmp.xml", "a+")
   f:write("\n", "</body>", "\n")
   if xmlbibresource ~= nil then
      bibf = assert(io.open(xmlbibresource, "r"))
      t = bibf:read("*a")
      t = string.gsub(t, "%s+corresp%=%b\"\"", "")
      t = string.gsub(t, "\n\n", "\n")
      f:write("<back>", "\n")
      f:write("<listBibl>", "\n")
      for i in string.gmatch(t, "<biblStruct.->.-</biblStruct>")
      do
	 f:write(i, "\n")
      end
      f:write("</listBibl>", "\n")
      f:write("</back>", "\n")
      bibf:close()
   else
   end
   f:write("</text>", "\n")
   f:write("</TEI>", "\n")
   f:close()
   cleanup_tei()
   os.remove(teifilename..".xml")
   os.rename(teifilename.."_tmp.xml", teifilename..".xml")
   if opt == "tidy" then
      os.execute("tidy -qmi -xml --output-xml yes "..teifilename..".xml")
   else
   end
   return true
end

function ekdosis.exporttei(str)
   local f = io.open(teifilename.."_tmp.xml", "a+")
   -- f:write("\n<p>")
   str = textotei(str)
   f:write(str)
   f:close()
   return true
end
-- end totei functions

-- begin basic TeX Conspectus siglorum
function ekdosis.basic_cs(msid)
   local indexwit = getindex(msid, listWit)
   siglum = listWit[indexwit].abbr
   -- if listWit[indexwit].detailsDesc == ""
   -- then
   -- name = listWit[indexwit].msIdentifier.msName
   -- else
   --    name = listWit[indexwit].msIdentifier.msName
   -- 	 .."\\thinspace\\newline\\bgroup\\footnotesize{}"..
   -- 	 listWit[indexwit].detailsDesc
   -- 	 .."\\egroup{}"
   -- end
   name = listWit[indexwit].detailsDesc
   if listWit[indexwit].history ~= nil
      and
      listWit[indexwit].history.origin ~= nil
   then
      date = listWit[indexwit].history.origin.origDate
   else
      date = ""
   end
   return siglum.."&"..name.."&"..date
end
-- end basic TeX Conspectus siglorum

function ekdosis.removesp(str)
   str = gsub(str, cmd * cmdargs * spcenc^-1, "%1%2")
   return str
end

function ekdosis.closestream()
   os.remove(tex.jobname..".ekd")
   os.rename(tex.jobname.."_tmp.ekd", tex.jobname..".ekd")
   return true
end

local cur_abs_pg = 0
local pg_i = nil
local pg_ii = nil
local prevcol = nil
local curcol = "x"

local check_resetlineno = {}

function ekdosis.update_abspg(n) -- not used
   cur_abs_pg = n
   return true
end

function ekdosis.storeabspg(n, pg)
   if pg == "pg_i" then
      pg_i = n
   elseif pg == "pg_ii" then
      pg_ii = n
      table.insert(check_resetlineno, curcol.."-"..pg_ii)
   end
   cur_abs_pg = n
   return true
end

function ekdosis.checkresetlineno()
   if isfound(check_resetlineno, curcol.."-"..pg_i)
   then
      return ""
   else
      return "\\resetlinenumber"
   end
end

--
-- Build environments to be aligned
--

local cur_alignment = "-"
local cur_alignment_patt = "%-"
local cur_alignment_cnt = 1

local newalignment = false
function ekdosis.newalignment(str)
   if str == "set"
   then
      newalignment = true
      cur_alignment = "-"..cur_alignment_cnt.."-"
      cur_alignment_patt = "%-"..cur_alignment_cnt.."%-"
      cur_alignment_cnt = cur_alignment_cnt + 1
   elseif str == "reset"
   then
      newalignment = false
      cur_alignment = "-"
      cur_alignment_patt = "%-"
   end
   return true
end

local aligned_texts = {}
local texts_w_apparatus = {}
local coldata_totei = {}

local function sanitize_envdata(str)  -- look for a better way to achieve this
   str = string.gsub(str, "(%a+)%s+(%b[])", "%1%2")
   str = string.gsub(str, "(%a+)(%b[])%s+", "%1%2")
   str = string.gsub(str, "%s+(%a+)(%b[])", "%1%2")
   str = gsub(str, lpeg.Cs(letters^1)
		 * spcenc^-1
		 * -bsqbrackets
		 * lpeg.Cs(";"), "%1[]%2")
   str = string.gsub(str, "%s+(%a+)(%b[])", "%1%2")
   return str
end

function ekdosis.mkenvdata(str, opt)
   if not string.find(str, "%;", -1) then str = str .. ";" else end
   --   str = str ..";"
   --   str = string.gsub(str, "%s+", "")
   local fieldstart = 1
   local col = 0
   if opt == "texts" then
      str = sanitize_envdata(str)
      repeat
	 local _s, nexti = string.find(str, "%b[]%s-%;", fieldstart)
	 local namediv = string.gsub(string.sub(str, fieldstart, nexti-1), "(%a+)%s-(%b[])", "%1")
	 local attr = string.gsub(string.sub(str, fieldstart, nexti-1), "(%a+)%s-(%b[])", "%2")
	 attr = string.sub(attr, 2, -2)
	 if forbid_xmlid
	 then
	    attr = string.gsub(attr, "xml:id", "n") -- xml:id is not allowed here
	 else
	 end
	 table.insert(aligned_texts, { text = namediv,
				       attribute = attr,
				       column = col })
	 table.insert(coldata_totei, { environment = namediv,
				       data = {} })
	 col = col + 1
	 fieldstart = nexti + 1
      until fieldstart > string.len(str)
      return aligned_texts
   elseif opt == "apparatus" then
      repeat
	 local nexti = string.find(str, "%;", fieldstart)
	 table.insert(texts_w_apparatus, string.sub(str, fieldstart, nexti-1))
	 fieldstart = nexti +1
      until fieldstart > string.len(str)
      return texts_w_apparatus
   end
end

-- Reminder: the following two variables are already set above
-- local prevcol = nil
-- local curcol = "x"

function ekdosis.storecurcol(n)
      curcol = n
   return true
end

function ekdosis.flushcolnums()
   prevcol = nil
   curcol = "x"
   return true
end

function ekdosis.flushenvdata()
   aligned_texts = {}
   texts_w_apparatus = {}
   coldata_totei = {}
   return true
end

function ekdosis.storecoldata(nthcol, chunk)
   local tindex = tonumber(nthcol) + 1
   table.insert(coldata_totei[tindex].data, chunk)
   return true
end

local environment_div = {}

local function build_envdiv(str)
   if not environment_div[str]
   then
      environment_div[str] = 1
   else
      environment_div[str] = environment_div[str] + 1
   end
   local div = "div-"..str.."_"..environment_div[str]
   if xmlidfound(div)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
		   ..div..
		   "\" already exists as an xml:id. "
		   ..
		   "ekdosis has generated some random id.}}")
      return "div-"..math.random(1000,9999)
   elseif not checkxmlid(div)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
      	 ..div..
      	 "\" is not a valid xml:id. \\MessageBreak "
      	 ..
      	 "Please pick another id.}}")
   else
      table.insert(xmlids, {xmlid = div})
      table.sort(xmlids, function(a ,b) return(#a.xmlid > #b.xmlid) end)
      return div
   end
end

function ekdosis.mkenv()
   local environments = {}
   for i = 1,#aligned_texts
   do
      if isfound(texts_w_apparatus, aligned_texts[i].text)
      then
	 table.insert(environments, "\\NewDocumentEnvironment{".. aligned_texts[i].text.."}{+b}"
			 .."{\\begin{nthcolumn}{".. aligned_texts[i].column.."}"
			 .."\\par"
			 .."\\EkdosisColStart"
			 .."\\EkdosisOn#1"
		         .."}{\\EkdosisOff"
			 .."\\EkdosisColStop"
		         .."\\end{nthcolumn}"
			 .."\\csname iftei@export\\endcsname\\luadirect{ekdosis.storecoldata("
			 .. aligned_texts[i].column
			 ..", \\luastringN{\\par#1\\par})}\\fi"
			 .."}")
	 table.insert(environments, "\\NewDocumentEnvironment{".. aligned_texts[i].text.."*}{+b}"
			 .."{\\begin{nthcolumn*}{".. aligned_texts[i].column.."}[]"
			 .."\\par"
			 .."\\EkdosisColStart"
			 .."\\EkdosisOn#1"
		         .."}{\\EkdosisOff"
			 .."\\EkdosisColStop"
		         .."\\end{nthcolumn*}"
			 .."\\csname iftei@export\\endcsname\\luadirect{ekdosis.storecoldata("
			 .. aligned_texts[i].column
			 ..", \\luastringN{\\par#1\\par})}\\fi"
			 .."}")
      else
	 table.insert(environments, "\\NewDocumentEnvironment{".. aligned_texts[i].text.."}{+b}"
			 .."{\\begin{nthcolumn}{".. aligned_texts[i].column.."}"
			 .."\\par"
			 .."#1"
		         .."}{\\end{nthcolumn}"
			 .."\\csname iftei@export\\endcsname\\luadirect{ekdosis.storecoldata("
			 .. aligned_texts[i].column
			 ..", \\luastringN{\\par#1\\par})}\\fi"
			 .."}")
	 table.insert(environments, "\\NewDocumentEnvironment{".. aligned_texts[i].text.."*}{+b}"
			 .."{\\begin{nthcolumn*}{"..aligned_texts[i].column.."}[]"
			 .."\\par"
			 .."#1"
			 .."}{"
		         .."\\end{nthcolumn*}"
			 .."\\csname iftei@export\\endcsname\\luadirect{ekdosis.storecoldata("
			 .. aligned_texts[i].column
			 ..", \\luastringN{\\par#1\\par})}\\fi"
			 .."}")
      end
      forbid_xmlid = false
      if aligned_texts[i].attribute ~= ""
      then
	 ekdosis.newenvtotag(aligned_texts[i].text, "div",
			     "xml:id=\""
				..build_envdiv(aligned_texts[i].text)
				.."\" "
				..aligned_texts[i].attribute)
      else
	 ekdosis.newenvtotag(aligned_texts[i].text, "div",
			     "xml:id=\""
				..build_envdiv(aligned_texts[i].text)
				.."\"")
      end
      forbid_xmlid = true
   end
   str = table.concat(environments)
   return str
end

function ekdosis.export_coldata_totei()
   for i = 1,#coldata_totei
   do
      ekdosis.exporttei("\\begin{".. coldata_totei[i].environment .."}"
			   .. table.concat(coldata_totei[i].data)
			.. "\\end{".. coldata_totei[i].environment .."}")
   end
end

-- handle multiple layers in apparatuses
--
local apparatuses = {}
local bagunits = {}

function ekdosis.newapparatus(teitype,
			      appdir,
			      apprule,
			      appdelim,
			      appsep,
			      appbhook,
			      appehook,
			      applimit,
			      applang)
   if isintable(apparatuses, teitype)
   then
      tex.print("\\unexpanded{\\PackageWarning{ekdosis}{\""
		   ..teitype..
		   "\" already exists.}}")
   else
      table.insert(apparatuses, {a = teitype,
				 direction = appdir,
				 rule = apprule,
				 delim = appdelim,
				 sep = appsep,
				 bhook = appbhook,
				 ehook = appehook,
				 limit = applimit,
				 lang = applang})
   end
   bagunits[teitype] = 1
   return true
end

function ekdosis.getapplang(teitype)
   i = get_a_index(teitype, apparatuses)
   if apparatuses[i].lang ~= ""
   then
      return apparatuses[i].lang
   else
      return "\\languagename"
   end
end

function ekdosis.getappdelim(str)
   for i = 1,#apparatuses
   do
      if apparatuses[i].a == str then
	 delimfound = apparatuses[i].delim
	 break
      end
   end
   return delimfound
end

function ekdosis.get_bagunits(teitype)
   return bagunits[teitype]
end

local function getapplimit(teitype)
   for i = 1,#apparatuses
   do
      if apparatuses[i].a == teitype then
	 limitfound = apparatuses[i].limit
	 break
      end
   end
   if tonumber(limitfound) ~= nil
   then
      if tonumber(limitfound) < 10
      then
	 return 0
      else
	 return limitfound
      end
   else
      return 0
   end
end

function ekdosis.limit_bagunits(teitype)
   local limit = tonumber(getapplimit(teitype))
   if limit >= 10 and bagunits[teitype] > limit
   then
      bagunits[teitype] = 2
      return "\\pagebreak"
   else
      return ""
   end
end

function ekdosis.addto_bagunits(teitype, n)
   if tonumber(getapplimit(teitype)) ~= 0
   then
      n = tonumber(n)
      bagunits[teitype] = bagunits[teitype] - n
   end
end

function ekdosis.increment_bagunits(teitype)
   bagunits[teitype] = (bagunits[teitype] or 0) + 1
end

local function reset_bagunits()
   for i = 1,#apparatuses
   do
      bagunits[apparatuses[i].a] = 1
   end
end

function ekdosis.appin(str, teitype)
   local f = io.open(tex.jobname.."_tmp.ekd", "a+")
   if next(apparatuses) == nil
   then
      f:write("<", cur_abs_pg, cur_alignment, curcol, "-0>", str, "</",
	      cur_abs_pg, cur_alignment, curcol, "-0>\n")
   else
      for i = 1,#apparatuses
      do
	 if apparatuses[i].a == teitype then
	    appno = i
	    break
	 end
      end
      f:write("<", cur_abs_pg, cur_alignment, curcol, "-",
	      appno, ">", str, "</", cur_abs_pg, cur_alignment, curcol, "-", appno, ">\n")
   end
   f:close()
   return true
end

function ekdosis.appout()
   local file = io.open(tex.jobname..".ekd", "r")
   if file ~= nil then io.close(file)
      f = assert(io.open(tex.jobname..".ekd", "r"))
      t = f:read("*a")
      local output = {}
      if next(apparatuses) == nil then
	 -- table.insert(output, "BEGIN")
	 table.insert(output, "\\csname ekd@default@rule\\endcsname\\NLS")
	 table.insert(output, "\\csname ekd@begin@apparatus\\endcsname\\ignorespaces")
--	 table.insert(output, "\\noindent ")
	 for i in string.gmatch(t,
				"<"..cur_abs_pg
				   ..cur_alignment_patt
				   ..curcol.."%-0>.-</"
				   ..cur_abs_pg
				   ..cur_alignment_patt
				   ..curcol.."%-0>")
	 do
	    table.insert(output, i)
	 end
	 -- table.insert(output, "END")
      else
	 local appinserted = false
	 local n = 1
	 while apparatuses[n]
	 do
	    if string.match(t, "<"..cur_abs_pg
			       ..cur_alignment_patt
			       ..curcol.."%-"..n..">.-</"
			       ..cur_abs_pg
			       ..cur_alignment_patt
			       ..curcol.."%-"..n..">")
	    then
	       -- table.insert(output, "BEGIN")
	       table.insert(output, "\\bgroup{}")
	       if apparatuses[n].direction == "LR"
	       then
		  table.insert(output, "\\pardir TLT\\leavevmode\\textdir TLT{}")
	       elseif apparatuses[n].direction == "RL"
	       then
		  table.insert(output, "\\pardir TRT\\leavevmode\\textdir TRT{}")
	       end
	       if apparatuses[n].rule == "none"
	       then
		  if n > 1
		  then
		     if appinserted
		     then
			table.insert(output, "\\NLS{}")
		     end
		  else
		     table.insert(output, "\\noindent ")
		  end
	       elseif apparatuses[n].rule ~= ""
	       then
		  if n > 1
		  then
		     if appinserted
		     then
			table.insert(output, "\\NLS{}" .. apparatuses[n].rule .. "\\NLS{}")
		     else
			table.insert(output, apparatuses[n].rule .. "\\NLS{}")
		     end
		  else
--		     table.insert(output, "\\noindent ")
		     table.insert(output, apparatuses[n].rule .. "\\NLS{}")
		  end
	       else
		  if n > 1
		  then
		     if appinserted
		     then
			table.insert(output, "\\NLS\\csname ekd@default@rule\\endcsname\\NLS{}")
		     else
			table.insert(output, "\\csname ekd@default@rule\\endcsname\\NLS{}")
		     end
		  else
--		     table.insert(output, "\\noindent ")
		     table.insert(output, "\\csname ekd@default@rule\\endcsname\\NLS{}")
		  end
	       end
	       if apparatuses[n].sep ~= ""
	       then
		  table.insert(output, "\\edef\\ekdsep{" .. apparatuses[n].sep .. "}")
	       else
	       end
	       if apparatuses[n].bhook ~= ""
	       then
		  table.insert(output, apparatuses[n].bhook)
	       else
		  table.insert(output, "\\relax")
	       end
	       for i in string.gmatch(t,
				      "<"..cur_abs_pg
					 ..cur_alignment_patt
					 ..curcol.."%-"..n..">.-</"
					 ..cur_abs_pg
					 ..cur_alignment_patt
					 ..curcol.."%-"..n..">")
	       do
		  table.insert(output, i)
		  appinserted = true
	       end
	       if apparatuses[n].ehook ~= ""
	       then
		  table.insert(output, apparatuses[n].ehook)
	       else
	       end
	       table.insert(output, "\\egroup{}")
	       -- table.insert(output, "END")
	    end
	    n = n + 1
	 end
      end
      f:close()
      str = table.concat(output)
      str = string.gsub(str, "</"..cur_abs_pg..cur_alignment_patt..curcol.."%-[0-9]>", "")
      str = string.gsub(str, "<"..cur_abs_pg..cur_alignment_patt..curcol.."%-[0-9]>", " ")
      return str
   else
   end
end

function ekdosis.appin_out(str, nl)
   local f = io.open(tex.jobname.."_tmp.ekd", "a+")
   if nl == "yes" then
      f:write(str, "\n")
   else
      f:write(str)
   end
   f:close()
   return true
end

local curcol_curabspg = {}

function ekdosis.testapparatus()
   if isfound(curcol_curabspg, curcol.."-"..cur_abs_pg)
   then
      if newalignment
      then
	 if next(apparatuses) ~= nil then
	    reset_bagunits()
	 end
	 newalignment = false
	 return "\\booltrue{do@app}"
      else
	 return "\\boolfalse{do@app}"
      end
   else
      table.insert(curcol_curabspg, curcol.."-"..cur_abs_pg)
      if next(apparatuses) ~= nil then
	 reset_bagunits()
      end
      newalignment = false
      return "\\booltrue{do@app}"
   end
end

local function get_ln_prefix(x, y)
   for index = 1, string.len(x)
   do
      if string.sub(x, index, index) ~= string.sub(y, index, index)
      then
	 return string.sub(x, 1, index - 1)
      end
   end
end

function ekdosis.numrange(x, y)
  xstr = tostring(x)
  ystr = tostring(y)
  if x == y -- which will never apply
  then
     return "\\LRnum{" .. xstr .. "}"
  elseif string.len(xstr) ~= string.len(ystr)
  then
     return "\\LRnum{" .. xstr .. "}--\\LRnum{" .. ystr .. "}"
  else
    common = get_ln_prefix(xstr, ystr)
    if string.len(common) == 0
    then
       return "\\LRnum{" .. xstr .. "}--\\LRnum{" .. ystr .. "}"
    elseif string.sub(xstr, -2, -2) == "1"
    then
       return "\\LRnum{"
	  .. string.sub(common, 1, -2)
	  .. string.sub(xstr, string.len(common), -1)
	  .. "}--\\LRnum{"
	  .. string.sub(ystr, string.len(common), -1)
	  .. "}"
    else
       return "\\LRnum{"
	  .. string.sub(common, 1, -1)
	  .. string.sub(xstr, string.len(common) + 1, -1)
	  .. "}--\\LRnum{"
	  .. string.sub(ystr, string.len(common) + 1, -1)
	  .. "}"
    end
  end
end

local lnlabs = {}
local lnlab_salt = 0
local current_lnlab = nil
local prev_lnlab = nil
local current_notelab = nil
local prev_notelab = nil
local current_lemma = nil
local salt = 0

local function mdvisintable(table, value)
   for _, v in pairs(table) do
      if v == value then return true end
   end
   return false
end

function ekdosis.dolnlab(str)
   prev_lnlab = current_lnlab
   current_lemma = str
   i = md5.sumhexa(str)
   if not mdvisintable(lnlabs, i) then
      table.insert(lnlabs, i)
   else
      i = i..salt
      table.insert(lnlabs, i)
      salt = salt + 1
   end
   current_lnlab = i
   return true
end

function ekdosis.getlnlab()
   return current_lnlab
end

function ekdosis.getprevlnlab()
   return prev_lnlab
end

function ekdosis.setnotelab(str)
   current_notelab = str
   return "\\linelabel{" .. current_notelab .. "}"
end

function ekdosis.getnotelab()
   return current_notelab
end

function ekdosis.setprevnotelab(str)
   prev_notelab = str
   return true
end

function ekdosis.getprevnotelab()
   return prev_notelab
end

local function remove_note(str)
   str = gsub(str, dblbkslash * lpeg.P("note") * cmdargs, "")
   return str
end

function ekdosis.mdvappend(str, teitype)
   if teitype == nil
   then
   return "\\linelabel{" .. current_lnlab .. "-b}\\wordboundary{}"
      ..
      current_lemma
      ..
      "\\linelabel{" .. current_lnlab .. "-e}"
      ..
      "\\csname append@app\\endcsname{"
      .. remove_note(str) .. "}"
   else
   return "\\linelabel{" .. current_lnlab .. "-b}\\wordboundary{}"
      ..
      current_lemma
      ..
      "\\linelabel{" .. current_lnlab .. "-e}"
      ..
      "\\csname append@app\\endcsname" .. "[" .. teitype ..  "]{"
      .. remove_note(str) .. "}"
   end
end

