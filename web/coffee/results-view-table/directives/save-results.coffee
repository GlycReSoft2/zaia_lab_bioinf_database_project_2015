# save-results.coffee
# Handles the indirection to create a client-side file save

angular.module("GlycReSoftMSMSGlycopeptideResultsViewApp").directive "saveResults", ["csvService", (csvService) ->

    # Handle the actual file generation
    saveResults = (predictions, metadata, element, fileName="results.json") ->
        if not (Blob? and saveAs?)
            alert("File Saving is not supported with this browser")
            return
        output = PredictionResults.serialize(predictions, metadata)
        blob = new Blob([output], {type: "application/json;charset=utf-8"})
        saveAs(blob, fileName)

    return {
        restrict: "EA"
        scope:{
            predictions:'='
            predictionsUnfiltered:'='
            metadata:'='
            mayOpenFile:'='
        }
        templateUrl: "templates/save-menu.html"
        link: (scope, element, attrs) ->

            # Used to track the bound dropdown menu state
            scope.status = {isopen: false}

            # Save only the results currently being displayed
            element.find(".save-filter-results-anchor").click (e) ->
                saveResults(scope.predictions, scope.metadata, element, "filtered-results.json")
            # Save all the results, not just those currently being displayed
            element.find(".save-all-results-anchor").click (e) ->
                saveResults(scope.predictionsUnfiltered, scope.metadata, element, "all-results.json")
            
            # Forward all clicks on the "open file" label to the hidden file input, since 
            # the file input is a native widget that cannot be styled.
            element.find(".open-file-anchor").click (e) ->
                element.find("#file-opener").click()

            # Every time a new file is put into the file input through the native dialog, 
            # read it in and pass it to the application controller.
            element.find("#file-opener").change (e) ->
                fileReader = new FileReader()
                # Handle the actual passing of the read file to the application controller
                fileReader.onload = (e) =>
                    fileContents = e.target.result
                    if fileContents[0] != "{"
                        format = "csv"
                        parsedData = d3.csv.parse(fileContents)
                    else
                        format = 'json'
                        parsedData = PredictionResults.parse(fileContents)
                    registerDataChange(parsedData, @.files[0].name, format)
                # Start the file reading process asynchronously
                fileReader.readAsText(@files[0], 'UTF-8');

    }


]
