defmodule Anda.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :question, :string
      add :num_answers, :integer
      add :alternatives, {:array, :string}
      add :section_id, references(:sections, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
