defmodule Anda.Repo.Migrations.AnswersUnique do
  use Ecto.Migration

  def change do
        create unique_index(:answers, [:text, :question_id, :submission_id])
  end
end
