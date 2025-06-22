defmodule Anda.Repo do
  use Ecto.Repo,
    otp_app: :anda,
    adapter: Ecto.Adapters.Postgres
end
