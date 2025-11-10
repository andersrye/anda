defmodule Anda.Repo.Migrations.ChangeAnswerCitext do
  use Ecto.Migration

  def change do

    alter table(:answers) do
      modify :answer, :citext
    end

    rename table(:answers), :answer, to: :text

  end
end
