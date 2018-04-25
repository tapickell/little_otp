def select(columns, table_name) do
  "SELECT #{columns} FROM #{table_name}"
end

def where(query, _column, nil), do: query
def where(query, column, match) do
  "#{query} WHERE #{column} = #{match}"
end

def limit(query, nil), do: query
def limit(query, number) do
  "#{query} LIMIT #{number}"
end

query = "*"
|> select("songs")
|> where("artist", req.params.artist)
|> limit(10)
