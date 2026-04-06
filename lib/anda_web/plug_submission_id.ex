defmodule SubmissionPlug do
  import Plug.Conn
  def init([]), do: false

  def call(conn, _opts) do
    #legacy:
    submissions_map =
      fetch_cookies(conn, signed: ~w"submissions")
      |> get_cookies()
      |> Map.get("submissions", %{})

    secret_salt =
      fetch_cookies(conn, signed: ~w"secret_salt")
      |> get_cookies()
      |> Map.get("secret_salt") ||
        :crypto.strong_rand_bytes(32) |> Base.encode64()

    dbg(secret_salt)

    conn
    |> put_session(:submissions, submissions_map)
    |> put_session(:secret_salt, secret_salt)
    |> put_resp_cookie("secret_salt", secret_salt, sign: true, max_age: 34_560_000)
  end
end
