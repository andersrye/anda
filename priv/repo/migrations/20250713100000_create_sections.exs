defmodule Anda.Repo.Migrations.CreateSections do
  use Ecto.Migration

  def change do
    create table(:sections) do
      add :title, :string
      add :description, :string
      add :quiz_id, references(:quiz, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
