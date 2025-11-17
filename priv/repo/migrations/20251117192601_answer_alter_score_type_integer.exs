defmodule Anda.Repo.Migrations.AnswerAlterScoreTypeInteger do
  use Ecto.Migration

  def change do
    alter table(:answers) do
      modify :score, :integer
    end

  end
end
