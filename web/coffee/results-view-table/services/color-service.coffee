# color-service.coffee
# Extracts the logic of associating a name with a color
class ColorSourceFactory
        colors: ["blue",
                  "#99CC00"#"rgb(228, 211, 84)",
                  "red", "purple", "grey", "black", "green", "orange", "brown"]
        pepColors: ["seagreen","mediumseagreen", "green", "limegreen", "darkgreen"]

        colorIters: {
            "_colorIter": 0,
            "_pepColorIter": 0,
        }

        colorMapDefault: {
            modColorMap: {
                HexNAc: "#CC3300"#"#CC99FF"
            }
            pepColorMap: {

            }
        }

        colorMap: {
            modColorMap: {
                HexNAc: "#CC3300" #"#CC99FF"
            }
            pepColorMap: {

            }
        }

        resetMap: (key) => @colorMap[key] = _.cloneDeep(@colorMapDefault[key])

        _nextColor: ->
           color = @colors[@colorIters["_colorIter"]++]
           if @colorIters["_colorIter"] >= @colors.length
               @colorIters["_colorIter"] = 0
           return color

        _nextPepColor: ->
           color = @pepColors[@colorIters["_pepColorIter"]++]
           if @colorIters["_pepColorIter"] >= @pepColors.length
               @colorIters["_pepColorIter"] = 0
           return color


        getColor: (label) =>
           if label not of @colorMap.modColorMap
               @colorMap.modColorMap[label] = @_nextColor()
           return @colorMap.modColorMap[label]

        getPepColor: (label) =>
           if label not of @colorMap.pepColorMap
               @colorMap.pepColorMap[label] = @_nextPepColor()
           return @colorMap.pepColorMap[label]

        resetPepColors: => @resetMap("pepColorMap")

ColorSource = new ColorSourceFactory()

angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").factory "colorService", [() -> ColorSource]