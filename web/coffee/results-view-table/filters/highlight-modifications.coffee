# highlight-modifications.coffee
# A filter to parse the Glycopeptide_identifier string and mark up the modification sites
# and visually separate the glycan composition tuple.

angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").filter "highlightModifications",[
    "colorService", "$sce", (colorService, $sce) ->
        return (input = '', sce=true) ->
            out = ""
            regex = /(\(.+?\)|\[.+?\])/
            fragments = input.split(regex)
            for frag in fragments
                if frag.charAt(0) is "(" # Then we are dealing with a modification
                    modName = frag.replace(/\(|\)/g,"")
                    out += "<span class='mod-string' style='color:#{colorService.getColor(modName)}'>#{frag}</span>"
                else if frag.charAt(0) is "["
                    out += " <b>#{frag}</b>"
                else
                    out += frag
            # Trust the content as Html with inline style if the target
            # will be an Angular binding which will strip out inline style
            # and may escape Html.
            out = $sce.trustAsHtml(out) if sce
            return out
]

