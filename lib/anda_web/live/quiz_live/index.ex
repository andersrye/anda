defmodule AndaWeb.QuizLive.Index do
  use AndaWeb, :live_view

  alias Anda.Contest
  alias Anda.Contest.Quiz

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :quiz_collection, Contest.list_quiz())}
  end

  @impl true
  def handle_info({AndaWeb.QuizLive.Form.QuizForm, {:saved, quiz}}, socket) do
    {:noreply, stream_insert(socket, :quiz_collection, quiz)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    quiz = Contest.get_quiz!(id)
    {:ok, _} = Contest.delete_quiz(quiz)

    {:noreply, stream_delete(socket, :quiz_collection, quiz)}
  end

  @impl true
  def handle_event("new", _, socket) do
    case Contest.create_quiz(%{title: "123"}) do
       {:ok, %{id: id}} ->
        {:noreply, redirect(socket, to: ~p"/admin/quiz/#{id}")}
       {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Let's pretend we have an error.")}
       end
  end
end
