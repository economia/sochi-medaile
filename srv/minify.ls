require! {fs, csv}
minify =
    columns: <[rok sport disciplina medaile stat jmena vysledek]>
    indexize: <[rok sport disciplina medaile stat]>
to_indexize = minify.indexize.map (field) ->
    data = []
    data_indices = {}
    {field, data, data_indices}
out = []
c = csv!.from.stream fs.createReadStream "#__dirname/../data/medailiste.csv"
    ..on \record ([_,rok,sport,disciplina,medaile,stat,jmena,vysledek], index) ->
        return if rok == 'rok'
        datum = {rok, sport, disciplina, medaile, stat, jmena, vysledek}
        for {field, data, data_indices} in to_indexize
            d = datum[field]
            if data_indices[d] is void
                data_indices[d] = -1 + data.push d
            datum[field] = data_indices[d]
        line = for column in minify.columns
            datum[column]
        out.push line

<~ c.on \end
json = {columns:minify.columns, indices: {}, data:out}
for {field, data} in to_indexize
    json.indices[field] = data
fs.writeFile "#__dirname/../data/medailiste.json", JSON.stringify json
