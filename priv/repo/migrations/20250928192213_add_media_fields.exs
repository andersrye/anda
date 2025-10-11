defmodule Anda.Repo.Migrations.AddMediaFields do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :media_url, :string
      add :media_type, :string
    end
  end
end
