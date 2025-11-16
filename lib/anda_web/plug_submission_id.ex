defmodule SubmissionPlug do
  def init([]), do: false

  def call(%{path_params: %{"quiz_id" => quiz_id}} = conn, _opts) do
    submissions_map =
      Plug.Conn.fetch_cookies(conn, signed: ~w"submissions")
      |> Plug.Conn.get_cookies()
      |> Map.get("submissions", %{})
      |> Map.put_new(quiz_id, Ecto.UUID.generate())

    dbg(submissions_map)

    conn
    |> Plug.Conn.put_session(:submissions, submissions_map)
    |> Plug.Conn.put_resp_cookie("submissions", submissions_map, sign: true, max_age: 34_560_000)
  end
end
