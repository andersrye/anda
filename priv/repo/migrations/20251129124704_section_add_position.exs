defmodule Anda.Repo.Migrations.SectionAddPosition do
  use Ecto.Migration

  def up do
    alter table(:sections) do
      add :position, :integer
    end

    execute """
    DO
    $$
        DECLARE
            q record;
            s record;
            i integer;
        BEGIN
            FOR q IN (SELECT * FROM quiz)
                LOOP
                    i := 0;
                    FOR s IN (SELECT * FROM sections WHERE quiz_id = q.id ORDER BY id)
                        LOOP
                            UPDATE sections SET position=i WHERE id = s.id;
                            i := i + 1;
                        END LOOP;
                END LOOP;
        END
    $$;
    """

    alter table(:sections) do
      modify :position, :integer, null: false
    end


  end

  def down do
    alter table(:sections) do
      remove :position
    end
  end
end
