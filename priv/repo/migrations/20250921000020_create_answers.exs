defmodule Anda.Repo.Migrations.CreateAnswers do
  use Ecto.Migration

  def change do
    create table(:answers) do
      add :answer, :string
      add :index, :integer
      add :submission_id, references(:submissions, on_delete: :delete_all), null: false
      add :question_id, references(:questions, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:answers, [:index, :submission_id, :question_id])
  end
end
