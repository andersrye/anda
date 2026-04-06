defmodule Anda.Contest.QuizUtils do
  def update_quiz(quiz, new_quiz) do
    struct(new_quiz, sections: quiz.sections)
  end

  def add_section(quiz, section) do
    update_in(
      quiz,
      [
        Access.key!(:sections)
      ],
      &(&1 ++ [section])
    )
  end

  def update_section(quiz, section) do
    update_in(
      quiz,
      [
        Access.key!(:sections),
        Access.find(&(&1.id == section.id))
      ],
      &struct(section, questions: &1.questions)
    )
  end

  def update_sections(quiz, sections) do
    Enum.reduce(sections, quiz, &update_section(&2, &1))
    |> update_in([Access.key!(:sections)], fn sections ->
      Enum.sort(sections, &(&1.position <= &2.position))
    end)
  end

  def remove_section(quiz, section) do
    {_, quiz} =
      pop_in(
        quiz,
        [
          Access.key!(:sections),
          Access.find(&(&1.id == section.id))
        ]
      )

    quiz
  end

  def add_question(quiz, question) do
    update_in(
      quiz,
      [
        Access.key!(:sections),
        Access.find(&(&1.id == question.section_id)),
        Access.key!(:questions)
      ],
      &(&1 ++ [question])
    )
  end

  def update_question(quiz, question) do
    put_in(
      quiz,
      [
        Access.key!(:sections),
        Access.find(&(&1.id == question.section_id)),
        Access.key!(:questions),
        Access.find(&(&1.id == question.id))
      ],
      question
    )
  end

  def update_questions(quiz, questions) do
    section_id = Enum.at(questions, 0).section_id

    Enum.reduce(questions, quiz, &update_question(&2, &1))
    |> update_in(
      [
        Access.key!(:sections),
        Access.find(&(&1.id == section_id)),
        Access.key!(:questions)
      ],
      fn questions ->
        Enum.sort(questions, &(&1.position <= &2.position))
      end
    )
  end

  def remove_question(quiz, question) do
    {_, quiz} =
      pop_in(
        quiz,
        [
          Access.key!(:sections),
          Access.find(&(&1.id == question.section_id)),
          Access.key!(:questions),
          Access.find(&(&1.id == question.id))
        ]
      )

    quiz
  end

  def update_question_scored_count(quiz, question, new_count) do
    put_in(
      quiz,
      [
        Access.key!(:sections),
        Access.find(&(&1.id == question.section_id)),
        Access.key!(:questions),
        Access.find(&(&1.id == question.id)),
        Access.key(:scored_answer_count)
      ],
      new_count
    )
  end

  def update_answer(quiz, answer) do
    put_in(
      quiz,
      [
        Access.key!(:sections),
        Access.all(),
        Access.key!(:questions),
        Access.find(&(&1.id == answer.question_id)),
        Access.key(:answers),
        Access.find(&(&1.index == answer.index))
      ],
      answer
    )
  end
end
