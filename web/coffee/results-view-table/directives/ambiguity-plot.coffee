# cluster-plot.coffee
# A directive using HighCharts to render clustered bubble plots about
# (MS1 Score, Mass) Observation Ambiguity
#
# Depends upon LoDash.js and Highcharts.js
#
angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").directive "ambiguityPlot", ["$window",  ($window) ->

    scalingDownFn = (value) -> Math.log(value)
    scalingUpFn = (value) -> Math.exp(value)

    # Injects the directive scope into the Highcharts.Chart instance's callbacks
    ambiguityPlotTemplater = (scope, seriesData, xAxisTitle, yAxisTitle, plotType = 'bubble') ->
        # Very small number for zooming to
        infitesimal = 1/(Math.pow(1000, 1000))
        ambiguityPlotTemplateImpl = {
            chart: {
                height: $window.innerHeight * 0.6
                type: plotType
                zoomType: 'xy'
            }
            plotOptions: {
                series: {
                    point: {
                        events: {
                            click: (evt) ->
                                point = this
                                chart = @series.chart
                                xs = _.pluck(@series.points, "x")
                                ys = _.pluck(@series.points, "y")
                                # Publish this data to the directive scope for use elsewhere
                                scope.$apply(() ->
                                    scope.describedPredictions = _.pluck(point.series.points, "data")
                                    )
                                chart.xAxis[0].setExtremes(Math.min.apply(null, xs) * (1 - infitesimal), Math.max.apply(null, xs) * (1 + infitesimal))
                                chart.yAxis[0].setExtremes(Math.min.apply(null, ys) * (1 - infitesimal), Math.max.apply(null, ys) * (1 + infitesimal))
                                chart.showResetZoom()
                        } # Close events
                    } # Close point
                states: {
                        hover: false
                    }
                } # Close series
            } # Close plotOptions
            legend: {
                title: {
                    text: "<b>Legend</b> <small>(click series to hide)</small>"
                }
                align: 'right',
                verticalAlign: 'top',
                y: 60
                width: 200
                height: $window.innerHeight * .8
            },
            tooltip: {
                formatter: () ->
                    point = this.point
                    contents = "#{point.titles.x}: <b>#{point.x}</b><br/>"
                    contents += "#{point.titles.z}: <b>#{point.z}</b><br/>" if point.titles.z != "None" and point.titles.z?
                    contents += "#{point.titles.y}: <b>#{point.y}</b><br/>" if point.titles.y != "" and point.titles.y?
                    contents += "Number of Matches: <b>#{point.series.data.length}</b><br/>"
                    return contents
                headerFormat: "<span style=\"color:{series.color}\">●</span> {series.name}</span><br/>"
                # Leading space is required to align the first character of each row.

                positioner: (boxWidth, boxHeight, point) ->
                    ttAnchor = {x: point.plotX, y: point.plotY}
                    ttAnchor.x -= (boxWidth * 1)
                    if ttAnchor.x <= 0
                        ttAnchor.x += 2 * (boxWidth * 1)
                    return ttAnchor

            }
            title: {
                text: "Ambiguous Groups Plot"
            }
            xAxis: {
                title: {
                    text: xAxisTitle
                }
                events: {

                }
            }
            yAxis: {
                title: {
                    text: yAxisTitle
                }
            }
            series: seriesData
        } # Close template

    # Create a new plot function on the fly based on bound form data
    genericGroupingFn = (xAxis, yAxis, zAxis, groupingName = "") ->
        if groupingName is ""
            groupingName = xAxis.name
            groupingName += "/" + zAxis.name if zAxis.name? and zAxis.name != ""
        # Allow axis definitions to be functions or attributes
        xAxisGetter = (p) -> p[xAxis.getter]
        if typeof(xAxis.getter) is "function"
            xAxisGetter = (p) -> xAxis.getter(p)
        yAxisGetter = (p) -> p[yAxis.getter]
        if typeof(yAxis.getter) is "function"
            yAxisGetter = (p) -> yAxis.getter(p)
        zAxisGetter = (p) -> p[zAxis.getter]
        if typeof(zAxis.getter) is "function"
            zAxisGetter = (p) -> zAxis.getter(p)
        fn = (predictions) ->
            ionPoints = ({x: xAxisGetter(p), y: yAxisGetter(p), z:zAxisGetter(p), data: p, titles:{x:xAxis.name, y:yAxis.name, z:zAxis.name}} for p in predictions)
            ionGroupings = _.groupBy ionPoints, (pred) ->
                xVal = pred.x
                if typeof(xVal) is "number" and not Number.isInteger(xVal)
                    xVal = xVal.toFixed(3)
                zVal = pred.z
                if typeof(zVal) is "number" and not Number.isInteger(zVal)
                    zVal = zVal.toFixed(3)
                groupId = xVal
                groupId += '-' + zVal if zVal?
                return groupId
            ionSeries = []
            notAmbiguous = []
            _.forEach ionGroupings, (group, id) ->
                if group.length == 1
                    notAmbiguous.push {data: group, name: groupingName + " " + id}
                else
                    ionSeries.push {data: group, name: groupingName + " " + id}
            return {ionSeries: ionSeries, notAmbiguous: notAmbiguous}
        return fn


    # Re-render the plot with new data
    updatePlot = (predictions, scope, element) ->
        # Get grouping configuration bound from UI
        groupParams = scope.grouping.groupingFnKey

        # Generate grouped series data
        scope.seriesData = groupParams.groupingFn(predictions)

        scope.describedPredictions = []
        {ionSeries, notAmbiguous} = scope.seriesData
        if not scope.ambiguityPlotParams.hideUnambiguous
            ionSeries = ionSeries.concat(notAmbiguous)
        # Initialize the plot template object, passing grouping labels
        plotOptions = ambiguityPlotTemplater(scope, ionSeries, xAxisTitle=groupParams.xAxisTitle,
            yAxisTitle=groupParams.yAxisTitle, plotType=groupParams.plotType)
        # Render the plot
        chart = element.find(".ambiguity-plot-container")
        chart.highcharts(plotOptions)
        return true

    return {
            restrict: "AE"
            scope: {
                predictions: '='
                headerSubstituitionDictionary: '=headers'
            }
            templateUrl: "templates/ambiguity-plot-template.html"
            link: (scope, element, attr) ->
                $window.PLOTTING = scope
                scope.describedPredictions = []
                scope.describedMS2Min = 0
                scope.describedMS2Max = 0
                scope.grouping = {}
                # The built-in plotting functions
                scope.grouping.groupingsOptions = {
                    "MS1 Score + Mass": {
                        groupingFn: genericGroupingFn(
                            {name: "MS1 Score", getter: "MS1_Score"}
                            {name: "MS2 Score", getter: "MS2_Score"}
                            {name: "Observed Mass", getter: "Obs_Mass"}
                            )
                        xAxisTitle: "MS1 Score"
                        yAxisTitle: "MS2 Score"
                        plotType: 'bubble'
                    }
                    "Start AA + Length": {
                        groupingFn: genericGroupingFn(
                                {name: "Start AA", getter: "startAA"}
                                {name: "MS2 Score", getter: "MS2_Score"}
                                {name: "Peptide Length", getter: "peptideLens"}
                            )
                        xAxisTitle: "Peptide Start Position"
                        yAxisTitle: "MS2 Score"
                        plotType: 'bubble'
                    }
                    "Scan Time": {
                        groupingFn: genericGroupingFn(
                                {name: 'Starting Scan', getter: "scan_id"}
                                {name: 'Mean Peptide Coverage', getter: 'meanCoverage'}
                                {name: 'None', getter: (p) -> null}
                            )
                        xAxisTitle: 'Scan Number'
                        yAxisTitle: 'Mean Peptide Coverage'
                        plotType: 'scatter'
                    }
                }
                scope._ = _ # let lodash be used in expressions
                scope.keys = Object.keys
                scope.grouping.groupingFnKey = scope.grouping.groupingsOptions["MS1 Score + Mass"]
                scope.ambiguityPlotParams = {
                    showCustomPlotter: false
                    x: "Scan ID"
                    y: "MS2 Score"
                    z: "None"
                    hideUnambiguous: true
                }
                scope.describedPeptideRegions = ->
                    Object.keys(_.groupBy(scope.describedPredictions, (p) -> p.startAA + '-' + p.endAA)).join('; ')
                scope.plotSelectorChanged = ->
                    updatePlot(scope.predictions, scope, element)
                    return true

                # Generate a new plotting function on the fly from bound form data
                scope.customPlot = ->
                    x = scope.ambiguityPlotParams.x
                    y = scope.ambiguityPlotParams.y
                    z = scope.ambiguityPlotParams.z
                    groupingParams = {
                        groupingFn: genericGroupingFn(
                                {name: x, getter: scope.headerSubstituitionDictionary[x.toLowerCase()]}
                                {name: y, getter: scope.headerSubstituitionDictionary[y.toLowerCase()]}
                                {name: z, getter: scope.headerSubstituitionDictionary[z.toLowerCase()]}
                            )
                        xAxisTitle: x
                        yAxisTitle: y
                        plotType: "bubble"
                    }
                    groupingParams.plotType = "scatter" if z is "None"
                    scope.grouping.groupingsOptions["Custom"] = groupingParams
                    scope.grouping.groupingFnKey = groupingParams
                    updatePlot(scope.predictions, scope, element)
                    return true

                angular.element($window).bind 'resize', ->
                    try
                        chart = element.find(".ambiguity-plot-container").highcharts()
                        chart.setSize($window.innerWidth, $window.innerHeight * 0.6)

                scope.$watch("describedPredictions", (newVal) ->
                        scoreRange = _.pluck(scope.describedPredictions, 'MS2_Score')
                        scope.describedMS2Min = Math.min.apply(null, scoreRange)
                        scope.describedMS2Max = Math.max.apply(null, scoreRange)
                        scope.$emit("selectedPredictions", {selectedPredictions: scope.describedPredictions})
                    )
                scope.$on "ambiguityPlot.renderPlot", (evt, params)->
                    updatePlot(scope.predictions, scope, element)
                # scope.$watch("predictions", ()-> updatePlot(scope.predictions, scope, element))
                scope.$watch('ambiguityPlotParams.hideUnambiguous', (newVal, oldVal) ->
                        updatePlot(scope.predictions, scope, element)
                    )

            }
]
