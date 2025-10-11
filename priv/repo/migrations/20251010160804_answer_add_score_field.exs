defmodule Anda.Repo.Migrations.AnswerAddScoreField do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      add :score, :real
    end
  end
end
