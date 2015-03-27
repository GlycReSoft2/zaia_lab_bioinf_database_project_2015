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

    # Use the 0/1 list returned by the Filtrex function
    # as an inclusion list for entries in `predictions`
    applyFiltrex = (predictions, filt) ->
        filterResults = _.map(predictions, filt)
        passed = []
        for i in [0...predictions.length]
            if filterResults[i] == 1
                passed.push(predictions[i])
        return passed

    # Map the Filtrex string through the substitution dictionary to
    # replace human friendly strings with object field names and then
    # attempt to compile the string into a function. 
    # Returns an error code and the function produced if any
    tryCompileFiltrex = ($scope) ->
        $scope.filtrexError = false
        expr = $scope.params.filtrexExpr.toLowerCase()
        for column, key of $scope.headerSubstituitionDictionary
                expr = expr.replace(new RegExp(column, "g"), key)
        console.log(expr)
        try
            fn = compileExpression(expr)

            if $scope.predictions[0]? and isNaN(fn($scope.predictions[0]))
                throw new Error("Filtrex #{expr} generates NaNs")
        catch ex
            $scope.filtrexError = true
            console.log ex
        console.log $scope.filtrexError
        return [$scope.filtrexError, fn]

    # Attempt to compile the current Filtrex and run it against the 
    # the predictions in `$scope._predictions`, updating `$scope.predictions`
    # with the sorted results of those that pass
    filterByFiltrex = ($scope, orderBy) ->
        [error, filterFn] = tryCompileFiltrex($scope)
        if error
            return
        console.log "Working..."
        filteredPredictions = applyFiltrex($scope._predictions, filterFn)
        orderedResults = orderBy(filteredPredictions, ["MS1_Score", "Obs_Mass", "MS2_Score"])
        groupedResults = if $scope.groupByKey? then setGroupBy($scope.groupByKey, orderedResults) else orderedResults
        $scope.predictions = groupedResults
        console.log($scope.predictions.length)
        return groupedResults

    # Stub
    focusRow = ($scope, targetRowIndex) ->
        return

    # Start-up logic for the Controller
    activateFn = ($scope, $window, $filter) ->
        orderBy = $filter("orderBy")
        $scope.headerSubstituitionDictionary = $scope.buildHeaderSubstituitionDictionary()
        $scope.$watch("params.filtrexExpr", -> tryCompileFiltrex($scope, orderBy))
        $scope.$on("selectedPredictions", (evt, params) ->
            try
                for glycopeptide in params.selectedPredictions
                    index = (_.findIndex($scope.predictions, {"Glycopeptide_identifier": glycopeptide.Glycopeptide_identifier}))
            )
        $scope.$on("ambiguityPlot.requestPredictionsUpdate", (evt, params) -> $scope.sendRenderPlotEvt())
        console.log("Activation Complete")

    helpText = {
        filtrex: '<article class="help-article"><h3>Filtrex</h3><h4>Expressions</h4><p>There are only 2 types: numbers and strings.</p><table><tbody><table class="table"><thead><tr><th>Numeric arithmetic</th><th>Description</th></tr></thead><tbody><tr><td>x + y</td><td>Add</td></tr><tr><td>x - y</td><td>Subtract</td></tr><tr><td>x * y</td><td>Multiply</td></tr><tr><td>x / y</td><td>Divide</td></tr><tr><td>x % y</td><td>Modulo</td></tr><tr><td>x ^ y</td><td>Power</td></tr></tbody></table><table class="table"><thead><tr><th>Comparisons</th><th>Description</th></tr></thead><tbody><tr><td>x == y</td><td>Equals</td></tr><tr><td>x &lt; y</td><td>Less than</td></tr><tr><td>x &lt;= y</td><td>Less than or equal to</td></tr><tr><td>x &gt; y</td><td>Greater than</td></tr><tr><td>x &gt;= y</td><td>Greater than or equal to</td></tr><tr><td>x in (a, b, c)</td><td>Equivalent to (x == a or x == b or x == c)</td></tr><tr><td>x not in (a, b, c)</td><td>Equivalent to (x != a and x != b and x != c)</td></tr></tbody></table><table class="table"><thead><tr><th>Boolean logic</th><th>Description</th></tr></thead><tbody><tr><td>x or y</td><td>Boolean or</td></tr><tr><td>x and y</td><td>Boolean and</td></tr><tr><td>not x</td><td>Boolean not</td></tr><tr><td>x ? y : z</td><td>If boolean x, value y, else z</td></tr></tbody></table><p>Created by Joe Walnes, <a href="https://github.com/joewalnes/filtrex"><br/>(See https://github.com/joewalnes/filtrex for more usage information.)</a></p></article>'
    }

    # Pre-canned Filtrex
    filterRules = {
        requirePeptideBackboneCoverage: {
            label: "Require Peptide Backbone Fragment Ions Matches"
            filtrex: "Mean Coverage > 0"
        }
        requireStubIons: {
            label: "Require Stub Ion Matches"
            filtrex: "Stub Ions > 0"
        }
        requireIonsWithHexNAc: {
            label: "Require Peptide Backbone Ion Fragment with HexNAc Matches"
            filtrex: "Mean Coverage+HexNAc > 0"
        }
        requirePeptideLongerThanN: {
            label: "Require Peptide longer than 9 AA"
            filtrex: "AA Length > 9"
        }
    }

    groupingRules = {
        ms1ScoreObsMass: {
            label: "Group ion matches by MS1 Score and Observed Mass (Ambiguous Matches)"
            groupByKey: (x) -> [x.Peptide, x.MS1_Score, x.Obs_Mass]
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

            $scope.currentProtein = null
            $scope.proteins = []


            $scope.params = {}
            $scope.params.name = "GlycReSoft 2 Tandem MS Glycopeptide Analyzer"
            $scope.headerSubstituitionDictionary = {}


            $scope.params.filtrexExpr = "MS2 Score > 0.2"
            $scope.params.currentGroupingRule = $scope.groupingRules.ms1ScoreObsMass

            $scope.groupByKey = null
            $scope.deregisterWatcher = null

            # Testing function
            $scope.ping = (args) -> console.log("ping", arguments, $scope)

            # Logic for loading new data into the controller
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
                    $scope._predictions = orderBy(predictions, ["Peptide", "MS1_Score", "Obs_Mass", "-MS2_Score"])
                    filteredPredictions = filterByFiltrex($scope, orderBy)
                    filteredPredictions = $scope._predictions if not filteredPredictions?
                    groupedPredictions = $scope.setGroupBy($scope.params.currentGroupingRule.groupByKey, filteredPredictions)
                    $scope.predictions = groupedPredictions
                )
                return true
            
            # Currently unused - Set the groupBy function
            $scope.setGroupBy = (grouping, predictions = null) ->
                $scope.groupByKey = grouping
                setGroupBy(grouping, predictions)

            # Add a pre-canned extension to the current Filtrex string
            $scope.extendFiltrex = (expr) ->
                if $scope.params.filtrexExpr.length > 0
                    $scope.params.filtrexExpr += " and " + expr
                else
                    $scope.params.filtrexExpr += expr

            # Compile the bound Filtrex string and execute the resulting filter
            # over each prediction in $_predictions, retaining those that pass in $predictions.
            # Re-sorts the results.
            $scope.filterByFiltrex = ->
                console.log($scope.params.filtrexExpr)
                filteredPredictions = filterByFiltrex($scope, orderBy)
                groupedPredictions = $scope.setGroupBy($scope.params.currentGroupingRule.groupByKey, filteredPredictions)
                $scope.predictions = groupedPredictions


            $scope.sendRenderPlotEvt = () ->
                $scope.$broadcast("ambiguityPlot.renderPlot", {predictions: $scope.predictions})
            
            $scope.sendUpdateProteinViewEvt = () -> 
                $scope.$broadcast("proteinSequenceView.updateProteinView", {predictions: $scope.predictions})
            
            # Update function to apply any changes from other tabs to the 
            # main table
            $scope.activateTable = ->
                $scope.$apply($scope.scrollToSelection)

            # Stub from old ngGrid code
            $scope.scrollToSelection = ->
                return

            # Constructs a mapping from column names in the table to field
            # names on the prediction objects.
            $scope.buildHeaderSubstituitionDictionary = ->
                dictionary = {}
                dictionary.NAME_MAP = []
                BLACK_LIST = {
                    "Peptide Span": true, "b Ions": true, "b Ions With HexNAc": true,
                    "y Ions": true, "y Ions With HexNAc": true, "Stub Ions": true,
                    "Oxonium Ions": true
                }
                addMapping = (colName, fieldName) ->
                    dictionary[colName.toLowerCase()] = fieldName
                    dictionary.NAME_MAP.push(colName)
                addMapping "Starting Scan", "scan_id"
                addMapping "MS2 Score", "MS2_Score"
                addMapping "MS1 Score", "MS1_Score"
                addMapping "Start AA", "startAA"
                addMapping "End AA", "endAA"
                addMapping "Observed Mass", "Obs_Mass"
                addMapping "Glycan Mass", "glycanMass"
                addMapping "Mean Coverage", "meanCoverage"
                addMapping "Mean Coverage+HexNAc", "meanHexNAcCoverage"
                addMapping "AA Length", "peptideLens"
                addMapping "Oxonium Ions", "numOxIons"
                addMapping "Stub Ions", "numStubs"
                addMapping "y Ion Coverage", "percent_y_ion_coverage"
                addMapping "b Ion Coverage", "percent_b_ion_coverage"
                addMapping "y Ion With HexNAc Coverage", "percent_y_ion_with_HexNAc_coverage"
                addMapping "b Ion With HexNAc Coverage", "percent_b_ion_with_HexNAc_coverage"
                return dictionary

            activateFn($scope, $window, $filter)
            $window.ClassifierResultsTableCtrlInstance = $scope])
)
