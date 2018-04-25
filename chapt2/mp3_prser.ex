defmodule ID3Parser do
  def parse(file_name) do
    with {:ok, mp3} <- File.read(file_name)
    do
      %{artist: artist, title: title, album: album, year: year} = get_id3(mp3)
      IO.puts "#{artist} - #{title} (#{album}, #{year})"
    else
      {:error, posix} -> IO.puts "Could not open file #{file_name} bc #{posix}"
    end
  end

  defp get_id3(mp3) do
    mp3
    # |> IO.inspect
    |> get_tag
    # |> IO.inspect
    |> get_metadata
  end

  defp get_tag(mp3) do
    byte_size = mp3_byte_size(mp3)
    << _ :: binary-size(byte_size), id3_tag :: binary >> = mp3
    id3_tag
  end

  defp get_metadata(id3_tag) do
    << "TAG", raw_title  :: binary-size(30),
              raw_artist :: binary-size(30),
              raw_album  :: binary-size(30),
              raw_year   :: binary-size(4),
              _rest  :: binary >> = id3_tag
    [title, artist, album, year] = trim([raw_title, raw_artist, raw_album, raw_year])

    %{artist: artist, title: title, album: album, year: year}
  end

  defp trim([]), do: []
  defp trim([string | rest]) do
    [trim(string) | trim(rest) ]
  end
  defp trim(string) do
    String.split(string, <<0>>) |> List.first
  end

  defp mp3_byte_size(mp3), do: byte_size(mp3) - 128
end
