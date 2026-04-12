defmodule Anda.Repo.Migrations.AddIndexes do
  use Ecto.Migration

  def change do
    create index(:quiz, [:user_id])
    create index(:sections, [:quiz_id, :position])
    create index(:submissions, [:quiz_id])
    create index(:submissions, [:secret])
    create index(:submissions, [:tags])
    create index(:questions, [:section_id, :position])
    create index(:answers, [:submission_id])
    create index(:answers, [:question_id])
  end
end
