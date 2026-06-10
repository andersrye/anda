defmodule AndaWeb.AnswersLive.Index do
  use AndaWeb, :live_view
  alias Anda.Contest
  alias Anda.Submission

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_new(:current_scope, fn -> nil end)}
  end

  def get_answers(quiz, tag) do
    []
  end

  #   def sort_submissions(submissions, sort_order) do
  #   sorter =
  #     case sort_order do
  #       "total_asc" -> &(&1.score <= &2.score)
  #       "total_desc" -> &(&1.score >= &2.score)
  #       "name_asc" -> &(&1.name <= &2.name)
  #       "name_desc" -> &(&1.name >= &2.name)
  #       "section_" <> rest ->
  #         [num, dir] = String.split(rest, "_")
  #         num = String.to_integer(num)
  #         case dir do
  #           "asc" -> &(Enum.at(&1.sections, num) <= Enum.at(&2.sections, num))
  #           "desc" -> &(Enum.at(&1.sections, num) >= Enum.at(&2.sections, num))
  #         end
  #     end

  #   Enum.sort(submissions, sorter)
  # end

  def handle_params(%{"slug" => slug, "tag_with_mac" => tag_with_mac}, uri, socket)
      when socket.assigns.live_action == :public do
    quiz = Contest.get_quiz_with_sections_by_slug!(slug)
    {:ok, tag} = Mac.verify_added_mac(tag_with_mac)
    tag = if tag == "", do: nil, else: tag

    answers = get_answers(quiz.id, tag)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, nil)
     |> assign(:tag_with_mac, tag_with_mac)
     |> assign(:show_copy_url, nil)
     |> assign(:selected_tag, nil)
     |> assign(current_uri: uri)
     |> assign(sort_order: "total_desc")
     |> assign(:answers, answers)}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, uri, socket)
      when socket.assigns.live_action == :private do
    quiz = Contest.get_quiz_with_sections!(quiz_id, socket.assigns.current_scope)
    tags = Submission.get_all_tags(quiz_id)
    selected_tag = Map.get(params, "tag")

    answers = Submission.get_all_submissions_with_answers(quiz_id, selected_tag)
    dbg(answers)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, tags)
     |> assign(:selected_tag, selected_tag)
     |> assign(:show_copy_url, nil)
     |> assign(current_uri: uri)
     |> assign(sort_order: "total_desc")
     |> assign(:answers, answers)}
  end

  @impl true
  def handle_event("change_tag", %{"tag" => tag}, socket) do
    url =
      if tag == "" do
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers"
      else
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers?tag=#{tag}"
      end

    {:noreply, socket |> push_patch(to: url)}
  end

  # @impl true
  # def handle_event("set_sort_order", %{"sort_order" => sort_order}, socket) do
  #   {:noreply, assign(socket, sort_order: sort_order, leaderboard: sort_submissions(socket.assigns.leaderboard, sort_order))}
  # end

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
