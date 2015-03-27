# protein-sequence-view.coffee
# Not an Angular View
#
# Render a Biojs.FeatureViewer that is decorated with peptide fragment matches
# Depends upon
# lodash
# Biojs
# Biojs.FeatureViewer - Modified to add Raphael.Element.node.id to Raphael.Element.id to make lookup faster
# raphael - The version of Raphael that Biojs bundles is old, and doesn't have Paper.getById.
# canvg
# rgbcolor
# jquery
# jquery.tooltip
# jquery.ui


angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").directive "proteinSequenceView", ["$window", "$filter",
"colorService", "$modal", "$timeout", ($window, $filter, colorService, $modal, $timeout) ->
        $window.modal = $modal
        orderBy = $filter("orderBy")
        $window.orderBy = orderBy
        highlightModifications = $filter("highlightModifications")

        _shapeIter = 0
        shapes = ["diamond", "triangle", "hexagon","wave", "circle"]

        # Default object settings for each feature.
        # Overriden as needed during construction
        featureTemplate = {
            nonOverlappingStyle: {
                heightOrRadius: 10
                y: 140
            }

            centeredStyle: {
                heightOrRadius: 48
                y: 71
            }

            rowStyle: {
                heightOrRadius: 10
                y: 181
            }

            text: ""
            type: "rect" # shape string
            fill: "#CDBCF6" # color string
            stroke: "#CDBCF6" # color string
            fillOpacity: 0.5
            height: 10
            evidenceText: ":"
            evidenceCode: "MS2 Score"
            typeCategory: "typeCategory"
            typeCode: "typeCode"
            path: "" # ?
            typeLabel: "" # May connect with featureLabel
            featureLabel: ""
            featureStart: null # number
            featureEnd: null # number
            strokeWidth: 0.6 # number
            r: 10 # number

            featureTypeLabel: "" # string related to featureLabel and typeLabel
        }

        # Currently un-used
        legendKeyTemplate ={
            label: {
              total: 1,
              yPosCentered: 210,
              text: "Domain",
              yPos: 234,
              xPos: 50,
              yPosNonOverlapping: 234,
              yPosRows: 310
            },
            shape: {
              centeredStyle: {
                heightOrRadius: 5,
                y: 208
              },
              text: "",
              nonOverlappingStyle: {
                heightOrRadius: 5,
                y: 229
              },
              width: 30,
              fill: "#033158",
              cy: 229,
              cx: 15,
              type: "rect",
              fillOpacity: 0.5,
              stroke: "#033158",
              height: 5,
              r: 10,
              path: "",
              rowsStyle: {
                heightOrRadius: 5,
                y: 305
              },
              typeLabel: "",
              y: 229,
              strokeWidth: 0.6,
              x: 15
            }
        }

        collapseGlycanShape = "circle"
        shapeMap = {
            Peptide: "rect"
            HexNAc: "text"
            PTM: "triangle"
        }

        typeCategoryMap = {
            "HexNAc": "Glycan"

        }

        _layerCounter = 0
        _layerIncrement = 15
        heightLayerMap = {
        }

        # $window-dependent Biojs.FeatureViewer config generation function
        generateConfig = ($window) ->
            configuration = {
                aboveRuler: 10
                belowRuler: 30
                requestedStop: 770,
                horizontalGridNumLines: 11,
                sequenceLineYCentered: 95,
                requestedStart: 1,
                gridLineHeight: 12,
                rightMargin: 20,
                sequenceLength: 770,
                horizontalGridNumLinesNonOverlapping: 11,
                horizontalGridNumLinesCentered: 6,
                verticalGridLineLengthRows: 284,
                unitSize: 0.8571428571428571,
                sizeYNonOverlapping: 184,
                style: "nonOverlapping",
                sequenceLineYRows: 155,
                sequenceLineY: 138,
                verticalGrid: false,
                rulerY: 20,
                dasSources: null,
                horizontalGrid: false,
                pixelsDivision: 50,
                sizeY: $window.innerHeight * 3.0,
                sizeX: $window.innerWidth * .95,
                dasReference: null,
                sizeYRows: 260,
                rulerLength: $window.innerWidth * .8,
                verticalGridLineLengthNonOverlapping: 174,
                sizeYKey: 210,
                sizeYCentered: 160,
                sequenceLineYNonOverlapping: 138,
                verticalGridLineLength: 174,
                horizontalGridNumLinesRows: 8,
                leftMargin: 20,
                nonOverlapping: true,
                verticalGridLineLengthCentered: 172
            }
            return configuration

        # Stub awaiting the day I write a legend
        transformFeatuersToLegend = (featuresArray) ->
            return []

        # Given a set of modifications at the same site, return the best score
        # for that site.
        getBestScoresForModification = (modifications, features) ->
            foldedMods = _.groupBy(modifications, "featureId")
            topMods = []

            for modId, mod of foldedMods
                ordMods = (orderBy(mod, ((obj) -> obj._obj.MS2_Score), true))
                bestMod = ordMods[0]
                colocatingFeatures = fragmentsSurroundingPosition(bestMod.featureStart, features)
                [frequencyOfModification, containingFragments] = fragmentsContainingModification(bestMod, colocatingFeatures)

                bestMod.statistics = {
                    meanScore: _.pluck(ordMods, ((obj)-> obj._obj.MS2_Score)).mean()
                    frequency: frequencyOfModification
                }
                bestMod.additionalTooltipContent =
                    "<br/>Mean Score: #{bestMod.statistics.meanScore.toFixed(3)}
                    <br/>Frequency of Feature: #{(bestMod.statistics.frequency * 100).toFixed(2)}%"

                if typeCategoryMap[bestMod.featureTypeLabel] is "Glycan"
                    makeGlycanCompositionContent(bestMod, containingFragments)

                if /HexNAc/.test modId
                    bestMod.type = "circle"
                    bestMod.r /= 2

                topMods.push(bestMod)
            return topMods

        # Obtain the set of fragments spanning a position
        fragmentsSurroundingPosition = (position, fragments) ->
            fragRanges = _.groupBy(fragments, ((frag) -> [frag.featureStart, frag.featureEnd]))
            results = []
            for range, fragments of fragRanges
                [start, end] = range.split(',')
                if position >= start and position <= end
                    results = results.concat(fragments)
            return results

        # Obtain the set of fragments containing this modification
        fragmentsContainingModification = (modification, fragments) ->
            count = 0
            containingFragments = []
            for frag in fragments
                if modification.featureId in frag.modifications
                    count++
                    containingFragments.push frag
            return [count/fragments.length, containingFragments]


        # Compile the additional content displayed on the Glycan attachment symbol
        makeGlycanCompositionContent = (bestMod, containingFragments) ->
            bestMod.hasModalContent = true
            glycanMap = {}
            for frag in containingFragments
                if not (frag._obj.Glycan of glycanMap)
                    glycanMap[frag._obj.Glycan] = 0
                glycanMap[frag._obj.Glycan]++
            bestMod.statistics.glycanMap = {}

            bestMod.additionalTooltipContent += "</br><b>Click to see Glycan Composition distribution</b>"

            glycanCompositionContent = "<div class='frequency-plot-container'></div>
            <table class='table table-striped table-compact centered glycan-composition-frequency-table'>
            <tr>
                <th>Glycan Composition</th><th>Frequency(%)</th>
            </tr>"
            for composition, frequency of glycanMap
                frequency = (frequency/containingFragments.length)
                bestMod.statistics.glycanMap[composition] = frequency
                glycanCompositionContent += "<tr>
                    <td>#{composition}</td><td>#{(frequency * 100).toFixed(2)}</td>
                </tr>"
            glycanCompositionContent += "</table>"
            bestMod.modalOptions = {
                title: "Glycan Composition: " + bestMod.featureId
                summary: glycanCompositionContent
                items: []
                postLoadFn: () ->
                    # Create the frequency histogram of glycan compositions at this site
                    $('.frequency-plot-container').highcharts({
                        data: {
                            table: $('.glycan-composition-frequency-table')[0]
                        },
                        chart: {
                            type: 'column'
                        }

                        title: {
                            text: 'Glycan Composition Frequency'
                        },
                        yAxis: {
                            allowDecimals: false,
                            title: {
                                text: 'Frequency (%)'
                            }
                        }
                        xAxis: {
                            type: 'category',
                            labels: {
                                rotation: -45,
                            }
                        },
                        tooltip: {
                            pointFormat: '<b>{point.y}%</b> Frequency'
                        }
                        legend: {
                            enabled: false
                        }
                    })
            }

        # Generate the backbone fragment plot for the clicked glycopeptide
        coverageModalHistogram = (glycoform) ->
            glycoform.hasModalContent = true
            glycoform.modalOptions = {
                title: "Peptide Coverage"
                summary: "<div class='frequency-plot-container'></div>"
                items: []
                postLoadFn: () ->
                    $(".modal-dialog").css {width: "85%", height: "95%"}
                    new PlotUtils.BackboneStackChart(glycoform._obj, ".frequency-plot-container").render()
            }

        # Parses the glycopeptide's Glycan_identifier string into `feature` objects
        # based on the template above. Each `feature` has its location-related information
        # set relative to `startSite`
        parseGlycopeptideIdentifierToModificationsArray = (glycoform, startSite) ->
            glycopeptide = glycoform.Glycopeptide_identifier
            regex = /(\(.+?\)|\[.+?\])/
            index = 0
            fragments = glycopeptide.split(regex)
            modifications = []
            glycanComposition = null
            glycans = []
            for frag in fragments
                if frag.charAt(0) is "["
                    glycanComposition = frag
                else if frag.charAt(0) is "("
                    # This is a modification site
                    label = frag.replace(/\(|\)/g, "")
                    feature = _.cloneDeep(featureTemplate)
                    feature.type = if label of shapeMap then shapeMap[label] else shapeMap.PTM

                    feature.fill = colorService.getColor(label)
                    feature.stroke = colorService.getColor(label)

                    feature.featureStart = index + startSite
                    feature.featureEnd = index + startSite
                    feature.typeLabel = ""
                    feature.typeCode = ""
                    feature.typeCategory  = ""
                    feature.evidenceText = glycoform.MS2_Score

                    feature.text = label
                    feature.featureLabel = label
                    feature.featureTypeLabel = label
                    feature.featureId = label + "-" + (index + startSite) # Parens prevent string addition



                    if label not of heightLayerMap
                        _layerCounter += _layerIncrement
                        heightLayerMap[label] = _layerCounter

                    feature.cy = 140 - ((feature.r) + heightLayerMap[label])
                    if feature.type == "text"
                        feature.y = 140 - ((feature.r) + heightLayerMap[label])
                        feature.fontSize = 12
                        feature.letterSpacing = 2
                        feature.strokeWidth = 1
                    feature._obj = glycoform
                    if label != "HexNAc"
                        modifications.push feature

                    # Handle glycans separately
                    else
                        glycans.push feature
                else
                    index += frag.length

            # Customize glycan layout
            withinLayerAdjust = -10
            for feature in glycans
                feature.text = glycanComposition
                feature.y += withinLayerAdjust + 10
                withinLayerAdjust += 10
                feature.cx += 50
                modifications.push feature


            return modifications

        # Gathers glycopeptide predictions by their location on the parent protein
        # and converts each glycopeptide into a `feature` object based on the template
        # above.
        transformPredictionGroupsToFeatures = (predictions) ->
            fragments = _.groupBy(predictions, (p) -> [p.startAA, p.endAA])

            featuresArray = []
            modifications = []

            sortFn = (a, b) ->
                [aStart, aEnd] = a.split(',')
                [bStart, bEnd] = b.split(',')
                aLen = aEnd-aStart
                bLen = bEnd-bStart
                if(aLen > bLen)
                    return -1
                else if (aLen < bLen)
                    return 1
                else return 0

            arrange = Object.keys(fragments).sort(sortFn)
            colorIter = 0

            for fragRange in arrange
                [start, end] = fragRange.split(",")

                frag = fragments[fragRange]
                depth = 1

                # Sort each fragment group by descending MS2 Score
                frag = orderBy(frag, "MS2_Score").reverse()

                for glycoform in frag
                    feature = _.cloneDeep featureTemplate
                    feature.type = shapeMap.Peptide
                    feature.fill = colorService.getPepColor("Peptide" + ((glycoform.scan_id) ))
                    feature.stroke = colorService.getPepColor("Peptide" + ((glycoform.scan_id) ))
                    feature.featureStart = glycoform.startAA
                    feature.featureEnd = glycoform.endAA
                    feature.text = glycoform.Glycopeptide_identifier

                    feature.typeLabel = "Peptide"
                    feature.typeCode = ""
                    feature.typeCategory = ""
                    feature.featureTypeLabel = "glycopeptide_match"
                    feature.evidenceText = glycoform.MS2_Score
                    # The featureId property is used as a CSS class, so make it CSS friendly
                    feature.featureId = glycoform.Glycopeptide_identifier.replace(/\[|\]|;|\(|\)/g, "-")
                    feature.y = depth * (feature.height + 2 * feature.strokeWidth) + 125

                    # Generate a collection of `feature` objects from modifications on this glycopeptide
                    glycoformModifications = parseGlycopeptideIdentifierToModificationsArray(glycoform, glycoform.startAA)
                    modifications = modifications.concat(glycoformModifications)
                    feature.modifications = _.pluck(glycoformModifications, "featureId")
                    feature._obj = glycoform

                    # Wait until after the modifications have been processed and registered in colorService
                    feature.featureLabel = highlightModifications(glycoform.Glycopeptide_identifier, false)
                    feature.additionalTooltipContent = "<br/>Scan ID: #{glycoform.scan_id}<br/>Mass: #{glycoform.Obs_Mass}<br/>Feature ID: #{glycoform.id}"
                    coverageModalHistogram(feature)
                    featuresArray.push feature

                    depth++
                colorIter++

            foldedMods = _.pluck(_.groupBy(modifications, "featureId"), (obj) -> obj[0])
            topMods = getBestScoresForModification(modifications, featuresArray)
            featuresArray = featuresArray.concat(topMods)

            return featuresArray

        # Update the current state of the widget when new data arrives
        updateView = (scope, element) ->
            scope.start = Math.min.apply(null, _.pluck(scope.predictions, "startAA"))
            scope.end = Math.max.apply(null, _.pluck(scope.predictions, "endAA"))
            colorService.resetPepColors()
            # Produce feature array
            scope.featureViewerConfig.featuresArray = transformPredictionGroupsToFeatures(scope.predictions)
            scope.scanMap = _.groupBy(_.filter(scope.featureViewerConfig.featuresArray, (obj) -> obj.featureTypeLabel == "glycopeptide_match"), (obj) -> obj._obj.scan_id)
            # Produce legend
            scope.featureViewerConfig.legend.keys = [] # TODO
            conf = scope.featureViewerConfig.configuration = generateConfig($window)
            conf.requestedStart = scope.start
            conf.requestedStop = scope.end
            conf.sequenceLength = scope.end
            if scope.featureViewerInstance?
                # BioJs caches all instances of a given widget. Have to remove all contents and
                # references to avoid memory leaks.
                try
                    scope.featureViewerInstance.clear()
                    biojsId = scope.featureViewerInstance
                    delete Biojs_FeatureViewer_array[biojsId - 1]
                    delete scope.featureViewerInstance


            scope.featureViewerInstance = new Biojs.FeatureViewer({
                    target: "protein-sequence-view-container-div"
                    json: _.cloneDeep(scope.featureViewerConfig)
                })


            scope.featureViewerInstance.onFeatureClick (featureShape) ->
                id = featureShape.featureId
                feature =  _.find(scope.featureViewerConfig.featuresArray, {featureId: id})
                # Add modal window configuration handles for glycopeptides and glycans
                if(feature.hasModalContent)
                    window.modalInstance= $modal.open({
                            templateUrl: "templates/summary-modal.html"
                            scope: scope
                            controller: ModalInstanceCtrl
                            size: 'lg'
                            windowClass: if feature.modalOptions.windowClass? then feature.modalOptions.windowClass \
                            else "peptide-view-modal"
                            resolve: {
                                title: ()->
                                    return feature.modalOptions.title
                                items: () ->
                                    return feature.modalOptions.items
                                summary: () ->
                                    return feature.modalOptions.summary
                                postLoadFn: () -> feature.modalOptions.postLoadFn
                            }
                        })

                    modalInstance.opened.then (evt) ->
                        $timeout(feature.modalOptions.postLoadFn, 1000)
                # Broadcast the last interacted with feature. Currently un-used
                if(feature.featureTypeLabel == "glycopeptide_match")
                    preds = []
                    if feature._obj.scan_id?
                        preds = _.pluck(scope.scanMap[feature._obj.scan_id], "_obj")
                    else
                        preds = [feature._obj]
                    scope.$emit("selectedPredictions", {selectedPredictions: preds})

            # 
            scope.featureViewerInstance.onFeatureOn (featureShape) ->
                id = featureShape.featureId
                feature =  _.find(scope.featureViewerConfig.featuresArray, {featureId: id})
                if feature.modifications?
                    for mod in feature.modifications
                        modId = "uniprotFeaturePainter_" + mod
                        modShape = scope.featureViewerInstance.raphael.getById(modId)
                        if modShape.type != "text"
                            modShape.scale(2)
                        else
                            modShape.attr("font-size", modShape.attr("font-size") * 2)
                        modShape.attr("fill-opacity", 1)


                if feature._obj.scan_id?
                    ambiguousMatches = scope.scanMap[feature._obj.scan_id]
                    for feat in ambiguousMatches
                        featId = "uniprotFeaturePainter_" + feat.featureId
                        featShape = scope.featureViewerInstance.raphael.getById(featId)
                        featShape.attr("fill", "red")

            scope.featureViewerInstance.onFeatureOff (featureShape) ->
                id = featureShape.featureId
                feature =  _.find(scope.featureViewerConfig.featuresArray, {featureId: id})
                if feature.modifications?
                    for mod in feature.modifications
                        modId = "uniprotFeaturePainter_" + mod
                        #scope.featureViewerInstance.raphael.getById(modId).transform("s1").attr("fill-opacity", 0.5)
                        modShape = scope.featureViewerInstance.raphael.getById(modId)

                        if modShape.type != "text"
                            modShape.scale(0.5)
                        else
                            modShape.attr("font-size", modShape.attr("font-size") * 0.5)
                        modShape.attr("fill-opacity", 0.5)

                if feature._obj.scan_id?
                    ambiguousMatches = scope.scanMap[feature._obj.scan_id]
                    for feat in ambiguousMatches
                        featId = "uniprotFeaturePainter_" + feat.featureId
                        featShape = scope.featureViewerInstance.raphael.getById(featId)
                        featShape.attr("fill", colorService.getPepColor("Peptide" + ((feat._obj.scan_id) )))

            angular.element("#protein-sequence-view-container-div").css({
                    height: $window.innerHeight,
                    "overflow-y": "scroll"
                })

        return {
            restrict: "E"
            scope: {
                predictions:"="
            }
            link: (scope, element, attrs) ->
                scope.getColorMap = -> colorMap
                scope.featureViewerConfig = {
                    featuresArray: []
                    segment: ""
                    configuration: {}
                    legend: {
                        segment: {
                            yPosCentered: 190
                            text: ""
                            yPos: 234
                            xPos: 15
                            yPosNonOverlapping: 214
                            yposRows: 290
                        }
                        key:[

                        ]
                    }

                }
                scope.$on "proteinSequenceView.updateProteinView", (evt, params) ->
                    updateView(scope, element)
                # scope.$watch("predictions", () -> updateView(scope, element))


            template: "<div class='protein-sequence-view-container' id='protein-sequence-view-container-div'></div>"
        }
    ]

