defmodule Anda.Repo.Migrations.AddAnswerKey do
  use Ecto.Migration
  alias Anda.Repo
  import Ecto.Query, warn: false
  alias Anda.Submission.Answer
  alias Anda.Contest.AnswerKey

  def up do
    create table(:answer_key) do
      add :text, :citext, null: false
      add :score, :integer, null: false
      add :question_id, references(:questions, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:answer_key, [:question_id, :text])

    alter table(:questions) do
      add :answer_key, :text
    end

    flush()

    answers =
      Repo.all(
        from(a in Answer,
          select: %{text: a.text, score: a.score, question_id: a.question_id},
          group_by: [a.text, a.score, a.question_id],
          where: not is_nil(a.score)
        )
      )

    for answer <- answers do
      Repo.insert(%AnswerKey{
        text: answer.text,
        score: answer.score,
        question_id: answer.question_id
      })
    end
  end

  def down do
    drop table(:answer_key)

    alter table(:questions) do
      remove :answer_key
    end
  end
end
