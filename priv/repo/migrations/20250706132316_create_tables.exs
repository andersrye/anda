defmodule Anda.Repo.Migrations.CreateQuiz do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:quiz) do
      add :title, :string
      add :description, :text
      add :mode, :string, null: false, default: "hidden"

      timestamps(type: :utc_datetime)
    end

    create table(:sections) do
      add :title, :string
      add :description, :string
      add :quiz_id, references(:quiz, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:questions) do
      add :text, :string
      add :type, :string, null: false, default: "text"
      add :num_answers, :integer
      add :alternatives, {:array, :string}
      add :media_url, :string
      add :media_type, :string
      add :section_id, references(:sections, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:submissions) do
      add :name, :citext
      add :secret, :string
      add :tags, {:array, :string}, null: false, default: []
      add :quiz_id, references(:quiz, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:submissions, [:name, :quiz_id], where: "name != ''")

    create table(:answers) do
      add :text, :citext
      add :index, :integer
      add :score, :integer
      add :submission_id, references(:submissions, on_delete: :delete_all), null: false
      add :question_id, references(:questions, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:answers, [:text, :question_id, :submission_id])
    create unique_index(:answers, [:index, :submission_id, :question_id])


  end
end
