defmodule Anda.ContestTest do
  use Anda.DataCase

  alias Anda.Contest

  describe "quiz" do
    alias Anda.Contest.Quiz

    import Anda.ContestFixtures

    @invalid_attrs %{description: nil, title: nil}

    test "list_quiz/0 returns all quiz" do
      quiz = quiz_fixture()
      assert Contest.list_quiz() == [quiz]
    end

    test "get_quiz!/1 returns the quiz with given id" do
      quiz = quiz_fixture()
      assert Contest.get_quiz!(quiz.id) == quiz
    end

    test "create_quiz/1 with valid data creates a quiz" do
      valid_attrs = %{description: "some description", title: "some title"}

      assert {:ok, %Quiz{} = quiz} = Contest.create_quiz(valid_attrs)
      assert quiz.description == "some description"
      assert quiz.title == "some title"
    end

    test "create_quiz/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contest.create_quiz(@invalid_attrs)
    end

    test "update_quiz/2 with valid data updates the quiz" do
      quiz = quiz_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title"}

      assert {:ok, %Quiz{} = quiz} = Contest.update_quiz(quiz, update_attrs)
      assert quiz.description == "some updated description"
      assert quiz.title == "some updated title"
    end

    test "update_quiz/2 with invalid data returns error changeset" do
      quiz = quiz_fixture()
      assert {:error, %Ecto.Changeset{}} = Contest.update_quiz(quiz, @invalid_attrs)
      assert quiz == Contest.get_quiz!(quiz.id)
    end

    test "delete_quiz/1 deletes the quiz" do
      quiz = quiz_fixture()
      assert {:ok, %Quiz{}} = Contest.delete_quiz(quiz)
      assert_raise Ecto.NoResultsError, fn -> Contest.get_quiz!(quiz.id) end
    end

    test "change_quiz/1 returns a quiz changeset" do
      quiz = quiz_fixture()
      assert %Ecto.Changeset{} = Contest.change_quiz(quiz)
    end
  end
end
