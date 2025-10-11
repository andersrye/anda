defmodule AndaWeb.QuizLive.Form.MultiString do
  use Ecto.Type
  def type, do: {:array, :string}
  def embed_as(_), do: :dump

  # Provide custom casting rules.
  # Cast strings into the URI struct to be used at runtime
  def cast(string) when is_binary(string) do
    {:ok, string |> String.split("\n")}
  end

  # Everything else is a failure though
  def cast(_), do: :error

  # When loading data from the database, as long as it's a map,
  # we just put the data back into a URI struct to be stored in
  # the loaded schema struct.
  def load(data) when is_list(data) do
    IO.puts("MultiString LOAD #{inspect(data)}")
    {:ok, data}
  end

  # When dumping data to the database, we *expect* a URI struct
  # but any value could be inserted into the schema struct at runtime,
  # so we need to guard against them.
  def dump(data) do
    IO.puts("MultiString DUMP #{inspect(data)}")
    data
   end

  def dump(_), do: :error
end
