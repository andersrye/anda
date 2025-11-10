defmodule Anda.Repo.Migrations.AddQuestionTypeColumn do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :type, :string, null: false, default: "text"
    end
  end
end
