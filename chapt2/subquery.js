let query = 'SELECT * FROM songs';
if (req.params.artist) {
    query = query + ' WHERE artist = "' + req.params.artist + '"'
}
query = query + ' LIMIT 10';

connection.query(query, (err, data) => {
    if (err) throw err;
    res.render('index', { songs: data })
})

const select = (columns, table_name) => `SELECT ${columns} FROM ${table_name}`

const where = (query, column, match) => {
    if (column && match) return `${query} WHERE ${column} = ${match}`
    return query
}
const limit = (query, number) => {
    if (number) return `${query} LIMIT ${number}`
    return query
}

let query = limit(where(select(), "artist", req.params.artist), 10)

// or using experiment pipeline operator that reads much better
let query = select()
    |> where("artist", req.params.artist)
    |> limit(10)
