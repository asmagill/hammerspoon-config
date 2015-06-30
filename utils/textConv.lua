local module = {}

local utf8    = require("hs.utf8")
local fnutils = require("hs.fnutils")

-- Also need way to convert all entities in string to appropriate UTF8

module.htmlEntities = setmetatable({}, { __index = function(object, key)
          if type(key) == "string" then
              local num = key:match("^&#(%d+);$")
              if num and tonumber(num) then
                  return utf8.codepointToUTF8(tonumber(num))
              else
                  return nil
              end
          else
              return nil
          end
    end,
     __tostring = function(object)
            local output = ""
            for i,v in fnutils.sortByKeys(object) do
                output = output..string.format("%-10s %-10s %s\n", i, "&#"..tostring(utf8.codepoint(v))..";", v)
            end
            return output
    end
})

-- Based on list located at http://www.freeformatter.com/html-entities.html
module.htmlEntities["&Aacute;"]    = utf8.codepointToUTF8(193)
module.htmlEntities["&aacute;"]    = utf8.codepointToUTF8(225)
module.htmlEntities["&Acirc;"]     = utf8.codepointToUTF8(194)
module.htmlEntities["&acirc;"]     = utf8.codepointToUTF8(226)
module.htmlEntities["&acute;"]     = utf8.codepointToUTF8(180)
module.htmlEntities["&AElig;"]     = utf8.codepointToUTF8(198)
module.htmlEntities["&aelig;"]     = utf8.codepointToUTF8(230)
module.htmlEntities["&Agrave;"]    = utf8.codepointToUTF8(192)
module.htmlEntities["&agrave;"]    = utf8.codepointToUTF8(224)
module.htmlEntities["&Alpha;"]     = utf8.codepointToUTF8(913)
module.htmlEntities["&alpha;"]     = utf8.codepointToUTF8(945)
module.htmlEntities["&amp;"]       = utf8.codepointToUTF8(38)
module.htmlEntities["&and;"]       = utf8.codepointToUTF8(8743)
module.htmlEntities["&ang;"]       = utf8.codepointToUTF8(8736)
module.htmlEntities["&Aring;"]     = utf8.codepointToUTF8(197)
module.htmlEntities["&aring;"]     = utf8.codepointToUTF8(229)
module.htmlEntities["&asymp;"]     = utf8.codepointToUTF8(8776)
module.htmlEntities["&Atilde;"]    = utf8.codepointToUTF8(195)
module.htmlEntities["&atilde;"]    = utf8.codepointToUTF8(227)
module.htmlEntities["&Auml;"]      = utf8.codepointToUTF8(196)
module.htmlEntities["&auml;"]      = utf8.codepointToUTF8(228)
module.htmlEntities["&bdquo;"]     = utf8.codepointToUTF8(8222)
module.htmlEntities["&Beta;"]      = utf8.codepointToUTF8(914)
module.htmlEntities["&beta;"]      = utf8.codepointToUTF8(946)
module.htmlEntities["&brvbar;"]    = utf8.codepointToUTF8(166)
module.htmlEntities["&bull;"]      = utf8.codepointToUTF8(8226)
module.htmlEntities["&cap;"]       = utf8.codepointToUTF8(8745)
module.htmlEntities["&Ccedil;"]    = utf8.codepointToUTF8(199)
module.htmlEntities["&ccedil;"]    = utf8.codepointToUTF8(231)
module.htmlEntities["&cedil;"]     = utf8.codepointToUTF8(184)
module.htmlEntities["&cent;"]      = utf8.codepointToUTF8(162)
module.htmlEntities["&Chi;"]       = utf8.codepointToUTF8(935)
module.htmlEntities["&chi;"]       = utf8.codepointToUTF8(967)
module.htmlEntities["&circ;"]      = utf8.codepointToUTF8(710)
module.htmlEntities["&clubs;"]     = utf8.codepointToUTF8(9827)
module.htmlEntities["&cong;"]      = utf8.codepointToUTF8(8773)
module.htmlEntities["&copy;"]      = utf8.codepointToUTF8(169)
module.htmlEntities["&crarr;"]     = utf8.codepointToUTF8(8629)
module.htmlEntities["&cup;"]       = utf8.codepointToUTF8(8746)
module.htmlEntities["&curren;"]    = utf8.codepointToUTF8(164)
module.htmlEntities["&dagger;"]    = utf8.codepointToUTF8(8224)
module.htmlEntities["&Dagger;"]    = utf8.codepointToUTF8(8225)
module.htmlEntities["&darr;"]      = utf8.codepointToUTF8(8595)
module.htmlEntities["&deg;"]       = utf8.codepointToUTF8(176)
module.htmlEntities["&Delta;"]     = utf8.codepointToUTF8(916)
module.htmlEntities["&delta;"]     = utf8.codepointToUTF8(948)
module.htmlEntities["&diams;"]     = utf8.codepointToUTF8(9830)
module.htmlEntities["&divide;"]    = utf8.codepointToUTF8(247)
module.htmlEntities["&Eacute;"]    = utf8.codepointToUTF8(201)
module.htmlEntities["&eacute;"]    = utf8.codepointToUTF8(233)
module.htmlEntities["&Ecirc;"]     = utf8.codepointToUTF8(202)
module.htmlEntities["&ecirc;"]     = utf8.codepointToUTF8(234)
module.htmlEntities["&Egrave;"]    = utf8.codepointToUTF8(200)
module.htmlEntities["&egrave;"]    = utf8.codepointToUTF8(232)
module.htmlEntities["&empty;"]     = utf8.codepointToUTF8(8709)
module.htmlEntities["&emsp;"]      = utf8.codepointToUTF8(8195)
module.htmlEntities["&ensp;"]      = utf8.codepointToUTF8(8194)
module.htmlEntities["&Epsilon;"]   = utf8.codepointToUTF8(917)
module.htmlEntities["&epsilon;"]   = utf8.codepointToUTF8(949)
module.htmlEntities["&equiv;"]     = utf8.codepointToUTF8(8801)
module.htmlEntities["&Eta;"]       = utf8.codepointToUTF8(919)
module.htmlEntities["&eta;"]       = utf8.codepointToUTF8(951)
module.htmlEntities["&ETH;"]       = utf8.codepointToUTF8(208)
module.htmlEntities["&eth;"]       = utf8.codepointToUTF8(240)
module.htmlEntities["&Euml;"]      = utf8.codepointToUTF8(203)
module.htmlEntities["&euml;"]      = utf8.codepointToUTF8(235)
module.htmlEntities["&euro;"]      = utf8.codepointToUTF8(8364)
module.htmlEntities["&exist;"]     = utf8.codepointToUTF8(8707)
module.htmlEntities["&fnof;"]      = utf8.codepointToUTF8(402)
module.htmlEntities["&forall;"]    = utf8.codepointToUTF8(8704)
module.htmlEntities["&frac12;"]    = utf8.codepointToUTF8(189)
module.htmlEntities["&frac14;"]    = utf8.codepointToUTF8(188)
module.htmlEntities["&frac34;"]    = utf8.codepointToUTF8(190)
module.htmlEntities["&Gamma;"]     = utf8.codepointToUTF8(915)
module.htmlEntities["&gamma;"]     = utf8.codepointToUTF8(947)
module.htmlEntities["&ge;"]        = utf8.codepointToUTF8(8805)
module.htmlEntities["&gt;"]        = utf8.codepointToUTF8(62)
module.htmlEntities["&harr;"]      = utf8.codepointToUTF8(8596)
module.htmlEntities["&hearts;"]    = utf8.codepointToUTF8(9829)
module.htmlEntities["&hellip;"]    = utf8.codepointToUTF8(8230)
module.htmlEntities["&Iacute;"]    = utf8.codepointToUTF8(205)
module.htmlEntities["&iacute;"]    = utf8.codepointToUTF8(237)
module.htmlEntities["&Icirc;"]     = utf8.codepointToUTF8(206)
module.htmlEntities["&icirc;"]     = utf8.codepointToUTF8(238)
module.htmlEntities["&iexcl;"]     = utf8.codepointToUTF8(161)
module.htmlEntities["&Igrave;"]    = utf8.codepointToUTF8(204)
module.htmlEntities["&igrave;"]    = utf8.codepointToUTF8(236)
module.htmlEntities["&infin;"]     = utf8.codepointToUTF8(8734)
module.htmlEntities["&int;"]       = utf8.codepointToUTF8(8747)
module.htmlEntities["&Iota;"]      = utf8.codepointToUTF8(921)
module.htmlEntities["&iota;"]      = utf8.codepointToUTF8(953)
module.htmlEntities["&iquest;"]    = utf8.codepointToUTF8(191)
module.htmlEntities["&isin;"]      = utf8.codepointToUTF8(8712)
module.htmlEntities["&Iuml;"]      = utf8.codepointToUTF8(207)
module.htmlEntities["&iuml;"]      = utf8.codepointToUTF8(239)
module.htmlEntities["&Kappa;"]     = utf8.codepointToUTF8(922)
module.htmlEntities["&kappa;"]     = utf8.codepointToUTF8(954)
module.htmlEntities["&Lambda;"]    = utf8.codepointToUTF8(923)
module.htmlEntities["&lambda;"]    = utf8.codepointToUTF8(955)
module.htmlEntities["&laquo;"]     = utf8.codepointToUTF8(171)
module.htmlEntities["&larr;"]      = utf8.codepointToUTF8(8592)
module.htmlEntities["&lceil;"]     = utf8.codepointToUTF8(8968)
module.htmlEntities["&ldquo;"]     = utf8.codepointToUTF8(8220)
module.htmlEntities["&le;"]        = utf8.codepointToUTF8(8804)
module.htmlEntities["&lfloor;"]    = utf8.codepointToUTF8(8970)
module.htmlEntities["&lowast;"]    = utf8.codepointToUTF8(8727)
module.htmlEntities["&loz;"]       = utf8.codepointToUTF8(9674)
module.htmlEntities["&lrm;"]       = utf8.codepointToUTF8(8206)
module.htmlEntities["&lsaquo;"]    = utf8.codepointToUTF8(8249)
module.htmlEntities["&lsquo;"]     = utf8.codepointToUTF8(8216)
module.htmlEntities["&lt;"]        = utf8.codepointToUTF8(60)
module.htmlEntities["&macr;"]      = utf8.codepointToUTF8(175)
module.htmlEntities["&mdash;"]     = utf8.codepointToUTF8(8212)
module.htmlEntities["&micro;"]     = utf8.codepointToUTF8(181)
module.htmlEntities["&middot;"]    = utf8.codepointToUTF8(183)
module.htmlEntities["&minus;"]     = utf8.codepointToUTF8(8722)
module.htmlEntities["&Mu;"]        = utf8.codepointToUTF8(924)
module.htmlEntities["&mu;"]        = utf8.codepointToUTF8(956)
module.htmlEntities["&nabla;"]     = utf8.codepointToUTF8(8711)
module.htmlEntities["&nbsp;"]      = utf8.codepointToUTF8(160)
module.htmlEntities["&ndash;"]     = utf8.codepointToUTF8(8211)
module.htmlEntities["&ne;"]        = utf8.codepointToUTF8(8800)
module.htmlEntities["&ni;"]        = utf8.codepointToUTF8(8715)
module.htmlEntities["&not;"]       = utf8.codepointToUTF8(172)
module.htmlEntities["&notin;"]     = utf8.codepointToUTF8(8713)
module.htmlEntities["&nsub;"]      = utf8.codepointToUTF8(8836)
module.htmlEntities["&Ntilde;"]    = utf8.codepointToUTF8(209)
module.htmlEntities["&ntilde;"]    = utf8.codepointToUTF8(241)
module.htmlEntities["&Nu;"]        = utf8.codepointToUTF8(925)
module.htmlEntities["&nu;"]        = utf8.codepointToUTF8(957)
module.htmlEntities["&Oacute;"]    = utf8.codepointToUTF8(211)
module.htmlEntities["&oacute;"]    = utf8.codepointToUTF8(243)
module.htmlEntities["&Ocirc;"]     = utf8.codepointToUTF8(212)
module.htmlEntities["&ocirc;"]     = utf8.codepointToUTF8(244)
module.htmlEntities["&OElig;"]     = utf8.codepointToUTF8(338)
module.htmlEntities["&oelig;"]     = utf8.codepointToUTF8(339)
module.htmlEntities["&Ograve;"]    = utf8.codepointToUTF8(210)
module.htmlEntities["&ograve;"]    = utf8.codepointToUTF8(242)
module.htmlEntities["&oline;"]     = utf8.codepointToUTF8(8254)
module.htmlEntities["&Omega;"]     = utf8.codepointToUTF8(937)
module.htmlEntities["&omega;"]     = utf8.codepointToUTF8(969)
module.htmlEntities["&Omicron;"]   = utf8.codepointToUTF8(927)
module.htmlEntities["&omicron;"]   = utf8.codepointToUTF8(959)
module.htmlEntities["&oplus;"]     = utf8.codepointToUTF8(8853)
module.htmlEntities["&or;"]        = utf8.codepointToUTF8(8744)
module.htmlEntities["&ordf;"]      = utf8.codepointToUTF8(170)
module.htmlEntities["&ordm;"]      = utf8.codepointToUTF8(186)
module.htmlEntities["&Oslash;"]    = utf8.codepointToUTF8(216)
module.htmlEntities["&oslash;"]    = utf8.codepointToUTF8(248)
module.htmlEntities["&Otilde;"]    = utf8.codepointToUTF8(213)
module.htmlEntities["&otilde;"]    = utf8.codepointToUTF8(245)
module.htmlEntities["&otimes;"]    = utf8.codepointToUTF8(8855)
module.htmlEntities["&Ouml;"]      = utf8.codepointToUTF8(214)
module.htmlEntities["&ouml;"]      = utf8.codepointToUTF8(246)
module.htmlEntities["&para;"]      = utf8.codepointToUTF8(182)
module.htmlEntities["&part;"]      = utf8.codepointToUTF8(8706)
module.htmlEntities["&permil;"]    = utf8.codepointToUTF8(8240)
module.htmlEntities["&perp;"]      = utf8.codepointToUTF8(8869)
module.htmlEntities["&Phi;"]       = utf8.codepointToUTF8(934)
module.htmlEntities["&phi;"]       = utf8.codepointToUTF8(966)
module.htmlEntities["&Pi;"]        = utf8.codepointToUTF8(928)
module.htmlEntities["&pi;"]        = utf8.codepointToUTF8(960)
module.htmlEntities["&piv;"]       = utf8.codepointToUTF8(982)
module.htmlEntities["&plusmn;"]    = utf8.codepointToUTF8(177)
module.htmlEntities["&pound;"]     = utf8.codepointToUTF8(163)
module.htmlEntities["&prime;"]     = utf8.codepointToUTF8(8242)
module.htmlEntities["&Prime;"]     = utf8.codepointToUTF8(8243)
module.htmlEntities["&prod;"]      = utf8.codepointToUTF8(8719)
module.htmlEntities["&prop;"]      = utf8.codepointToUTF8(8733)
module.htmlEntities["&Psi;"]       = utf8.codepointToUTF8(936)
module.htmlEntities["&psi;"]       = utf8.codepointToUTF8(968)
module.htmlEntities["&radic;"]     = utf8.codepointToUTF8(8730)
module.htmlEntities["&raquo;"]     = utf8.codepointToUTF8(187)
module.htmlEntities["&rarr;"]      = utf8.codepointToUTF8(8594)
module.htmlEntities["&rceil;"]     = utf8.codepointToUTF8(8969)
module.htmlEntities["&rdquo;"]     = utf8.codepointToUTF8(8221)
module.htmlEntities["&reg;"]       = utf8.codepointToUTF8(174)
module.htmlEntities["&rfloor;"]    = utf8.codepointToUTF8(8971)
module.htmlEntities["&Rho;"]       = utf8.codepointToUTF8(929)
module.htmlEntities["&rho;"]       = utf8.codepointToUTF8(961)
module.htmlEntities["&rlm;"]       = utf8.codepointToUTF8(8207)
module.htmlEntities["&rsaquo;"]    = utf8.codepointToUTF8(8249)
module.htmlEntities["&rsquo;"]     = utf8.codepointToUTF8(8217)
module.htmlEntities["&sbquo;"]     = utf8.codepointToUTF8(8218)
module.htmlEntities["&Scaron;"]    = utf8.codepointToUTF8(352)
module.htmlEntities["&scaron;"]    = utf8.codepointToUTF8(353)
module.htmlEntities["&sdot;"]      = utf8.codepointToUTF8(8901)
module.htmlEntities["&sect;"]      = utf8.codepointToUTF8(167)
module.htmlEntities["&shy;"]       = utf8.codepointToUTF8(173)
module.htmlEntities["&Sigma;"]     = utf8.codepointToUTF8(931)
module.htmlEntities["&sigma;"]     = utf8.codepointToUTF8(963)
module.htmlEntities["&sigma;"]     = utf8.codepointToUTF8(963)
module.htmlEntities["&sigmaf;"]    = utf8.codepointToUTF8(962)
module.htmlEntities["&sim;"]       = utf8.codepointToUTF8(8764)
module.htmlEntities["&spades;"]    = utf8.codepointToUTF8(9824)
module.htmlEntities["&sub;"]       = utf8.codepointToUTF8(8834)
module.htmlEntities["&sube;"]      = utf8.codepointToUTF8(8838)
module.htmlEntities["&sum;"]       = utf8.codepointToUTF8(8721)
module.htmlEntities["&sup;"]       = utf8.codepointToUTF8(8835)
module.htmlEntities["&sup1;"]      = utf8.codepointToUTF8(185)
module.htmlEntities["&sup2;"]      = utf8.codepointToUTF8(178)
module.htmlEntities["&sup3;"]      = utf8.codepointToUTF8(179)
module.htmlEntities["&supe;"]      = utf8.codepointToUTF8(8839)
module.htmlEntities["&szlig;"]     = utf8.codepointToUTF8(223)
module.htmlEntities["&Tau;"]       = utf8.codepointToUTF8(932)
module.htmlEntities["&tau;"]       = utf8.codepointToUTF8(964)
module.htmlEntities["&there4;"]    = utf8.codepointToUTF8(8756)
module.htmlEntities["&Theta;"]     = utf8.codepointToUTF8(920)
module.htmlEntities["&theta;"]     = utf8.codepointToUTF8(952)
module.htmlEntities["&thetasym;"]  = utf8.codepointToUTF8(977)
module.htmlEntities["&thinsp;"]    = utf8.codepointToUTF8(8201)
module.htmlEntities["&THORN;"]     = utf8.codepointToUTF8(222)
module.htmlEntities["&thorn;"]     = utf8.codepointToUTF8(254)
module.htmlEntities["&tilde;"]     = utf8.codepointToUTF8(732)
module.htmlEntities["&times;"]     = utf8.codepointToUTF8(215)
module.htmlEntities["&trade;"]     = utf8.codepointToUTF8(8482)
module.htmlEntities["&Uacute;"]    = utf8.codepointToUTF8(218)
module.htmlEntities["&uacute;"]    = utf8.codepointToUTF8(250)
module.htmlEntities["&uarr;"]      = utf8.codepointToUTF8(8593)
module.htmlEntities["&Ucirc;"]     = utf8.codepointToUTF8(219)
module.htmlEntities["&ucirc;"]     = utf8.codepointToUTF8(251)
module.htmlEntities["&Ugrave;"]    = utf8.codepointToUTF8(217)
module.htmlEntities["&ugrave;"]    = utf8.codepointToUTF8(249)
module.htmlEntities["&uml;"]       = utf8.codepointToUTF8(168)
module.htmlEntities["&upsih;"]     = utf8.codepointToUTF8(978)
module.htmlEntities["&Upsilon;"]   = utf8.codepointToUTF8(933)
module.htmlEntities["&upsilon;"]   = utf8.codepointToUTF8(965)
module.htmlEntities["&Uuml;"]      = utf8.codepointToUTF8(220)
module.htmlEntities["&uuml;"]      = utf8.codepointToUTF8(252)
module.htmlEntities["&Xi;"]        = utf8.codepointToUTF8(926)
module.htmlEntities["&xi;"]        = utf8.codepointToUTF8(958)
module.htmlEntities["&Yacute;"]    = utf8.codepointToUTF8(221)
module.htmlEntities["&yacute;"]    = utf8.codepointToUTF8(253)
module.htmlEntities["&yen;"]       = utf8.codepointToUTF8(165)
module.htmlEntities["&yuml;"]      = utf8.codepointToUTF8(255)
module.htmlEntities["&Yuml;"]      = utf8.codepointToUTF8(376)
module.htmlEntities["&Zeta;"]      = utf8.codepointToUTF8(918)
module.htmlEntities["&zeta;"]      = utf8.codepointToUTF8(950)
module.htmlEntities["&zwj;"]       = utf8.codepointToUTF8(8205)
module.htmlEntities["&zwnj;"]      = utf8.codepointToUTF8(8204)

module.convertHtmlEntities = function(input)
    return input:gsub("&[^;]+;", function(c) return module.htmlEntities[c] or c end)
end

-- Also need way to convert in string while preserving UTF8
-- option to skip converting cr,lf,tab? yes in string one... in char one too?

module.visibleCtrlChar = function(char)
    if type(char) == "number" and char < 32 then char = string.char(char) end
    if type(char) ~= "string" or char:len() ~= 1 or char:byte() > 31 then
        return char
    else
        return utf8.codepointToUTF8(char:byte() + 0x2400)
    end
end

--- {PATH}.{MODULE}.hexDump(string [, count]) -> string
--- Function
--- Treats the input string as a binary blob and returns a prettied up hex dump of it's contents. By default, a newline character is inserted after every 16 bytes, though this can be changed by also providing the optional count argument.  This is useful with the results of `{PATH}.{MODULE}.userDataToString` or `string.dump` for debugging and the curious, and may also provide some help with troubleshooting utf8 data that is being mis-handled or corrupted.
module.hexDump = function(stuff, linemax)
    local ascii = ""
    local count = 0
    local linemax = tonumber(linemax) or 16
    local buffer = ""
    local rb = ""
    local offset = math.floor(math.log(#stuff,16)) + 1
    offset = offset + (offset % 2)

    local formatstr = "%0"..tostring(offset).."x : %-"..tostring(linemax * 3).."s : %s"

    for c in string.gmatch(tostring(stuff), ".") do
        buffer = buffer..string.format("%02X ",string.byte(c))
        -- using string.gsub(c,"%c",".") didn't work in Hydra, but I didn't dig any deeper -- this works.
        if string.byte(c) < 32 or string.byte(c) > 126 then
            ascii = ascii.."."
        else
            ascii = ascii..c
        end
        count = count + 1
        if count % linemax == 0 then
            rb = rb .. string.format(formatstr, count - linemax, buffer, ascii) .. "\n"
            buffer=""
            ascii=""
        end
    end
    if count % linemax ~= 0 then
        rb = rb .. string.format(formatstr, count - (count % linemax), buffer, ascii) .. "\n"
    end
    return rb
end

--- {PATH}.{MODULE}.asciiOnly(string[, all]) -> string
--- Function
--- Returns the provided string with all non-printable ascii characters (except for Return, Linefeed, and Tab unless `all` is provided and is true) escaped as \x## so that it can be safely printed in the {TARGET} console, rather than result in an uninformative '(null)'.  Note that this will break up Unicode characters into their individual bytes.
function module.asciiOnly(theString, all)
    local all = all or false
    if type(theString) == "string" then
        if all then
            return (theString:gsub("[\x00-\x1f\x7f-\xff]",function(a)
                    return string.format("\\x%02X",string.byte(a))
                end))
        else
            return (theString:gsub("[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]",function(a)
                    return string.format("\\x%02X",string.byte(a))
                end))
        end
    else
        error("string expected", 2) ;
    end
end

return module