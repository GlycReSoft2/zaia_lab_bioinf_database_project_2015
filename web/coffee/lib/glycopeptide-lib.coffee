class GlycopeptideLib
    @buildBackboneStack: (glycopeptide) ->
        stack = ({
            bIon: [0,0],
            yIon: [0,0],
            bHexNAc: [0,0],
            yHexNAc: [0,0]
            } for i in [0..glycopeptide.peptideLens])
        len = glycopeptide.peptideLens

        for bIon in glycopeptide.b_ion_coverage
            key = bIon.key
            index = parseInt(key.replace(/B/, ''))
            stack[index].bIon = [0, index]

        for yIon in glycopeptide.y_ion_coverage
            key = yIon.key
            index = parseInt(key.replace(/Y/, ''))
            stack[len - index].yIon = [len - index , len]

        for bHexNAc in glycopeptide.b_ions_with_HexNAc
            key = bHexNAc.key
            index = parseInt(/B([0-9]+)\+/.exec(key)[1])
            stack[index].bHexNAc = [0, index]

        for yHexNAc in glycopeptide.y_ions_with_HexNAc
            key = yHexNAc.key
            index = parseInt(/Y([0-9]+)\+/.exec(key)[1])
            stack[len - index].yHexNAc = [len - index, len]

        return stack

    @parseModificationSites: (glycopeptide) ->
            sequence = glycopeptide.Glycopeptide_identifier
            regex = /(\(.+?\)|\[.+?\])/
            index = 0
            fragments = sequence.split(regex)
            modifications = []
            for frag in fragments
                if frag.charAt(0) is "["
                    # Ignore the Glycan Identifier Chunk
                else if frag.charAt(0) is "("
                    # This is a modification site
                    label = frag.replace(/\(|\)/g, "")
                    feature = name: label, position: index
                    modifications.push feature
                else
                    index += frag.length


            return modifications

    @sequenceTokenizer: (sequence, nTerm=null, cTerm=null) ->
        state = "start"  # [start, nTerm, aa, mod, cTerm]
        nTerm = nTerm or "H"
        cTerm = cTerm or "OH"
        mods = []
        chunks = []
        glycan = ""
        currentAA = ""
        currentMod = ""
        currentMods = []
        parenLevel = 0
        i = 0
        while i < sequence.length
            nextChr = sequence[i]
            # Transition from aa to mod when encountering the start of a modification
            # internal to the sequence
            if nextChr == "("
                if state == "aa"
                    state = "mod"
                    parenLevel += 1
                # Transition to nTerm when starting on an open parenthesis
                else if state == "start"
                    state = "nTerm"
                    parenLevel += 1
                else
                    parenLevel += 1
                    if not (state in ["nTerm", "cTerm"] and parenLevel == 1)
                        currentMod += nextChr
            else if nextChr == ")"
                if state == "aa"
                    throw new Exception(
                        "Invalid Sequence. ) found outside of modification, Position {0}. {1}".format(i, sequence))
                else
                    parenLevel -= 1
                    if parenLevel == 0
                        mods.push(currentMod)
                        currentMods.push(currentMod)
                        if state == "mod"
                            state = 'aa'
                            if currentAA == ""
                                chunks.slice(-1)[1] = chunks.slice(-1)[1].concat currentMods
                            else 
                                chunks.push([currentAA, currentMods])
                        else if state == "nTerm"
                            if sequence[i+1] != "-"
                                throw new Exception("Malformed N-terminus for " + sequence)
                            # Only one modification on termini
                            nTerm = currentMod
                            state = "aa"
                            # Jump ahead past - into the amino acid sequence
                            i += 1
                        else if state == "cTerm"
                            # Only one modification on termini
                            cTerm = currentMod

                        currentMods = []
                        currentMod = ""
                        currentAA = ""
                    else
                        currentMod += nextChr

            else if nextChr == "|"
                if state == "aa"
                    throw new Exception(
                        "Invalid Sequence. | found outside of modification")
                else
                    currentMods.push(currentMod)
                    mods.push(currentMod)
                    currentMod = ""
            else if nextChr == "["
                if (state == 'aa' or (state == "cTerm" and parenLevel == 0))
                    glycan = sequence.slice(i)
                    break
                else
                    currentMod += nextChr

            else if nextChr == "-"
                if state == "aa"
                    state = "cTerm"
                    if(currentAA != "")
                        currentMods.push(currentMod)
                        chunks.push([currentAA, currentMods])
                        currentMod = ""
                        currentMods = []
                        currentAA = ""
                else
                    currentMod += nextChr
            else if state == "start"
                state = "aa"
                currentAA = nextChr
            else if state == "aa"
                if(currentAA != "")
                    currentMods.push(currentMod)
                    chunks.push([currentAA, currentMods])
                    currentMod = ""
                    currentMods = []
                    currentAA = ""
                currentAA = nextChr
            else if state in ["nTerm", "mod", "cTerm"]
                currentMod += nextChr
            else
                throw new Exception(
                    "Unknown Tokenizer State", currentAA, currentMod, i, nextChr)
            i += 1
        if currentAA != ""
            chunks.push([currentAA, currentMod])
        if currentMod != ""
            mods.push(currentMod)

        return [chunks, mods, glycan, nTerm, cTerm]


class ProteinBackboneSpace
    constructor: (@predictions, @options={}) ->
        @stacks = _.groupBy @predictions, (p) -> [p.startAA, p.endAA]
        for pileup, matches of @stacks
            matches = matches.sort (a, b) ->
                if a.MS2_Score < b.MS2_Score
                    return -1
                else if a.MS2_Score > b.MS2_Score
                    return 1
                return 0

class GlycopeptideLib.Glycopeptide
    constructor: (glycopeptide) ->
        @data = glycopeptide
        console.log(5)


if(module?)
    if not module.exports?
        module.exports = {}

    module.exports.GlycopeptideLib = GlycopeptideLib
    module.exports.ProteinBackboneSpace = ProteinBackboneSpace
