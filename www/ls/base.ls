tooltip = new Tooltip!
    ..watchElements!
class Nation
    (@abbr, @isPseudo) ->
        @name = ig.nations_expand[@abbr]
        @byMedals = []
        @byYears = []
        @byYearsAssoc = {}
        @medalsSum = 0
        @displayedMedals = 0

    addMedalist: ({rok:year, medaile:medal}:person) ->
        ++@medalsSum
        @displayedMedals = @medalsSum
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

    recountMedals: ->
        @displayedMedals =
            | yearFilter.length
                @byYears
                    .filter -> it.year in yearFilter
                    .reduce do
                        (prev, curr) -> prev + curr.medailists.length
                        0
            | otherwise => @medalsSum

class Sport
    (@name) ->

class Event
    (@name) ->

class PseudoNationSelector
    (@name, @abbr) ->

years_assoc = {}
for year, index in ig.data.medailiste.indices.rok
    years_assoc[year] = index

nations = ig.data.medailiste.indices.stat .= map (name) -> new Nation name
sports = ig.data.medailiste.indices.sport .= map (name) -> new Sport name
events = ig.data.medailiste.indices.disciplina .= map (name) -> new Event name
people = ig.utils.deminifyData ig.data.medailiste

pseudoNations =
    "TCH": new Nation "TCH", yes
    "RUS": new Nation "RUS", yes
    "GER": new Nation "GER", yes
pseudoNations.RUS.name = "Sovětský svaz + Sjednocený tým + Rusko"
pseudoNations.TCH.name = "Československo + Česká Republika + Slovensko"
pseudoNations.GER.name = "Německo + Západní + Východní + Sjednocené"
pseudoNationSources =
    "TCH": "TCH"
    "CZE": "TCH"
    "SVK": "TCH"
    "GER": "GER"
    "FRG": "GER"
    "GDR": "GER"
    "EUA": "GER"
    "RUS": "RUS"
    "URS": "RUS"
    "EUN": "RUS"

for index, pseudoNation of pseudoNations
    nations.push pseudoNation

for person in people
    person.stat.addMedalist person
    if person.stat.abbr of pseudoNationSources
        pseudoAbbr = pseudoNationSources[person.stat.abbr]
        pseudoNations[pseudoAbbr].addMedalist person

nations .= sort (a, b) -> b.medalsSum - a.medalsSum

container = d3.select ig.containers['base']
leftColumn = 89px
x = d3.scale.linear!
    ..domain [1924 2010]
    ..range [0+leftColumn, 458+leftColumn]
heights = nations.map ->
    Math.max ...it.byYears.map (.medailists.length)
max = Math.max ...heights
lineHeight = 60px
y = d3.scale.linear!
    ..domain [0 max]
    ..range [0 lineHeight]


pseudoNationSelectors =
    new PseudoNationSelector "Sjednotit Německo" "GER"
    new PseudoNationSelector "Spojit Rusko a Sovětský svaz" "RUS"
    new PseudoNationSelector "Zachovat Československo" "TCH"


container.append \div .attr \class \pseudoNationSelector
    ..selectAll "div.pair" .data pseudoNationSelectors .enter!append \div
        ..attr \class \pair
        ..append \input
            ..attr \type \checkbox
            ..attr \id -> "sochi-medaile-#{it.abbr}"
            ..on \change ->
                pseudoNations[it.abbr].active = @checked
                reFilter!
        ..append \label
            ..html (.name)
            ..attr \for -> "sochi-medaile-#{it.abbr}"
            ..attr \data-tooltip ->
                | it.abbr == "TCH" => "Objeví se níže ve výpisu, modře podbarvené"
                | otherwise => void

yearSelector = container.append \div .attr \class \yearSelector
yearFilter = ["2010"]
yearSelector.selectAll \div.year .data ig.data.medailiste.indices.rok .enter!append \div
    ..attr \class -> "year y-#{it}"
    ..classed \active -> it in yearFilter
    ..style \left -> "#{x it}px"
    ..append \span .html -> it
    ..append \div
        ..attr \class \closebtn
    ..on \click ->
        i = yearFilter.indexOf it
        if i === -1
            yearFilter.push it
            d3.select @ .classed \active yes
        else
            yearFilter.splice i, 1
            d3.select @ .classed \active no
        reFilter!
    ..on \mousedown -> d3.event.preventDefault!


dNations = container.selectAll "div.nation" .data nations
    .enter!append \div
        ..each (nation) -> nation.element = @
        ..attr \class ->
            isPseudo = if it.isPseudo then "pseudo disabled" else ""
            "nation #{isPseudo}"
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
                    #{it.medailistsByType.2.medailists.length}x bronz<br />
                    <i>Klikněte pro zobrazení konkrétních medailistů</i>"
                ..on \click (year, index, nationIndex) ->
                    draw-nation-year nations[nationIndex], year
                    tooltip.hide!
                ..on \mousedown -> d3.event.preventDefault!
                ..style \left -> "#{x it.year}px"
                ..append \div
                    ..attr \class \year
                    ..style \height -> "#{y it.medailists.length}px"
                    ..selectAll \div.medalType .data (.medailistsByType)
                        ..enter!append \div
                            ..attr \class -> "medalType #{it.type}"
                            ..style \height -> "#{y it.medailists.length}px"

reFilter = ->
    nations.forEach (.recountMedals!)
    dNations
        ..sort (a, b) -> b.displayedMedals - a.displayedMedals
        ..select "div.leftSide div.count" .html (.displayedMedals)
        ..classed \disabled -> if it.isPseudo and not it.active then true else false
        ..selectAll "div.yearContainer"
            ..classed \inactive ->
                yearFilter.length && it.year not in yearFilter
reFilter!
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
                ..on \mousedown -> d3.event.preventDefault!

    <~ setTimeout _, 1
    ele.classed \phase-1 on
