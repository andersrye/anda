defmodule Anda.Repo.Migrations.AddQuestionsRenderedText do
  alias Anda.Repo
  import Ecto.Query, warn: false
  alias Anda.Contest.Question
  use Ecto.Migration

  def up do
    alter table(:questions) do
      add :text_rendered, :text
    end

    flush()

    questions = Repo.all(from(q in Question, select: {q.id, q.text}))

    for {id, text} <- questions do
      rendered = MDEx.to_html!(text, render: [hardbreaks: true])
      q = from(q in Question, update: [set: [text_rendered: ^rendered]], where: q.id == ^id)
      Repo.update_all(q, [])
    end
  end

  def down do
    alter table(:questions) do
      remove :text_rendered
    end
  end
end
