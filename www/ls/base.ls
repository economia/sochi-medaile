class Nation
    (@name) ->
        @byMedals = []
        @byYears = []
        @byYearsAssoc = {}
        @medalsSum = 0

    addMedalist: ({rok:year, medaile:medal}:person) ->
        ++@medalsSum
        if @byYearsAssoc[year] is void
            medailists = []
            medailistsByType =
                *   type: \gold medailists: []
                *   type: \silver medailists: []
                *   type: \bronze medailists: []
            @byYearsAssoc[year] = -1 + @byYears.push {year, medailists, medailistsByType}
        yearData = @byYears[@byYearsAssoc[year]]
        index = switch medal
            | \zlato => 0
            | \stříbro => 1
            | \bronz => 2
        yearData.medailistsByType[index].medailists.push person
        yearData.medailists.push person

class Sport
    (@name) ->

class Event
    (@name) ->

years_assoc = {}
for year, index in ig.data.medailiste.indices.rok
    years_assoc[year] = index

nations = ig.data.medailiste.indices.stat .= map (name) -> new Nation name
sports = ig.data.medailiste.indices.sport .= map (name) -> new Sport name
events = ig.data.medailiste.indices.disciplina .= map (name) -> new Event name
people = ig.utils.deminifyData ig.data.medailiste
for person in people
    person.stat.addMedalist person

nations .= sort (a, b) -> b.medalsSum - a.medalsSum

container = d3.select ig.containers['base']
x = d3.scale.linear!
    ..domain [1924 2010]
    ..range [0 100]
heights = nations.map ->
    Math.max ...it.byYears.map (.medailists.length)
max = Math.max ...heights
lineHeight = 60px
y = d3.scale.linear!
    ..domain [0 max]
    ..range [0 lineHeight]

dNations = container.selectAll "div.nation" .data nations
    .enter!append \div
        ..attr \class \nation
        ..append \div
            ..attr \class \name
            ..html (.name)
        ..selectAll \div.year .data (.byYears)
            ..enter!append \div
                ..attr \class \year
                ..style \left -> "#{x it.year}%"
                ..selectAll \div.medalType .data (.medailistsByType)
                    ..enter!append \div
                        ..attr \class -> "medalType #{it.type}"
                        ..style \height -> "#{y it.medailists.length}px"
                ..style \height -> "#{y it.medailists.length}px"

ig.utils.draw-bg do
    ig.containers['base']
    top: -3px
    bottom: -1 + 3
