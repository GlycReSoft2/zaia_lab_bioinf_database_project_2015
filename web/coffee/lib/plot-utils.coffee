class PlotUtils
    @window: window
    @addAlphaToRGB = (rgb, alpha) ->
        return "rgba(#{rgb.r}, #{rgb.g}, #{rgb.b}, #{alpha})"

    @getWindowSize = ()->
        {
            height: @window.innerHeight
            width: @window.innerWidth
        }


class PlotUtils.BackboneStackChart
        @template: () ->
            reference = _.cloneDeep {
                chart:
                    type: "columnrange"
                    inverted: true
                    height: PlotUtils.getWindowSize().height * 0.7
                title:
                    text: "Peptide Backbone Fragment Coverage"
                xAxis:[
                    {
                        title:
                            text: "Sequence Position"
                        allowDecimals: false
                    }
                ]
                yAxis:
                    {
                        title:
                            text: "Backbone Fragmentation Site"
                        allowDecimals: false
                        min: 0
                        max: null
                    }
                plotOptions:
                    columnrange:
                        animation: false
                        groupPadding: 0

                legend:
                    enabled: true
                series: []
            }
        constructor: (@glycopeptide, @container) ->
            @backboneStack = GlycopeptideLib.buildBackboneStack(@glycopeptide)
            @config = BackboneStackChart.template()
            @config.yAxis.max = @glycopeptide.peptideLens
            @config.series.push {
                name: "b Ion",
                data: _.pluck(@backboneStack, "bIon")
                            }
            @config.series.push {
                name: "y Ion",
                data: _.pluck(@backboneStack, "yIon")
                            }
            @config.series.push {
                name: "b Ion + HexNAc",
                data: _.pluck(@backboneStack, "bHexNAc")
                            }
            @config.series.push {
                name: "y Ion + HexNAc",
                data: _.pluck(@backboneStack, "yHexNAc")
                            }
            @addModificationBars()

        addModificationBars: ->
            modificationSites = GlycopeptideLib.parseModificationSites(@glycopeptide)
            for mod in modificationSites
                @config.series.push {
                    name: "#{mod.name}-#{mod.position}"
                    data:([i, mod.position] for i in [0..@glycopeptide.peptideLens])
                    type: "scatter"
                    color: PlotUtils.addAlphaToRGB(new RGBColor(ColorSource.getColor(mod.name)), .65)
                    marker:
                        radius: 4
                        symbol: "circle"
                }


        render: ->
            @chart = $(@container).highcharts(@config)
            @


class PlotUtils.ModificationDistributionChart

        constructor: (@predictions, @container) ->

        render: ->
            @chart = $(@container).highcharts(@config)
            @
