defmodule SubmissionPlug do
  def init([]), do: false

  def call(%{path_params: %{"id" => quiz_id}} = conn, _opts) do
    submissions_map =
      Plug.Conn.get_session(conn, :submissions, %{})
      |> Map.put_new(quiz_id, Ecto.UUID.generate())

    conn |> Plug.Conn.put_session(:submissions, submissions_map)
  end
end
