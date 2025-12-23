defmodule AndaWeb.LeaderboardLive.Index do
  use AndaWeb, :live_view
  alias Anda.Contest
  alias Anda.Submission

  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_new(:current_scope, fn -> nil end)}
  end

  def handle_params(%{"slug" => slug, "tag_with_mac" => tag_with_mac}, uri, socket)
      when socket.assigns.live_action == :public do
    quiz = Contest.get_quiz_by_slug!(slug)
    {:ok, tag} = Mac.verify_added_mac(tag_with_mac)
    tag = if tag=="", do: nil, else: tag

    leaderboard =
      Submission.get_leaderboard(quiz.id, tag)
      |> Enum.with_index()
      |> Enum.map(fn {item, index} -> Map.put(item, :index, index + 1) end)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, nil)
     |> assign(:tag_with_mac, tag_with_mac)
     |> assign(:show_copy_url, nil)
     |> assign(:selected_tag, nil)
     |> assign(current_uri: uri)
     |> assign(:leaderboard, leaderboard)}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, uri, socket)
      when socket.assigns.live_action == :private do
    quiz = Contest.get_quiz!(quiz_id)
    tags = Submission.get_all_tags(quiz_id)
    selected_tag = Map.get(params, "tag")

    leaderboard =
      Submission.get_leaderboard(quiz_id, selected_tag)
      |> Enum.with_index()
      |> Enum.map(fn {item, index} -> Map.put(item, :index, index + 1) end)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, tags)
     |> assign(:selected_tag, selected_tag)
     |> assign(:show_copy_url, nil)
     |> assign(current_uri: uri)
     |> assign(:leaderboard, leaderboard)}
  end

  @impl true
  def handle_event("change_tag", %{"tag" => tag}, socket) do
    url =
      if tag == "" do
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/leaderboard"
      else
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/leaderboard?tag=#{tag}"
      end

    {:noreply, socket |> push_patch(to: url)}
  end

  @impl true
  def handle_event("show_url", _, socket) do
    tag_with_mac = Mac.add_mac(socket.assigns.selected_tag || "")

    url =
      URI.parse(socket.assigns.current_uri)
      |> Map.put(:path, ~p"/quiz/#{socket.assigns.quiz.slug}/leaderboard/#{tag_with_mac}")
      |> Map.put(:query, nil)
      |> URI.to_string()

    {:noreply, socket |> assign(show_copy_url: url)}
  end

  @impl true
  def handle_event("hide_url", _, socket) do
    {:noreply, socket |> assign(show_copy_url: nil)}
  end
end
