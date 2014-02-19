tooltip = new Tooltip!
    ..watchElements!
class Nation
    (@abbr) ->
        @name = ig.nations_expand[@abbr]
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
    ..range [0 466]
heights = nations.map ->
    Math.max ...it.byYears.map (.medailists.length)
max = Math.max ...heights
lineHeight = 60px
y = d3.scale.linear!
    ..domain [0 max]
    ..range [0 lineHeight]

dNations = container.selectAll "div.nation" .data nations
    .enter!append \div
        ..each (nation) -> nation.element = @
        ..attr \class \nation
        ..append \div
            ..attr \class \name
            ..html (.name)
        ..append \div
            ..attr \class \leftSide
            ..append \div
                ..attr \class \abbr
                ..html (.abbr)
            ..append \div
                ..attr \class \count
                ..html -> it.medalsSum
        ..selectAll \div.year .data (.byYears)
            ..enter!append \div
                ..attr \class -> "yearContainer y-#{it.year}"
                ..attr \data-tooltip (it, index, nationIndex)-> escape "<b>#{nations[nationIndex].name}, rok #{it.year}</b><br />
                    Celkem #{it.medailists.length} medailí<br />
                    #{it.medailistsByType.0.medailists.length}x zlato<br />
                    #{it.medailistsByType.1.medailists.length}x stříbro<br />
                    #{it.medailistsByType.2.medailists.length}x bronz<br />"
                ..on \click (year, index, nationIndex) ->
                    draw-nation-year nations[nationIndex], year
                    tooltip.hide!
                ..style \left -> "#{x it.year}px"
                ..append \div
                    ..attr \class \year
                    ..style \height -> "#{y it.medailists.length}px"
                    ..selectAll \div.medalType .data (.medailistsByType)
                        ..enter!append \div
                            ..attr \class -> "medalType #{it.type}"
                            ..style \height -> "#{y it.medailists.length}px"

draw-nation-year = (nation, year) ->
    ele = d3.select nation.element .append \div
        ..attr \class \detail
        ..append \div
            ..attr \class \name
            ..html "#{nation.name}, <span>medaile #{year.year}<span>"
        ..selectAll \div.medalType .data year.medailistsByType .enter!append \div
            ..attr \class -> "medalType #{it.type}"
            ..selectAll \div.medal .data (.medailists) .enter!append \div
                ..attr \class "medal"
                ..attr \data-tooltip ({medaile, sport, disciplina, jmena, vysledek}) ->
                    escape "<b>#jmena</b><br />
                        #{sport.name} #{disciplina.name}<br />
                        #{vysledek}"
            ..append \div
                ..attr \class \sum
                ..html -> it.medailists.length
        ..append \div
            ..attr \class \closeContainer
            ..append \div
                ..attr \class \close
                ..on \click ->
                    ele.classed \phase-1 off
                    <~ setTimeout _, 800
                    ele.remove!

    <~ setTimeout _, 1
    ele.classed \phase-1 on
