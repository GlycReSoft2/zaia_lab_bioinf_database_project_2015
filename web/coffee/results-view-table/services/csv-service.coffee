# csv-service.coffee
# Depends upon d3 to provide the Csv parsing features
class CsvService
    @serializedFields:  [
                        "Oxonium_ions",
                        "Stub_ions",
                        "bare_b_ions",
                        "bare_y_ions",
                        "b_ion_coverage",
                        "y_ion_coverage",
                        "b_ions_with_HexNAc",
                        "y_ions_with_HexNAc",
                        "startAA",
                        "endAA",
                        "vol",
                        "peptideLens",
                        "numOxIons",
                        "numStubs",
                        "scan_id",

                        "meanCoverage",
                        "percentUncovered",

                        "meanHexNAcCoverage",
                        "peptideCoverageMap",
                        "hexNAcCoverageMap",

                        "bIonCoverageMap",
                        "bIonCoverageWithHexNAcMap",
                        "yIonCoverageMap",
                        "yIonCoverageWithHexNAcMap",

                        "MS1_Score",
                        "MS2_Score",

                        "Obs_Mass",
                        "Calc_mass",
                        'ppm_error',
                        'abs_ppm_error',
                        'percent_b_ion_with_HexNAc_coverage',
                        'percent_y_ion_with_HexNAc_coverage'
                    ]

    @defaultValues:  {
        "hexNAcCoverageMap": (pred) -> [0 for i in [0...pred.peptideLens]]
        "peptideCoverageMap": (pred) -> [0 for i in [0...pred.peptideLens]]
        "meanHexNAcCoverage": (pred) -> 0.0
        "bIonCoverageMap": (pred)->
            [0 for i in [0...pred.peptideLens]]
        "bIonCoverageWithHexNAcMap": (pred)-> [0 for i in [0...pred.peptideLens]]
        "yIonCoverageMap": (pred)-> [0 for i in [0...pred.peptideLens]]
        "yIonCoverageWithHexNAcMap": (pred) -> [0 for i in [0...pred.peptideLens]]
    }


    @parse:  (stringData) ->
        rowData = d3.csv.parse(stringData)
        instantiatedData = @deserializeAfterParse(rowData)
        @defaultValues(instantiatedData)
        return instantiatedData

    @format:  (rowData) ->
        serializedData = @serializeBeforeFormat(rowData)
        stringData = d3.csv.format(serializedData)
        return stringData

    # Translating from CSV leaves many fields as strings or JSON trees that need to be parsed into
    # JS Numbers and Objects
    @deserializeAfterParse:  (predictions) ->
        self = this
        idCnt = 0
        _.forEach(predictions, (obj) ->
            _.forEach(self.serializedFields, (field) ->
                obj[field] = angular.fromJson(obj[field]))
            obj.call = if obj.call == "Yes" then true else false
            obj.ambiguity = if obj.ambiguity == "True" then true else false
            obj.groupBy = 0
            obj.id = idCnt++
            return obj
        )
        return predictions

    @setDefaultValues:  (predictions) ->
        for pred in predictions
            for key, defaultFn of @defaultValues
                if not pred[key]?
                    pred[key] = defaultFn(pred)

        return predictions

    @serializeBeforeFormat:  (predictions) ->
        self = this
        predictions = _.cloneDeep(predictions)
        _.forEach(predictions, (obj) ->
            _.forEach(self.serializedFields, (field) ->
                obj[field] = angular.toJson(obj[field]))
            obj.call = if obj.call then "Yes" else "No"
            obj.ambiguity = if obj.ambiguity then "True" else "False"
            obj.groupBy = 0
            #console.log(obj)
            return obj
        )
        return predictions

try
    GlycReSoftMSMSGlycopeptideResultsViewApp.factory "csvService", [() -> CsvService]

if(module?)
    if not module.exports?
        module.exports = {}

    module.exports = CsvService