defmodule Anda.Repo.Migrations.AddUserToQuiz do
  use Ecto.Migration

  def change do

    alter table(:quiz) do
      add :user_id, references(:users, on_delete: :delete_all), null: false, default: 1
    end
    execute "ALTER TABLE quiz ALTER COLUMN user_id DROP DEFAULT"

  end
end
