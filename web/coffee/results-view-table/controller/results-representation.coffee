# Creates an IIFE to define the closure of functions for the controller
do (()->

    # Groups prediction objects by a grouping predicate function.
    # It uses LoDash's groupBy function.
    # It mutates the input by setting a groupBy key to the cluster it
    # belongs to.
    setGroupBy = (grouping, predictions) -> (
        clustered = _.groupBy(predictions, grouping)
        id = 0
        _.forEach(clustered, (matches, key) ->
                for match in matches
                    match['groupBy'] = id
                    match['groupBySize'] = matches.length;
                id++
            )
        return predictions
        );

    applyFiltrex = (predictions, filt) ->
        filterResults = _.map(predictions, filt)
        passed = []
        for i in [0...predictions.length]
            if filterResults[i] is 1
                passed.push(predictions[i])
        return passed

    tryCompileFiltrex = ($scope) ->
        $scope.filtrexError = false
        expr = $scope.params.filtrexExpr.toLowerCase()
        for column, key of $scope.headerSubstituitionDictionary
                expr = expr.replace(new RegExp(column, "g"), key)
        try
            fn = compileExpression(expr)

            if $scope.predictions[0]? and isNaN(fn($scope.predictions[0]))
                throw new Error("Filtrex #{expr} generates NaNs")
        catch ex
            $scope.filtrexError = true
            console.log ex
        console.log $scope.filtrexError
        return [$scope.filtrexError, fn]

    filterByFiltrex = ($scope, orderBy) ->
        [error, filterFn] = tryCompileFiltrex($scope)
        if error
            return
        console.log "Working..."
        filteredPredictions = applyFiltrex($scope._predictions, filterFn)
        orderedResults = orderBy(filteredPredictions, ["MS1_Score", "Obs_Mass", "MS2_Score"])
        groupedResults = if $scope.groupByKey? then setGroupBy($scope.groupByKey, orderedResults) else orderedResults
        $scope.predictions = groupedResults
        return groupedResults


    updateFiltrexDebounce = _.debounce ($scope, orderBy) ->
            $scope.$apply -> filterByFiltrex($scope, orderBy)
        10000

    # Scrolls the ngGrid instance to a given row index
    focusRow = ($scope, targetRowIndex) ->
        grid = $scope.gridOptions.ngGrid
        position = (grid.rowMap[targetRowIndex] * grid.config.rowHeight)
        grid.$viewport.scrollTop(position)

    # Start-up logic for the Controller
    activateFn = ($scope, $window, $filter) ->
        orderBy = $filter("orderBy")
        $scope.headerSubstituitionDictionary = $scope.buildHeaderSubstituitionDictionary()
        $scope.$watch("params.filtrexExpr", -> tryCompileFiltrex($scope, orderBy))
        $scope.$on("selectedPredictions", (evt, params) ->
            try
                $scope.gridOptions.selectAll(false)
                for glycopeptide in params.selectedPredictions
                    index = (_.findIndex($scope.predictions, {"Glycopeptide_identifier": glycopeptide.Glycopeptide_identifier}))
                    $scope.gridOptions.selectRow(index, true)
            )
        $scope.$on("ambiguityPlot.requestPredictionsUpdate", (evt, params) -> $scope.sendRenderPlotEvt())
        console.log("Activation Complete")

    helpText = {

        filtrex: '<article class="help-article"><h3>Filtrex</h3><h4>Expressions</h4><p>There are only 2 types: numbers and strings.</p><table><tbody><table class="table"><thead><tr><th>Numeric arithmetic</th><th>Description</th></tr></thead><tbody><tr><td>x + y</td><td>Add</td></tr><tr><td>x - y</td><td>Subtract</td></tr><tr><td>x * y</td><td>Multiply</td></tr><tr><td>x / y</td><td>Divide</td></tr><tr><td>x % y</td><td>Modulo</td></tr><tr><td>x ^ y</td><td>Power</td></tr></tbody></table><table class="table"><thead><tr><th>Comparisons</th><th>Description</th></tr></thead><tbody><tr><td>x == y</td><td>Equals</td></tr><tr><td>x &lt; y</td><td>Less than</td></tr><tr><td>x &lt;= y</td><td>Less than or equal to</td></tr><tr><td>x &gt; y</td><td>Greater than</td></tr><tr><td>x &gt;= y</td><td>Greater than or equal to</td></tr><tr><td>x in (a, b, c)</td><td>Equivalent to (x == a or x == b or x == c)</td></tr><tr><td>x not in (a, b, c)</td><td>Equivalent to (x != a and x != b and x != c)</td></tr></tbody></table><table class="table"><thead><tr><th>Boolean logic</th><th>Description</th></tr></thead><tbody><tr><td>x or y</td><td>Boolean or</td></tr><tr><td>x and y</td><td>Boolean and</td></tr><tr><td>not x</td><td>Boolean not</td></tr><tr><td>x ? y : z</td><td>If boolean x, value y, else z</td></tr></tbody></table><p>Created by Joe Walnes, <a href="https://github.com/joewalnes/filtrex"><br/>(See https://github.com/joewalnes/filtrex for more usage information.)</a></p></article>'

    }

    filterRules = {
        requirePeptideBackboneCoverage: {
            label: "Require Peptide Backbone Fragment Ions Matches"
            filtrex: "Mean Peptide Coverage > 0"
        }
        requireStubIons: {
            label: "Require Stub Ion Matches"
            filtrex: "Stub Ion Count > 0"
        }
        requireIonsWithHexNAc: {
            label: "Require Peptide Backbone Ion Fragment with HexNAc Matches"
            filtrex: "Mean PeptideHexNAc Coverage > 0"
        }
        requirePeptideLongerThanN: {
            label: "Require Peptide longer than 9 AA"
            filtrex: "AA Length > 9"
        }
    }

    groupingRules = {
        ms1ScoreObsMass: {
            label: "Group ion matches by MS1 Score and Observed Mass (Ambiguous Matches)"
            groupByKey: (x) -> [x.MS1_Score, x.Obs_Mass]
        }
        startAALength: {
            label: "Group ion matches by the starting amino acid index and the peptide length (Heterogeneity)"
            groupByKey: (x) -> [x.startAA, x.peptideLens]
        }

    }

    angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").controller(
        "ClassifierResultsTableCtrl", [ "$scope", "$window", '$filter', 'csvService', '$timeout',
        ($scope, $window, $filter, csvService, $timeout) ->
            orderBy = $filter("orderBy")
            $scope.helpText = helpText
            $scope.filterRules = filterRules
            $scope.groupingRules = groupingRules

            $scope.backend = {}
            $scope.metadata = {}
            $scope.predictions = []
            $scope._predictions = []
            $scope._predictionsReceiver = []

            $scope.params = {}
            $scope.params.name = "GlycReSoft 2 Tandem MS Glycopeptide Analyzer"
            $scope.headerSubstituitionDictionary = {}


            $scope.params.filtrexExpr = "MS2 Score > 0.2"
            $scope.params.currentGroupingRule = $scope.groupingRules.ms1ScoreObsMass

            $scope.groupByKey = null
            $scope.deregisterWatcher = null

            $scope.ping = (args) -> console.log("ping", arguments, $scope)
            $scope.update = (newVal) ->
                console.log("Update", arguments)
                $scope.backend = newVal
                $scope.$apply(
                    ->
                    if !newVal.metadata?
                        $scope.backend = new PredictionResults(newVal, {})
                    else
                        $scope.backend = new PredictionResults(newVal.predictions, newVal.metadata)
                    predictions = $scope.backend._predictions
                    $scope.metadata = $scope.backend.metadata
                    $scope._predictions = orderBy(predictions, ["MS1_Score", "Obs_Mass", "-MS2_Score"])
                    filteredPredictions = filterByFiltrex($scope, orderBy)
                    filteredPredictions = $scope._predictions if not filteredPredictions?
                    groupedPredictions = $scope.setGroupBy($scope.params.currentGroupingRule.groupByKey, filteredPredictions)
                    $scope.predictions = groupedPredictions
                    $scope.gridLayoutPlugin.updateGridLayout()
                )
                return true
            $scope.extendFiltrex = (expr) ->
                if $scope.params.filtrexExpr.length > 0
                    $scope.params.filtrexExpr += " and " + expr
                else
                    $scope.params.filtrexExpr += expr

            $scope.filterByFiltrex = ->
                filterByFiltrex($scope, orderBy)

            $scope.sendRenderPlotEvt = () ->
                $scope.$broadcast("ambiguityPlot.renderPlot", {predictions: $scope.predictions})
            $scope.sendUpdateProteinViewEvt = () -> $scope.$broadcast("proteinSequenceView.updateProteinView", {predictions: $scope.predictions})
            $scope.setGroupBy = (grouping, predictions = null) ->
                $scope.groupByKey = grouping
                setGroupBy(grouping, predictions)
            $scope.activateTable = ->
                console.log "Activating table,", $scope
                $scope.$apply($scope.scrollToSelection)
                try
                    $scope.gridLayoutPlugin.updateGridLayout()

            $scope.scrollToSelection = ->
                if $scope.gridOptions.$gridScope? and $scope.gridOptions.$gridScope.selectedItems?
                    console.log "Scroll to selection!"
                    selectedItems = $scope.gridOptions.$gridScope.selectedItems
                    topIndex = Infinity # The index at the top of the selection (nearest to 0)
                    for glycopeptide in selectedItems
                        index = (_.findIndex($scope.predictions, {"Glycopeptide_identifier": glycopeptide.Glycopeptide_identifier}))
                        topIndex = index if index < topIndex
                    if topIndex is Infinity
                        return false
                    $timeout( (-> focusRow($scope, topIndex)), 50)
                    console.log topIndex
                    return 0

            $scope.buildHeaderSubstituitionDictionary = ->
                dictionary = {}
                dictionary.NAME_MAP = []
                BLACK_LIST = {
                    "Peptide Span": true, "b Ions": true, "b Ions With HexNAc": true,
                    "y Ions": true, "y Ions With HexNAc": true, "Stub Ions": true,
                    "Oxonium Ions": true
                }
                for column in $scope.gridOptions.columnDefs
                    if not (BLACK_LIST[column.displayName])
                        dictionary.NAME_MAP.push column.displayName
                        dictionary[column.displayName.toLowerCase()] = column.field
                dictionary["Start AA".toLowerCase()] = "startAA"
                dictionary.NAME_MAP.push "Start AA"
                dictionary["End AA".toLowerCase()] = "endAA"
                dictionary.NAME_MAP.push "End AA"
                dictionary["AA Length".toLowerCase()] = "peptideLens"
                dictionary.NAME_MAP.push "AA Length"
                dictionary["Oxonium Ion Count".toLowerCase()] = "numOxIons"
                dictionary.NAME_MAP.push "Oxonium Ion Count"
                dictionary["Stub Ion Count".toLowerCase()] = "numStubs"
                dictionary.NAME_MAP.push "Stub Ion Count"
                dictionary["% y Ion Coverage".toLowerCase()] = "percent_y_ion_coverage"
                dictionary.NAME_MAP.push "% y Ion Coverage"
                dictionary["% b Ion Coverage".toLowerCase()] = "percent_b_ion_coverage"
                dictionary.NAME_MAP.push "% b Ion Coverage"
                dictionary["% y Ion With HexNAc Coverage".toLowerCase()] = "percent_y_ion_with_HexNAc_coverage"
                dictionary.NAME_MAP.push "% y Ion With HexNAc Coverage"
                dictionary["% b Ion With HexNAc Coverage".toLowerCase()] = "percent_b_ion_with_HexNAc_coverage"
                dictionary.NAME_MAP.push "% b Ion With HexNAc Coverage"

                return dictionary


            headerCellTemplateNoPin = '<div class="ngHeaderSortColumn {{col.headerClass}}" ng-style="{\'cursor\': col.cursor}" ng-class="{ \'ngSorted\': !noSortVisible }">
                                        <div ng-click="col.sort($event)" ng-class="\'colt\' + col.index" class="ngHeaderText">{{col.displayName}}</div>
                                        <div class="ngSortButtonDown" ng-show="col.showSortButtonDown()"></div>
                                        <div class="ngSortButtonUp" ng-show="col.showSortButtonUp()"></div>
                                        <div class="ngSortPriority">{{col.sortPriority}}</div>
                                    </div>
                                    <div ng-show="col.resizable" class="ngHeaderGrip" ng-click="col.gripClick($event)" ng-mousedown="col.gripOnMouseDown($event)"></div>'

            $scope.gridLayoutPlugin = new ngGridLayoutPlugin();
            $scope.gridOptions = {
                data: "predictions"
                showColumnMenu: true
                showFilter: false
                enableSorting: false
                enableHighlighting: true
                enablePinning: true
                rowHeight: 90
                plugins: [ $scope.gridLayoutPlugin ]
                columnDefs:[
                    {
                        field:'scan_id'
                        width:90
                        pinned:true
                        displayName: "Scan ID"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'MS2_Score'
                        width:90
                        pinned: true
                        displayName:"MS2 Score"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|number:4}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'MS1_Score'
                        width:90
                        pinned: true
                        displayName:"MS1 Score"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|number:4}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'Obs_Mass'
                        width:130
                        pinned: true
                        displayName:"Observed Mass"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|number:4}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'vol'
                        width:90
                        pinned: true
                        displayName:"Volume"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|number:3}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'ppm_error'
                        width:90
                        displayName:"PPM Error"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|scientificNotation|number:4}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'Glycopeptide_identifier'
                        width: 240
                        displayName:"Glycopeptide Sequence"
                        cellClass: "matched-ions-cell glycopeptide-identifier"
                        cellTemplate: '<div><div class="ngCellText" ng-bind-html="row.getProperty(col.field)|highlightModifications"></div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'meanCoverage'
                        width:180
                        displayName:"Mean Peptide Coverage"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|number:3}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'meanHexNAcCoverage'
                        width:180
                        displayName:"Mean PeptideHexNAc Coverage"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)|number:3}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'percentUncovered'
                        width:165
                        displayName:"% Peptide Uncovered"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field) * 100|number:2}}</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field: "startAA"
                        width: 180
                        displayName: "Peptide Span"
                        cellTemplate: '<div><div class="ngCellText matched-ions-cell">{{::row.getProperty(col.field)}}-{{row.entity.endAA}}&nbsp;({{row.entity.peptideLens}})</div></div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'Oxonium_ions',
                        width: 200
                        headerClass: null
                        displayName:"Oxonium Ions"
                        cellClass: "stacked-ions-cell-grid"
                        cellTemplate:
                                    '<div>
                                        <div class="ngCellText">
                                            <div class="coverage-text">{{::row.entity.numOxIons}} Ions Matched</div>
                                            <fragment-ion ng-repeat="fragment_ion in row.getProperty(col.field)"></fragment-ion>
                                        </div>
                                    </div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'Stub_ions',
                        width: 340
                        displayName:"Stub Ions"
                        headerClass: null
                        cellClass: "stacked-ions-cell-grid"
                        cellTemplate:
                                    '<div>
                                        <div class="ngCellText">
                                            <div class="coverage-text">{{::row.entity.numStubs}} Ions Matched</div>
                                            <fragment-ion ng-repeat="fragment_ion in row.getProperty(col.field)"></fragment-ion>
                                        </div>
                                    </div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'b_ion_coverage',
                        width: 340
                        displayName:"b Ions"
                        headerClass: null
                        cellClass: "stacked-ions-cell-grid"
                        cellTemplate:
                                    '<div>
                                        <div class="ngCellText">
                                            <div class="coverage-text">{{::row.entity.percent_b_ion_coverage * 100|number:1}}% Coverage</div>
                                            <fragment-ion ng-repeat="fragment_ion in row.getProperty(col.field)"></fragment-ion>
                                        </div>
                                    </div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'y_ion_coverage',
                        width: 340
                        displayName:"y Ions"
                        headerClass: null
                        cellClass: "stacked-ions-cell-grid"
                        cellTemplate:
                                    '<div>
                                        <div class="ngCellText">
                                            <div class="coverage-text">{{::row.entity.percent_y_ion_coverage * 100|number:1}}% Coverage</div>
                                            <fragment-ion ng-repeat="fragment_ion in row.getProperty(col.field)"></fragment-ion>
                                        </div>
                                    </div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'b_ions_with_HexNAc',
                        width: 340
                        displayName:"b Ions with HexNAc"
                        headerClass: null
                        cellClass: "stacked-ions-cell-grid"
                        cellTemplate:
                                    '<div>
                                        <div class="ngCellText">
                                            <div class="coverage-text">{{::row.entity.percent_b_ion_with_HexNAc_coverage * 100 |number:1}}% Coverage</div>
                                            <fragment-ion ng-repeat="fragment_ion in row.getProperty(col.field)"></fragment-ion>
                                        </div>
                                    </div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                    {
                        field:'y_ions_with_HexNAc',
                        width: 340
                        displayName:"y Ions with HexNAc"
                        headerClass: null
                        cellClass: "stacked-ions-cell-grid"
                        cellTemplate:
                                    '<div>
                                        <div class="ngCellText">
                                            <div class="coverage-text">{{::row.entity.percent_y_ion_with_HexNAc_coverage * 100|number:1}}% Coverage</div>
                                            <fragment-ion ng-repeat="fragment_ion in row.getProperty(col.field)"></fragment-ion>
                                        </div>
                                    </div>'
                        headerCellTemplate: headerCellTemplateNoPin
                    }
                ]
                # Class setting in outer-most div interpolates color class from the prediction's groupBy.
                # Only color if the group is larger than 1 match
                rowTemplate: '<div style="height: 100%" class="{{::row.entity.groupBySize > 1 ? \'c\' + row.entity.groupBy % 6 : \'cX\'}}">
                                <div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell matched-ions-cell">
                                    <div class="ngVerticalBar" ng-style="{height: rowHeight}" ng-class="{ ngVerticalBarVisible: !$last }"> </div>
                                        <div ng-cell>
                                    </div>
                                </div>
                            </div>'
                            }

            activateFn($scope, $window, $filter)
            $window.ClassifierResultsTableCtrlInstance = $scope])
)