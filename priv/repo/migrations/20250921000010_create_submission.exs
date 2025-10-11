defmodule Anda.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add :name, :string
      add :secret, :string
      add :quiz_id, references(:quiz, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
