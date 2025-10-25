defmodule AndaWeb.QuizLive.Index do
  use AndaWeb, :live_view

  alias Anda.Contest

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :quiz_collection, Contest.list_quiz(socket.assigns.current_scope))}
  end

  @impl true
  def handle_info({AndaWeb.QuizLive.Form.QuizForm, {:saved, quiz}}, socket) do
    {:noreply, stream_insert(socket, :quiz_collection, quiz)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    quiz = Contest.get_quiz!(id)
    {:ok, _} = Contest.delete_quiz(quiz, socket.assigns.current_scope)

    {:noreply, stream_delete(socket, :quiz_collection, quiz)}
  end

  @impl true
  def handle_event("new", _, socket) do
    case Contest.create_quiz(%{title: "Ny quiz"}, socket.assigns.current_scope) do
       {:ok, %{id: id}} ->
        {:noreply, redirect(socket, to: ~p"/admin/quiz/#{id}")}
       {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Oj sorry, det virka ikke.")}
       end
  end
end
