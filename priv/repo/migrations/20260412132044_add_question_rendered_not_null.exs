defmodule Anda.Repo.Migrations.AddQuestionRenderedNotNull do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      modify :text_rendered, :text, null: false
    end
  end
end
