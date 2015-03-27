


class PredictionResults
    @DEFAULT_SORT_FIELDS = ["MS1_Score", "Obs_Mass", "-MS2_Score"]
    @DEFAULT_GROUPING_PREDICATE = (pred)-> [pred.Obs_Mass, pred.MS1_Score]
    @parse = (textBlob) ->
        rep = if typeof textBlob == "string" then JSON.parse(textBlob) else textBlob
        idCount = 0
        _.forEach(rep.predictions, (pred) -> pred.id = idCount++)
        results = []
        for i in [0...rep.predictions.length]
            pred = rep.predictions[i]
            if pred.MS2_Score > 0
                results.push(pred)
        rep.predictions = results
        new PredictionResults(rep.predictions, rep.metadata)

    @serialize = (predictions, metadata) ->
        if predictions.metadata?
            metadata = predictions.metadata
            predictions = predictions.predictions
        stringForm = JSON.stringify({predictions: predictions, metadata: metadata})
        return stringForm

    constructor: (@predictions, @metadata) ->
        @_predictions = @predictions

    filterBy: (filterFn) ->
        # Assume filterFn returns false-y (0) or true-y (1) on pass/fail
        filteredResults = _.map(@_predictions, filterFn)
        passPreds = new Array(filteredResults.sum())
        passPos = 0
        for i in [0...filteredResults.length]
            if filteredResults[i]
                passPreds[passPos] = @_predictions[i]
                passPos++
        @predictions = passPreds

    groupBy: (groupFn=PredictionResults.DEFAULT_GROUPING_PREDICATE) ->
        groups = _.groupBy(@predictions, groupFn)
        id = 0
        _.forEach(groups, (matches, key) ->
            for match in matches
                match.groupBy = id
                match.groupBySize = matches.length
            i++
        )

    sortBy: (fields=PredictionResults.DEFAULT_SORT_FIELDS) ->
        @predictions = _.sortBy(@predictions, fields)

    byPosition: ->
        @groupBy (p) -> [p.startAA, p.endAA]


if(module?)
    if not module.exports?
        module.exports = {}

    module.exports.PredictionResults = PredictionResults
