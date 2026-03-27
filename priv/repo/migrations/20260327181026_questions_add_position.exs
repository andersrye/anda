defmodule Anda.Repo.Migrations.QuestionsAddPosition do
  use Ecto.Migration

  def up do
    alter table(:questions) do
      add :position, :integer
    end

    execute """
    DO
    $$
        DECLARE
            s record;
            q record;
            i integer;
        BEGIN
            FOR s IN (SELECT * FROM sections)
                LOOP
                    i := 0;
                    FOR q IN (SELECT * FROM questions WHERE section_id = s.id ORDER BY id)
                        LOOP
                            UPDATE questions SET position=i WHERE id = q.id;
                            i := i + 1;
                        END LOOP;
                END LOOP;
        END
    $$;
    """

    alter table(:questions) do
      modify :position, :integer, null: false
    end
  end

  def down do
    alter table(:questions) do
      remove :position
    end
  end
end
